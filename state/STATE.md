# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M2 — Traversal is **done**. M3 — First blood is now open; its first box (the combat design pitch)
is done as of tick 5.

## Current focus
**M3's second box: a battle scene with turn order and a readable state.** Build the turn-order
queue strip and the two-slot Front/Back board specified in `design/combat.md`, against a
placeholder pair of creatures — enough to prove the state is readable on screen before real
creatures/moves/Guard values exist. Do not build creatures/moves data or unit tests yet; those are
the next two boxes after this one, in order.

## Open blockers
None.

## Recent decisions
- **Combat design pitch** (tick 5): `design/combat.md` decides M3's core loop — a deterministic
  speed-ordered turn queue rendered as a visible strip (not hidden ATB), a two-slot Front/Back
  position (melee locked to Front, ranged discounted vs Back, Swap costs a full turn), and a
  Guard/Charge economy (type-effective hits crack Guard faster, breaking a creature banks a Charge
  spendable on a burst-empowered move). Capture and bonds-with-memory are explicitly deferred to
  M4 — noted as read, not built. Full reasoning and rejected alternatives (plain HP race, real-time
  ATB, a full tactics grid, a separate mana/AP pool) are in the document itself.
- **Town square layout** (tick 4): a stone plaza floor wider than the road, two mirrored shop
  facades (solid block + wider roof-cap box + door inset — no wedge geometry, the project only
  emits primitives), a well centerpiece, a market stall built from the existing crates, and a
  second lantern for symmetry. Full reasoning and rejected alternatives in `design/town_square.md`.
- **A solid `CylinderMesh` has no hollow interior.** The well's water disc was first sunk *into*
  the stone rim on the assumption the rim was hollow like a real well; it was fully swallowed and
  invisible (QC showed a plain stone stool). Fixed by raising the disc proud of the rim's top
  surface instead — reads as a raised fountain lip, not a deep well, but reads as something.
  Applies to any future prop that wants a visible recessed/embedded surface: either the container
  mesh needs an actual cavity, or the inset needs to sit proud, not sunk.
- **`CrateA`'s world position is load-bearing.** `traversal_demo.gd`'s collision-bump beat is tuned
  around it (`APPROACH_SECONDS`/`BUMP_HOLD_SECONDS` assume it's at (-2.9, *, 1.6)). Any future set
  dressing near it must be placed clear, not moved into it.
- `farm/publish.py <slug>` with no file args only looks in `farm/out/<slug>/`. If the demo used for
  capture has a different name than the devlog slug (e.g. captured `diorama_showcase` for slug
  `0005-town-square`), pass the file paths explicitly:
  `farm/publish.py <slug> farm/out/<demo>/clip.mp4 farm/out/<demo>/clip.webm farm/out/<demo>/poster.jpg`.
- `farm/capture.sh`'s Movie Maker path drops/coalesces frames on long captures (see tick 3's note,
  still true) — keep captures in the 12–16s range, front-load what the tick needs to prove.
- Any node lookup by absolute path (`get_node("SomeName")`) is fragile against reparenting. Grep
  `game/tools/demos/` before renaming or reparenting a node other scripts reference.
- `_block()` in `build_diorama.gd` returns a `StaticBody3D` (mesh + matching box collider) — solid
  by default. A helper that wants to be walk-through needs its own path that skips `_block()`.
- Demo scripts with per-step scripted input durations must capture the active step's duration into
  a local var when the step starts, not compare elapsed time against `_steps[_step][1]` after
  `_step` has already advanced.
- Input map lives in code (`InputSetup` autoload), not `project.godot`'s `[input]` block.
- No gravity, no floor collision shape on the ground plane — movement is flat/top-down.
- **Always import assets (`godot --headless --import`) before running `build_diorama.gd`.** Silent
  null-texture bug otherwise; verify.sh won't catch it.
- Scene files are generated from `game/tools/build_diorama.gd`, not hand-edited. Edit the builder,
  re-run it, commit both.
- Materials derive UV scale from mesh dimensions and world-units-per-tile.

## Consumed requests
Hashes of notes from `state/REQUESTS.md` already folded into a tick. The loop appends here; it never
edits REQUESTS.md itself.

(none — REQUESTS.md has no notes yet)

## Known cleanup (non-blocking)
`game/assets/sprites/traveler.png` and its `.import` are orphaned — nothing loads them since the
traveler switched to `traveler_idle/walk_a/walk_b.png`. `git rm` required interactive approval that
wasn't available mid-tick. Safe to delete whenever that's available; not urgent.

## Tick counter
5
