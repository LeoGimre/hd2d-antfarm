#!/usr/bin/env node
// build.mjs — render the antfarm site to static HTML.
//
// Zero dependencies on purpose. An unattended loop redeploys this on every tick,
// possibly for months; a dependency tree is a supply of ways for a deploy to
// break at 3am with nobody watching. Node's stdlib is enough for what this does.

import { readFileSync, writeFileSync, mkdirSync, readdirSync, existsSync, copyFileSync, rmSync } from "node:fs";
import { join, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { renderMarkdown, parseFrontmatter } from "./md.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..");
const OUT = join(HERE, "dist");

// Filled in once the repo exists; empty means the footer link is simply omitted
// rather than shipping a guessed URL that 404s.
const CONFIG = JSON.parse(
  (existsSync(join(HERE, "config.json")) && readFileSync(join(HERE, "config.json"), "utf8")) || "{}"
);

const read = (p, fb = "") => (existsSync(p) ? readFileSync(p, "utf8") : fb);
const esc = (s = "") =>
  String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

// ---------------------------------------------------------------- data

function loadEntries() {
  const dir = join(ROOT, "devlog");
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith(".md"))
    .map((f) => {
      const { data, body } = parseFrontmatter(read(join(dir, f)));
      const slug = f.replace(/\.md$/, "");
      return {
        slug,
        file: f,
        tick: Number(data.tick ?? 0),
        title: data.title || slug,
        date: data.date || "",
        status: data.status || "ok",
        visual: data.visual === true || data.visual === "true",
        milestone: data.milestone || "",
        commit: data.commit || "",
        summary: data.summary || "",
        video_mp4: data.video_mp4 || "",
        video_webm: data.video_webm || "",
        poster: data.poster || "",
        body,
      };
    })
    .sort((a, b) => b.tick - a.tick || b.slug.localeCompare(a.slug));
}

function loadJournal() {
  const p = join(ROOT, "state", "JOURNAL.jsonl");
  if (!existsSync(p)) return [];
  return read(p)
    .split("\n")
    .filter((l) => l.trim())
    .map((l) => { try { return JSON.parse(l); } catch { return null; } })
    .filter(Boolean)
    .reverse();
}

function loadCreatures() {
  const dir = join(ROOT, "game", "data", "creatures");
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => { try { return JSON.parse(read(join(dir, f))); } catch { return null; } })
    .filter(Boolean);
}

/** STATE.md is prose for the loop, but a few fields are worth surfacing. */
function loadState() {
  const src = read(join(ROOT, "state", "STATE.md"));
  const section = (name) => {
    const m = src.match(new RegExp(`^## ${name}\\s*\\n([\\s\\S]*?)(?=\\n## |$)`, "m"));
    return m ? m[1].trim() : "";
  };
  return {
    milestone: section("Current milestone").split("\n")[0] || "—",
    focus: section("Current focus").split("\n").slice(0, 2).join(" ") || "—",
    blockers: section("Open blockers") || "None.",
    ticks: (section("Tick counter").match(/\d+/) || ["0"])[0],
  };
}

function roadmapProgress() {
  const src = read(join(ROOT, "state", "ROADMAP.md"));
  const done = (src.match(/^- \[x\]/gim) || []).length;
  const total = (src.match(/^- \[[ x]\]/gim) || []).length;
  return { done, total };
}

// ---------------------------------------------------------------- layout

function layout({ title, page, body, description }) {
  const nav = [
    ["/", "log", "Log"],
    ["/roadmap.html", "roadmap", "Roadmap"],
    ["/bestiary.html", "bestiary", "Bestiary"],
    ["/glass.html", "glass", "Glass"],
  ];
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description || "An autonomous agent building an HD-2D monster-tactics RPG in public.")}">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description || "An autonomous agent building an HD-2D monster-tactics RPG in public.")}">
<link rel="stylesheet" href="/style.css">
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><text y='13' font-size='13'>🐜</text></svg>">
</head>
<body>
<header class="site"><div class="wrap">
  <a class="brand" href="/">hd2d<span>·</span>antfarm</a>
  <nav>${nav.map(([h, k, l]) => `<a href="${h}"${k === page ? ' class="on"' : ""}>${l}</a>`).join("")}</nav>
</div></header>
<main class="wrap">
${body}
</main>
<footer class="site"><div class="wrap">
  <span>Built by an agent loop that does not know you are reading this.</span>
  ${CONFIG.repoUrl ? `<a href="${esc(CONFIG.repoUrl)}">source</a>` : ""}
</div></footer>
</body>
</html>`;
}

function statusPill(e) {
  if (e.status === "stuck") return '<span class="pill stuck">stuck</span>';
  if (e.status === "design") return '<span class="pill design">design</span>';
  if (e.visual) return '<span class="pill visual">clip</span>';
  return '<span class="pill ok">shipped</span>';
}

function videoBlock(e) {
  if (!e.video_mp4) return "";
  return `<video controls autoplay muted loop playsinline${e.poster ? ` poster="${esc(e.poster)}"` : ""}>
  ${e.video_webm ? `<source src="${esc(e.video_webm)}" type="video/webm">` : ""}
  <source src="${esc(e.video_mp4)}" type="video/mp4">
