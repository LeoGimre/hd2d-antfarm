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

/** The game keeps its content in three flat files under game/data/, each an
 *  object wrapping one named array. This page was written before any of them
 *  existed and guessed a one-file-per-creature directory instead, so from the
 *  moment creatures actually landed it quietly reported an empty roster while
 *  the build shipped four. Read what is really there. */
function loadGameData(file, key) {
  const path = join(ROOT, "game", "data", file);
  if (!existsSync(path)) return [];
  try {
    const parsed = JSON.parse(read(path));
    return Array.isArray(parsed[key]) ? parsed[key] : [];
  } catch {
    return [];
  }
}

const loadCreatures = () => loadGameData("creatures.json", "creatures");
const loadMoves = () => loadGameData("moves.json", "moves");

/** types.json keys its chart by type name instead of listing it, so it does not
 *  go through loadGameData. */
function loadTypes() {
  const path = join(ROOT, "game", "data", "types.json");
  if (!existsSync(path)) return {};
  try { return JSON.parse(read(path)).types || {}; } catch { return {}; }
}

/** The design/ directory is where the loop is allowed to invent, and by tick 18
 *  it holds more of this project's thinking than game/ does. The devlog refers
 *  to these documents constantly and a reader had no way to open one, which is
 *  a strange gap on a site whose whole premise is watching the work. */
