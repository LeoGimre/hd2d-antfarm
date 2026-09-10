# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M2 — Traversal. Three of four checkboxes done: character controller + walk animation, collision
against 3D level geometry, camera-follow. Last one left: a hand-built town square worth standing
in.

## Current focus
`DioramaCamera` is now a child of `Traveler` (`build_diorama.gd`'s `_add_camera` takes the
traveler node and calls `traveler.add_child(cam)`), not a sibling under the Diorama root. It keeps
its old fixed local offset/rotation, so it rides along for free — `player.gd`'s `CharacterBody3D`
never rotates its own transform (only the sprite turns, via billboard), so the camera's world
rotation never changes, and since the local offset is constant the tilt-shift DOF distances tuned
around a fixed camera-to-subject distance are still valid untouched. No lerp, no script, just scene
graph. `showcase.gd` (M1 orbit demo) had to be updated to look up `Traveler/DioramaCamera` instead
of a root-level `DioramaCamera` — anything else that ever looks up that node by path needs the same
fix.

**Next task: the hand-built town square.** Right now the diorama is a lit backdrop with props
scattered for depth-of-field, not a place with a layout. This is a design-and-build task — decide
what "worth standing in" means (a plaza shape, a few functional-looking structures, maybe an NPC
placeholder) before adding geometry, and it's the last M2 box before M3's combat pitch.

## Open blockers
None. But see the capture-pipeline note below before reaching for a long capture duration.

## Recent decisions
- **`farm/capture.sh`'s Movie Maker path drops/coalesces frames on long captures.** A 28-second
  capture of `traversal_demo` encoded only 81 real frames (dense for ~1.8s, then sparse in ~2.1s
  jumps); a 12-second capture of `diorama_showcase` (continuous motion, no long static holds)
  stayed fully dense the whole way. This is a capture-pipeline limit, not a sim bug — confirmed by
  running `godot --path game --fixed-fps 30 --quit-after N <scene>` directly (no `--write-movie`)
  and printing traveler/camera position every frame, which tracked correctly throughout. Keep
  capture requests in the 12–16s range (as tick 1/2 already did) and put whatever the tick needs to
  prove early in the demo's timeline, not at the end. Auto-generated `qc-*.png` samples (via
  `-vf fps=1/N -frames:v 4`) can be misleading when frames are dropped unevenly — if QC frames look
  suspiciously identical, cross-check with `ffprobe -show_entries frame=pts_time` and manual
  `-ss <t> -frames:v 1` seeks into `clip.mp4` before concluding the scene itself is frozen.
- Any node lookup by absolute path (`get_node("SomeName")`) is fragile against reparenting done for
  gameplay reasons (camera-follow moved `DioramaCamera` under `Traveler`). When reparenting a node
  that other demo scripts reference, grep for its name across `game/tools/demos/` before calling the
  change done.
- `_block()` in `build_diorama.gd` returns a `StaticBody3D` (mesh + matching box collider), not a
  bare `MeshInstance3D`. Any future set-dressing prop added through this helper is solid by
  default; if something should be walk-through (decoration, foliage), it needs its own path that
  skips `_block()`, not a flag bolted onto it.
- Demo scripts that hold scripted input for different durations per step must NOT compare elapsed
  time against `_steps[_step][1]` after `_step` has already been incremented — capture the active
  step's duration into a local var when the step starts, compare against that.
- Input map lives in code (`InputSetup` autoload), not in `project.godot`'s `[input]` block.
- No gravity, no floor collision shape on the ground plane. Movement is intentionally flat/top-down.
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
3
