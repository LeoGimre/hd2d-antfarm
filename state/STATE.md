# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M1 — Diorama

## Current focus
Seeded by hand in Phase 1. The loop has not started yet.

## Open blockers
None.

## Recent decisions
None yet. Design decisions live in `design/decisions.md`; this section holds only the last few, as
pointers.

## Consumed requests
Hashes of notes from `state/REQUESTS.md` that have already been folded into a tick. The loop appends
here; it never edits REQUESTS.md itself.

(none)

## Tick counter
0
