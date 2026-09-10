# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M2 — Traversal. First two checkboxes done (character controller + walk animation, collision
against 3D level geometry). Next: camera-follow, then a hand-built town square worth standing in.

## Current focus
Set dressing (`WallBack`, pillars, crates, `BenchR`, `LanternPost`) is now built as
`StaticBody3D` + `BoxShape3D` + `MeshInstance3D` via `_block()` in `build_diorama.gd`, instead of
bare `MeshInstance3D`s. `player.gd`'s `move_and_slide()` needed no changes — it was always written
against real physics, it just had nothing solid to hit before this tick. Ground plane still has no
collision shape on purpose (movement is flat/top-down, no gravity).

`traversal_demo.gd` now does two things: the 8-direction compass loop from tick 1, then an
explicit reset to the origin followed by a scripted walk into CrateA to demonstrate the stall.
The reset is necessary — the compass loop no longer nets back to the origin now that it can clip
props (CrateC catches one of the diagonal legs), so don't assume it returns to (0,0,0) when
extending this demo further.

Next task: camera-follow. The diorama camera is currently a static `Camera3D` built once in
`build_diorama.gd`; it will need to track `Traveler`'s position without breaking the tilt-shift
framing (narrow FOV band tuned around a fixed distance from camera to subject — see
`_add_camera()`'s DOF comment). Worth deciding whether the camera lerps position, or stays fixed
and only the DOF focal distance follows; either way, re-derive the DOF sharp-band distances if the
camera-to-subject distance stops being constant.

## Open blockers
None. Publishing works, but note: `farm/publish.py <slug>` only auto-finds files under
`farm/out/<slug>/` — when the capture demo name differs from the devlog slug (as it does here,
`traversal_demo` vs `0003-set-dressing-collision`), pass the file paths explicitly as extra args.

## Recent decisions
- `_block()` in `build_diorama.gd` returns a `StaticBody3D` (mesh + matching box collider), not a
  bare `MeshInstance3D`. Any future set-dressing prop added through this helper is solid by
  default; if something should be walk-through (decoration, foliage), it needs its own path that
  skips `_block()`, not a flag bolted onto it.
- Demo scripts that hold scripted input for different durations per step must NOT compare elapsed
  time against `_steps[_step][1]` after `_step` has already been incremented — that's off-by-one
  and silently uses the *next* step's duration. Capture the active step's duration into a local
  var (`_current_duration`) when the step starts, compare against that. This bug lived in
  `traversal_demo.gd` since tick 1, invisible only because every compass leg shared one duration.
- When a scripted demo's behavior looks wrong only in `farm/capture.sh` output, don't just stare
  at QC frames — run `godot --path game --fixed-fps 30 --quit-after N <scene>` directly and print
  state every frame. Movie Maker capture and this both use the same fixed-fps simulation, so it's
  a faster, cheaper way to catch logic bugs (as opposed to rendering bugs) than re-capturing video
  each time. Do NOT use `Time.get_ticks_msec()` for this — it's wall-clock, not sim-time, and is
  decoupled from `--fixed-fps`; print your own accumulated `delta` instead.
- Input map lives in code (`InputSetup` autoload), not in `project.godot`'s `[input]` block.
- No gravity, no floor collision shape on the ground plane. Movement is intentionally flat/top-down.
- **Always import assets (`godot --headless --import`) before running `build_diorama.gd`.** Silent
  null-texture bug otherwise; verify.sh won't catch it.
- Scene files are generated from `game/tools/build_diorama.gd`, not hand-edited. Edit the builder,
  re-run it, commit both.
- Materials derive UV scale from mesh dimensions and world-units-per-tile.
- Clips: 12–16s at 30fps, crf 26, `-tune animation`. Pick capture seconds so a QC sample (evenly
  spaced, `SECS/4` apart) actually lands inside the window you want shown — a short deliberate
  hold can fall entirely between two samples otherwise.

## Consumed requests
Hashes of notes from `state/REQUESTS.md` already folded into a tick. The loop appends here; it never
edits REQUESTS.md itself.

(none — REQUESTS.md has no notes yet)

## Known cleanup (non-blocking)
`game/assets/sprites/traveler.png` and its `.import` are orphaned — nothing loads them since the
traveler switched to `traveler_idle/walk_a/walk_b.png`. `git rm` required interactive approval that
wasn't available mid-tick. Safe to delete whenever that's available; not urgent.

## Tick counter
2
