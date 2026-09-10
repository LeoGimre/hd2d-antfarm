---
description: Run one antfarm tick — pick one task, build it, verify, commit, document, publish.
---

Run exactly one tick. Work through these phases in order. Do not skip ahead, and do not stop
partway to ask anything — there is nobody to ask.

## 1. Orient

Read, in this order:

- `state/GAME.md` — the pillars you cannot renegotiate
- `state/ROADMAP.md` — find the earliest milestone with unticked boxes; that is your milestone
- `state/STATE.md` — where the last tick left off, and any open blocker
- `state/REQUESTS.md` — Leo's notes
- `design/` — whatever is relevant to the milestone you are on
- `git log --oneline -12` and the two most recent `devlog/` entries

## 2. Consume requests

For each note in `state/REQUESTS.md`, compute a short hash of its text. If that hash is not in the
"Consumed requests" list in `state/STATE.md`, it is unprocessed — let it steer what you pick in
phase 3, and add the hash to `STATE.md` at the end of the tick. **Never edit `REQUESTS.md`.**

A request outranks the roadmap for *ordering*, never for scope. If a request asks for something the
pillars forbid, note in your devlog entry that you read it and why you did not act on it.

## 3. Pick one task

One unit of work that produces one coherent commit, sized to finish inside this tick. Prefer:

- the open blocker from last tick, if there is one
- something a request pointed at
- the next unticked box in the current milestone

Design work is a valid task. If the milestone needs a decision before it needs code — the combat
hook, a type chart, how capture works — write it up in `design/` and let that be the tick.

State the task in one sentence before you start. That sentence becomes the devlog title.

## 4. Build

Make the change. Match the surrounding code. Keep the demo scenes current.

## 5. Verify — the hard gate

Run `farm/verify.sh`. It must exit 0.

If it fails and you cannot fix it within this tick: **commit nothing in `game/`**, skip to phase 9,
and publish a `stuck` entry describing precisely what blocked you and what you already tried.
Record the blocker in `STATE.md`. That is a legitimate outcome — the next tick picks it up.

Never weaken `verify.sh`, disable a check, or comment out a failing test to get past this gate.

## 6. Commit

```
git add -A && git commit
```

Short imperative subject, then prose explaining the reasoning. End the message with:

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

## 7. Is it visible?

Decide whether this change altered what a viewer would *see*. It is visible if you touched
`game/scenes/`, `game/assets/`, shaders, materials, camera, lighting, or data that a demo scene
renders. Pure refactors, tests, tooling and design documents are not.

If not visible, skip to phase 9 with `visual: false`.

## 8. Capture and QC

Pick the demo scene that best shows the change — create or update one if none fits.

```
farm/capture.sh <demo-name> 12
```

Then **open the QC frames in `farm/out/<demo-name>/qc-*.png` and look at them.** You are checking:

- Is anything rendered at all, or is it black?
- Any magenta / missing-texture surfaces?
- Is the subject in frame?
- **Does the clip actually show the thing you just built?**

If any answer is wrong, either fix the demo and re-capture, or publish text-only with
`visual: false`. Do not publish a clip you have not looked at. Do not publish a clip that fails.

## 9. Write the devlog entry

Create `devlog/NNNN-slug.md`, where `NNNN` is one past the highest existing entry.

```
---
tick: <number from STATE.md, incremented>
title: <the sentence from phase 3, as a title>
date: <YYYY-MM-DD>
status: ok | stuck | design
visual: true | false
milestone: <e.g. M2 — Traversal>
commit: <full sha, or omit if nothing was committed>
summary: <one sentence, shown in the feed>
video_mp4: <url, if published>
video_webm: <url, if published>
poster: <url, if published>
---
```

Then the body. What you set out to do, what actually happened, what you got wrong on the way, and
what is next. Write for someone who is following along and enjoys the struggle. Include the dead
ends — they are the most interesting part, and a devlog where everything works is fiction.

Aim for 200–500 words. Longer is fine when a real decision needs explaining; padding is not.

## 10. Publish

```
farm/publish.py <slug>          # uploads clip.mp4, clip.webm, poster.jpg
node site/build.mjs             # rebuild the static site
git add -A && git commit && git push
```

Paste the returned URLs into the entry's frontmatter before committing it. The push is what
deploys — Vercel builds from the repo.

If `publish.py` fails on credentials, publish the entry text-only, note it as a blocker in
`STATE.md`, and carry on. A missing clip is not a reason to lose the tick's work.

## 11. Record

Rewrite `state/STATE.md`: current milestone, current focus, open blockers, last few decisions,
consumed request hashes, incremented tick counter. Keep it short — it is read every tick, so bloat
costs tokens forever.

Append one line to `state/JOURNAL.jsonl`:

```json
{"tick": N, "date": "YYYY-MM-DD", "task": "...", "status": "ok|stuck|design", "visual": true, "commit": "sha", "slug": "NNNN-slug"}
```

Commit and push those. The tick is over. Do not start another one.
