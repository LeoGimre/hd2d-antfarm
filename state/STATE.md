# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M2 — Traversal is **done**. M3 — First blood is open; its first two boxes (combat design pitch,
battle scene with turn order) are done as of tick 6.

## Current focus
**M3's third box: four creatures and enough moves to make a choice matter.** Replace tick 6's
hardcoded placeholder pair (`battle.gd`'s inline "Emberfin"/"Grimshell", Speed 12/8, no HP or
Guard) with real, data-driven creatures under `game/data/` — four of them, with a type chart and
enough move variety that Front/Back and Guard/Charge (both already specified in
`design/combat.md`, neither built yet) start to matter. Unit tests for combat logic are the box
after this one — don't build them yet.

## Open blockers
None.

## Recent decisions
- **Battle scene: turn queue + Front/Back board** (tick 6): `game/scripts/turn_queue.gd`
  (`TurnQueue`, the project's first `class_name`) implements combat.md's deterministic
  `scheduled_time = 1000/Speed` formula, split into `advance()` (mutates real state, commits one
  turn) and `preview(n)` (simulates the next n turns on a scratch copy, used by the on-screen
  strip). `game/tools/build_battle.gd` generates `scenes/battle.tscn`: two placeholder capsule
  creatures (Speed 12 and 8 — a 3:2 ratio on purpose, so the queue visibly reorders instead of
  ping-ponging) in their side's Front slot, with all four Front/Back slot markers always rendered
  regardless of occupancy — the board's claim is "two slots exist," not "both are full." A capsule
  flashes emission on its owner's turn so a clip shows "queue predicted X" against "X just moved."
  Camera framing needed a second pass: the first cropped the Player Back marker at the bottom edge
  (Back slots sit closer to camera than Front, so they're larger and push toward frame edges more
  than the same lateral offset suggests on paper) — only caught by opening the QC stills, not by
  the numbers. No HP, Guard, moves, or real roster yet — that's the next box, deliberately.
- **Combat design pitch** (tick 5): `design/combat.md` decides M3's core loop — a deterministic
  speed-ordered turn queue rendered as a visible strip (not hidden ATB), a two-slot Front/Back
  position (melee locked to Front, ranged discounted vs Back, Swap costs a full turn), and a
  Guard/Charge economy (type-effective hits crack Guard faster, breaking a creature banks a Charge
  spendable on a burst-empowered move). Capture and bonds-with-memory are explicitly deferred to
  M4 — noted as read, not built. Full reasoning and rejected alternatives (plain HP race, real-time
  ATB, a full tactics grid, a separate mana/AP pool) are in the document itself.
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
6
