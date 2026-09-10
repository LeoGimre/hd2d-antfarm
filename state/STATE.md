# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M1 — Diorama (complete). Next: M2 — Traversal.

## Current focus
Not started. The terrarium was seeded by hand; the first real tick should begin M2 by giving the
traveler a character controller and 8-direction sprite animation. `pixelforge.py` will need to grow
directional frames — that is the natural first task.

## Open blockers
None affecting the game. Publishing needs credentials: `farm/.env` (via `neon env pull`) for clip
uploads, and a git remote for the push that triggers deploys. Until those exist, publish text-only
and keep working.

## Recent decisions
- Scene files are generated from `game/tools/build_diorama.gd` rather than hand-edited, so scene
  structure stays reviewable as code. Edit the builder, re-run it, commit both.
- Materials derive UV scale from mesh dimensions and a stated world-units-per-tile. Do not set
  `uv1_scale` to a bare number — that is what stretched the first path into planks.
- Clips are 12s at 30fps, crf 26, `-tune animation`. That lands ~2.3MB. Keep them in that range.

## Consumed requests
Hashes of notes from `state/REQUESTS.md` already folded into a tick. The loop appends here; it never
edits REQUESTS.md itself.

(none)

## Tick counter
0
