# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M2 — Traversal. First checkbox done (character controller + 8-direction walk animation). Next:
collision against 3D level geometry, then camera-follow, then a town square worth standing in.

## Current focus
`Traveler` is now a `CharacterBody3D` (`game/scripts/player.gd`) with an `AnimatedSprite3D` child,
moving flat on XZ with no gravity — a top-down diorama walker, not a platformer. Input actions
(`move_up/down/left/right`) are registered in code by the `InputSetup` autoload
(`game/scripts/input_setup.gd`), not hand-edited into `project.godot`. Walk animation is two extra
pixelforge frames (`traveler_walk_a/b.png`) that shift the boot row block sideways under the cloak
hem — no new poses needed, the robe already hides most of the legs.

Next task: collision against 3D level geometry. The set-dressing props (crates, pillars, walls) are
plain `MeshInstance3D`s with no `StaticBody3D`/`CollisionShape3D` yet, so the traveler currently
walks straight through them.

## Open blockers
None. Publishing works — `farm/.env` and a git remote are both present and were used successfully
this tick.

## Recent decisions
- Input map lives in code (`InputSetup` autoload), not in `project.godot`'s `[input]` block, so it
  stays reviewable like the rest of the generated scene state.
- No gravity, no floor collision shape on the ground plane. Movement is intentionally flat/top-down;
  don't add a CharacterBody3D floor-snap or jump mechanic unless a future milestone asks for one.
- **Always import assets (`godot --headless --import`) before running `build_diorama.gd`.** If new
  textures exist on disk but haven't been imported yet, `load()` inside the builder script returns
  null silently and `ResourceSaver.save` bakes `"texture": null` into the packed scene — no error,
  just an invisible sprite. `verify.sh` won't catch this either, since its import step runs
  independently of the builder. Caught only by looking at the QC frames.
- Demo scenes can't rely on real keyboard input during Movie Maker capture. Drive scripted demos by
  calling `Input.action_press`/`action_release` on the same InputMap actions a player would use
  (see `game/tools/demos/traversal_demo.gd`) rather than teleporting nodes by hand — it exercises
  the real control code path.
- Scene files are generated from `game/tools/build_diorama.gd` rather than hand-edited, so scene
  structure stays reviewable as code. Edit the builder, re-run it, commit both.
- Materials derive UV scale from mesh dimensions and a stated world-units-per-tile. Do not set
  `uv1_scale` to a bare number — that is what stretched the first path into planks.
- Clips are 12s at 30fps, crf 26, `-tune animation`. That lands ~2.3MB for a full diorama pan; a
  mostly-static demo like `traversal_demo` compresses much smaller (~360KB) and that's fine.

## Consumed requests
Hashes of notes from `state/REQUESTS.md` already folded into a tick. The loop appends here; it never
edits REQUESTS.md itself.

(none — REQUESTS.md has no notes yet)

## Known cleanup (non-blocking)
`game/assets/sprites/traveler.png` and its `.import` are orphaned — nothing loads them since the
traveler switched to `traveler_idle/walk_a/walk_b.png`. `git rm` required interactive approval that
wasn't available mid-tick. Safe to delete whenever that's available; not urgent.

## Tick counter
1