function loadDesignDocs() {
  const dir = join(ROOT, "design");
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith(".md"))
    .map((f) => {
      const src = read(join(dir, f));
      const slug = f.replace(/\.md$/, "");
      const heading = src.match(/^#\s+(.+)$/m);
      // First real paragraph: skip headings, blockquotes, tables and lists.
      const para = src
        .split(/\n{2,}/)
        .find((b) => b.trim() && !/^[#>|\-*\d]/.test(b.trim()));
      return {
        slug,
        file: f,
        title: heading ? heading[1].trim() : slug,
        summary: summarise(para || "", 2, 240),
        body: src,
      };
    })
    .sort((a, b) => a.title.localeCompare(b.title));
}

/** Flatten markdown to something a one-line status tile can hold. */
function plain(md) {
  return String(md)
    .replace(/`([^`]*)`/g, "$1")
    .replace(/\*\*([^*]*)\*\*/g, "$1")
    .replace(/\*([^*]*)\*/g, "$1")
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\s+/g, " ")
    .trim();
}

/** First `count` sentences, then a hard cap that breaks on a word boundary.
 *  Splits on a terminator *followed by whitespace* rather than matching
 *  sentence shapes: STATE.md is full of filenames, and a pattern that treats
 *  every "." as an end-of-sentence cuts `first_blood_balance.md` in half and
 *  puts "md, in-engine." on the front page. */
function summarise(md, count, cap) {
  const text = plain(md);
  let out = text.split(/(?<=[.!?])\s+/).slice(0, count).join(" ").trim();
  if (!out) out = text;
  if (out.length > cap) out = out.slice(0, cap - 1).replace(/[\s,;:—-]+\S*$/, "") + "…";
  return out;
}

/** STATE.md is the loop's own memory, written for whichever session reads it
 *  next — not copy for this page. Its line breaks fall wherever the paragraph
 *  happened to wrap and its prose is markdown, so slicing physical lines out of
 *  it puts stray `**` on the front page and stops sentences mid-word. That is
 *  exactly what shipped when tick 10 rewrote the file. Work in sentences, strip
 *  the markup, and cap the length here, so how the next tick words its notes
 *  cannot break the page. */
function loadState() {
  const src = read(join(ROOT, "state", "STATE.md"));
  // No "m" flag on purpose. With it, `$` matches at every line end, so the lazy
  // body stops at the first newline and every section silently collapses to its
  // first line — which is how a mid-sentence fragment reached the front page.
  // `(?:^|\n)## ` anchors the heading without needing multiline.
  const section = (name) => {
    const m = src.match(new RegExp(`(?:^|\\n)## ${name}\\s*\\n([\\s\\S]*?)(?=\\n## |$)`));
    return m ? m[1].trim() : "";
  };
  const blockers = section("Open blockers");
  return {
    milestone: summarise(section("Current milestone"), 1, 58) || "—",
    focus: summarise(section("Current focus"), 2, 240) || "—",
    // "None." is the normal case and not worth a line; anything else is.
    // Three sentences rather than two: a blocker is only useful if the reader
    // learns what is actually stuck. The character cap is what bounds it.
    blocker: /^none\.?$/i.test(plain(blockers)) ? "" : summarise(blockers, 3, 240),
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
    ["/roadmap", "roadmap", "Roadmap"],
    ["/design", "design", "Design"],
    ["/bestiary", "bestiary", "Bestiary"],
    ["/glass", "glass", "Glass"],
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

/** The hero leads with the most recent tick, whatever kind it was.
 *
 *  It used to lead with the most recent tick that had a *clip*, which is right
 *  while clips are frequent and quietly wrong once they are not: twenty
 *  consecutive text-only ticks left a black video player from tick 9
 *  headlining a project on tick 29. A site whose premise is watching the work
 *  happen should not open on three weeks ago. When the newest entry has no
 *  clip, it leads as text and the last capture is demoted to a strip
 *  underneath, which is honest about both. */
function pageIndex(entries, state, progress) {
  const newest = entries[0];
  const lastClip = entries.find((e) => e.video_mp4);

  let stage;
  if (!newest) {
    stage = `<div class="stage"><div class="empty">nothing published yet</div></div>`;
  } else if (newest.video_mp4) {
    stage = `<div class="stage">${videoBlock(newest)}<div class="stage-cap">
         <strong>${esc(newest.title)}</strong>
         <span>tick ${newest.tick}</span>
         <a href="/log/${esc(newest.slug)}">read the entry →</a>
       </div></div>`;
  } else {
    stage = `<div class="stage"><div class="lead">
         <div class="lead-meta"><span>tick ${newest.tick}</span>${
           newest.date ? `<span>${esc(newest.date)}</span>` : ""}${statusPill(newest)}</div>
         <h2><a href="/log/${esc(newest.slug)}">${esc(newest.title)}</a></h2>
         <p>${esc(newest.summary || "")}</p>
       </div><div class="stage-cap">
         <span>latest tick</span>
         <a href="/log/${esc(newest.slug)}">read the entry →</a>
       </div></div>`;
    if (lastClip) {
      stage += `<p class="lastclip">Last captured clip: <a href="/log/${
        esc(lastClip.slug)}">${esc(lastClip.title)}</a> <span>tick ${lastClip.tick}</span></p>`;
    }
  }

  const feed = entries.length
    ? entries.map((e) => `<div class="entry">
        ${e.poster ? `<img class="thumb" src="${esc(e.poster)}" alt="">` : ""}
        <h3><a href="/log/${esc(e.slug)}">${esc(e.title)}</a></h3>
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
  <p class="now">Now: ${esc(state.focus)}</p>
  ${state.blocker ? `<p class="blocked">Blocked: ${esc(state.blocker)}</p>` : ""}
</section>
<h2 class="section">Devlog</h2>
${feed}`,
  });
}

function pageEntry(e, slugs = new Set()) {
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
  ${linkDesignRefs(renderMarkdown(e.body), slugs)}
  <hr>
  <p><a href="/">← all entries</a></p>
</article>`,
  });
}


/** Devlog entries and design documents name each other constantly, always as
 *  `design/thing.md` in a code span. Turning the ones that exist into links
 *  costs a regex and makes fourteen dead references navigable. Unknown paths
 *  are left alone rather than linked to a 404. */
function linkDesignRefs(html, slugs) {
  return html.replace(/<code>design\/([a-z0-9_]+)\.md<\/code>/g, (m, slug) =>
    slugs.has(slug) ? `<a href="/design/${slug}"><code>design/${slug}.md</code></a>` : m);
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

/** Type accents are cosmetic, keyed by name with a neutral fallback, so a fifth
 *  type appearing in game/data/types.json renders correctly — just in grey —
 *  without anyone editing this file. The pillar that content must stay cheap to
 *  add applies to the page that shows it off too. */
const TYPE_ACCENT = { Ember: "rust", Tide: "blue", Gale: "ink", Root: "green" };
const accent = (t) => TYPE_ACCENT[t] || "grey";
const typeTag = (t) => (t ? `<span class="t ${accent(t)}">${esc(t)}</span>` : "—");

/** Rendered as a table rather than the cycle it happens to be today: the chart
 *  is data, and the next one may not be a cycle. */
function typeChart(types) {
  const rows = Object.entries(types).map(([name, e]) => {
    const beats = Object.entries(types)
      .filter(([, other]) => other.weak_to === name)
      .map(([n]) => typeTag(n))
      .join(" ");
    return `<tr><td>${typeTag(name)}</td><td>${beats || "—"}</td><td>${typeTag(e.weak_to)}</td></tr>`;
  });
  if (!rows.length) return "";
  return `<h2>Type chart</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Type</th><th>Strong against</th><th>Weak to</th></tr></thead>
      <tbody>${rows.join("")}</tbody>
    </table></div>`;
}

function beastCard(c, moveById, types) {
  const moves = (c.moves || [])
    .map((id) => moveById.get(id))
    .filter(Boolean)
    .map((m) => `<li>
        <span class="mv">${esc(m.display_name || m.id)}</span>
        <span class="cat">${esc(m.category || "—")}</span>
        <span class="pw">${esc(m.power ?? "—")}</span>
      </li>`)
    .join("");

  const strong = Object.entries(types)
    .filter(([, e]) => e.weak_to === c.type)
    .map(([n]) => n);
  const weak = (types[c.type] || {}).weak_to;

  return `<article class="beast">
    <header><h2>${esc(c.display_name || c.id)}</h2>${typeTag(c.type)}</header>
    <dl class="vitals">
      <div><dt>HP</dt><dd>${esc(c.max_hp ?? "—")}</dd></div>
      <div><dt>Guard</dt><dd>${esc(c.max_guard ?? "—")}</dd></div>
      <div><dt>Speed</dt><dd>${esc(c.speed ?? "—")}</dd></div>
    </dl>
    ${moves ? `<ul class="moves">${moves}</ul>` : ""}
    <p class="match">Strong vs ${strong.length ? strong.map(esc).join(", ") : "nothing yet"}
      · Weak to ${weak ? esc(weak) : "nothing yet"}</p>
  </article>`;
}


function pageDesignIndex(docs) {
  const rows = docs.length
    ? docs.map((d) => `<div class="entry">
        <h3><a href="/design/${d.slug}">${esc(d.title)}</a></h3>
        <div class="meta"><span>design/${esc(d.file)}</span></div>
        <p>${esc(d.summary)}</p>
      </div>`).join("")
    : `<div class="empty-note">Nothing designed yet.</div>`;
  return layout({
    title: "Design — hd2d-antfarm",
    page: "design",
    description: "The loop's design documents: what it decided and what it rejected.",
    body: `<article class="post"><h1>Design</h1>
    <p>Where the loop is allowed to invent. These are the decisions behind the build — including the alternatives that were rejected, which is usually the more useful half. The devlog is what happened; this is what it was trying to do.</p>
    </article>${rows}`,
  });
}

function pageDesignDoc(doc, slugs) {
  // Relative links between design documents resolve to their published paths.
  const src = doc.body.replace(/\]\((?:design\/)?([a-z0-9_]+)\.md\)/g, "](/design/$1)");
  return layout({
    title: `${doc.title} — hd2d-antfarm`,
    page: "design",
    description: doc.summary,
    body: `<article class="post">
  <div class="meta"><span>design/${esc(doc.file)}</span></div>
  ${linkDesignRefs(renderMarkdown(src), slugs)}
  <hr>
  <p><a href="/design">← all design documents</a></p>
</article>`,
  });
}

function pageBestiary(creatures, moves, types) {
  const moveById = new Map(moves.map((m) => [m.id, m]));
  const body = creatures.length
    ? `<div class="beasts">${creatures.map((c) => beastCard(c, moveById, types)).join("")}</div>
       ${typeChart(types)}`
    : `<div class="empty-note">No creatures yet. The roster starts filling at milestone M4, when creatures become data rather than code.</div>`;
  return layout({
    title: "Bestiary — hd2d-antfarm",
    page: "bestiary",
    description: "Every creature the loop has designed.",
    body: `<article class="post"><h1>Bestiary</h1>
    <p>Generated from the same data files the game reads, so this page is never out of date with what is actually in the build. ${creatures.length} creature${creatures.length === 1 ? "" : "s"} so far.</p>
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
  writeFileSync(join(OUT, "bestiary.html"), pageBestiary(loadCreatures(), loadMoves(), loadTypes()));
  writeFileSync(join(OUT, "glass.html"), pageGlass(loadJournal()));

  const docs = loadDesignDocs();
  const slugs = new Set(docs.map((d) => d.slug));
  mkdirSync(join(OUT, "design"), { recursive: true });
  writeFileSync(join(OUT, "design.html"), pageDesignIndex(docs));
  for (const d of docs) writeFileSync(join(OUT, "design", `${d.slug}.html`), pageDesignDoc(d, slugs));

  for (const e of entries) writeFileSync(join(OUT, "log", `${e.slug}.html`), pageEntry(e, slugs));
  copyFileSync(join(HERE, "style.css"), join(OUT, "style.css"));

  // The prototype creature sprites, so design/roster.md can show what it is
  // describing. They are design artifacts rather than game assets — nothing in
  // game/ loads them — and farm/agreements.py checks they still match what the
  // generator produces, so a stale sprite cannot sit here unnoticed.
  const spriteSrc = join(ROOT, "design", "proto", "sprites");
  if (existsSync(spriteSrc)) {
    mkdirSync(join(OUT, "sprites"), { recursive: true });
    for (const f of readdirSync(spriteSrc).filter((f) => f.endsWith(".png"))) {
      copyFileSync(join(spriteSrc, f), join(OUT, "sprites", f));
    }
  }

  console.log(
    `site: ${entries.length} entries, ${docs.length} design docs, ${progress.done}/${progress.total} roadmap items -> ${basename(OUT)}/`
  );
}

main();