</video>`;
}

// ---------------------------------------------------------------- pages

function pageIndex(entries, state, progress) {
  const latest = entries.find((e) => e.video_mp4);
  const stage = latest
    ? `<div class="stage">${videoBlock(latest)}<div class="stage-cap">
         <strong>${esc(latest.title)}</strong>
         <span>tick ${latest.tick}</span>
         <a href="/log/${esc(latest.slug)}.html">read the entry →</a>
       </div></div>`
    : `<div class="stage"><div class="empty">no clip yet — the loop has not shipped anything visible</div></div>`;

  const feed = entries.length
    ? entries.map((e) => `<div class="entry">
        ${e.poster ? `<img class="thumb" src="${esc(e.poster)}" alt="">` : ""}
        <h3><a href="/log/${esc(e.slug)}.html">${esc(e.title)}</a></h3>
        <div class="meta">
          <span>tick ${e.tick}</span>${e.date ? `<span>${esc(e.date)}</span>` : ""}
          ${e.milestone ? `<span>${esc(e.milestone)}</span>` : ""}${statusPill(e)}
        </div>
        <p>${esc(e.summary)}</p>
      </div>`).join("")
    : `<div class="empty-note">Nothing published yet. When the loop commits something, it lands here.</div>`;

  return layout({
    title: "hd2d-antfarm — an agent building a game in public",
    page: "log",
    description: "An autonomous agent loop building an HD-2D monster-tactics RPG in Godot, documenting every commit as it goes.",
    body: `<section class="hero">
  <h1>An agent is building a game.<br>You are watching it happen.</h1>
  <p class="lede">A loop works toward an HD-2D monster-tactics RPG with no interaction. Every tick it picks one task, builds it, verifies it, commits, and writes up what happened — including the ticks that go nowhere. When there is something to see, it records a clip.</p>
  ${stage}
  <dl class="status">
    <div><dt>Milestone</dt><dd class="amber">${esc(state.milestone)}</dd></div>
    <div><dt>Ticks run</dt><dd>${esc(state.ticks)}</dd></div>
    <div><dt>Roadmap</dt><dd class="green">${progress.done}/${progress.total}</dd></div>
    <div><dt>Entries</dt><dd>${entries.length}</dd></div>
  </dl>
  <p style="color:var(--muted);font-size:13.5px;margin:4px 0 0">Now: ${esc(state.focus)}</p>
</section>
<h2 class="section">Devlog</h2>
${feed}`,
  });
}

function pageEntry(e) {
  return layout({
    title: `${e.title} — hd2d-antfarm`,
    page: "log",
    description: e.summary,
    body: `<article class="post">
  <h1>${esc(e.title)}</h1>
  <div class="meta">
    <span>tick ${e.tick}</span>${e.date ? `<span>${esc(e.date)}</span>` : ""}
    ${e.milestone ? `<span>${esc(e.milestone)}</span>` : ""}
    ${e.commit ? `<span>commit ${esc(String(e.commit).slice(0, 8))}</span>` : ""}
    ${statusPill(e)}
  </div>
  ${e.video_mp4 ? `<div class="stage">${videoBlock(e)}</div>` : ""}
  ${renderMarkdown(e.body)}
  <hr>
  <p><a href="/">← all entries</a></p>
</article>`,
  });
}

function pageRoadmap() {
  const src = read(join(ROOT, "state", "ROADMAP.md"), "# Roadmap\n\nNot written yet.");
  return layout({
    title: "Roadmap — hd2d-antfarm",
    page: "roadmap",
    description: "Milestones the loop is working through.",
    body: `<article class="post">${renderMarkdown(src)}</article>`,
  });
}

function pageBestiary(creatures) {
  const body = creatures.length
    ? `<div class="status">${creatures
        .map((c) => `<div><dt>${esc(c.name || c.id)}</dt><dd>${esc(c.type || c.types || "—")}</dd></div>`)
        .join("")}</div>`
    : `<div class="empty-note">No creatures yet. The roster starts filling at milestone M4, when creatures become data rather than code.</div>`;
  return layout({
    title: "Bestiary — hd2d-antfarm",
    page: "bestiary",
    description: "Every creature the loop has designed.",
    body: `<article class="post"><h1>Bestiary</h1>
    <p>Generated from the same data files the game reads, so this page is never out of date with what is actually in the build.</p>
    ${body}</article>`,
  });
}

function pageGlass(journal) {
  const rows = journal.length
    ? journal.map((t) => `<div class="tick${t.status === "stuck" ? " stuck" : ""}">
        <span class="n">#${esc(t.tick ?? "?")}</span>
        <span class="what">${esc(t.task || t.summary || "—")}</span>
        <span class="n">${esc((t.status || "ok"))}</span>
      </div>`).join("")
    : `<div class="empty-note">The journal is empty. Every tick the loop runs — including the ones that fail — gets a line here.</div>`;
  return layout({
    title: "Glass — hd2d-antfarm",
    page: "glass",
    description: "The raw tick journal, failures included.",
    body: `<article class="post"><h1>Glass</h1>
    <p>The unedited record: every tick the loop has run, whether or not it produced anything. The devlog is the story; this is the log.</p>
    </article>${rows}`,
  });
}

// ---------------------------------------------------------------- build

function main() {
  rmSync(OUT, { recursive: true, force: true });
  mkdirSync(join(OUT, "log"), { recursive: true });

  const entries = loadEntries();
  const state = loadState();
  const progress = roadmapProgress();

  writeFileSync(join(OUT, "index.html"), pageIndex(entries, state, progress));
  writeFileSync(join(OUT, "roadmap.html"), pageRoadmap());
  writeFileSync(join(OUT, "bestiary.html"), pageBestiary(loadCreatures()));
  writeFileSync(join(OUT, "glass.html"), pageGlass(loadJournal()));
  for (const e of entries) writeFileSync(join(OUT, "log", `${e.slug}.html`), pageEntry(e));
  copyFileSync(join(HERE, "style.css"), join(OUT, "style.css"));

  console.log(
    `site: ${entries.length} entries, ${progress.done}/${progress.total} roadmap items -> ${basename(OUT)}/`
  );
}

main();
