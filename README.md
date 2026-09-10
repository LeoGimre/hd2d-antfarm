# hd2d-antfarm

An autonomous agent loop building an HD-2D monster-tactics RPG in Godot, documenting every commit
as it goes.

You watch it. You don't steer it.

## What this is

An **antfarm**: a long-running loop that works toward a game with no interaction. Every tick picks
one task, builds it, verifies it, commits it, writes a devlog entry at that moment, and — if the
change is something you can actually *see* — records a short clip of the game running and publishes
both to a website.

Failed ticks publish too. A devlog where everything always works would be fiction.

## The game

A creature-collecting **tactical** turn-based RPG rendered in HD-2D — pixel sprites billboarded in a
real 3D scene, tilt-shift depth of field, heavy bloom, diorama camera. See [state/GAME.md](state/GAME.md)
for the pillars, which the loop may never renegotiate, and [state/ROADMAP.md](state/ROADMAP.md) for
where it's going.

## Layout

| Path | What |
|---|---|
| `game/` | The Godot 4.7 project |
| `design/` | The loop's creative record — combat, creatures, world, story. It owns this. |
| `state/` | The loop's memory between ticks. `GAME.md` and `REQUESTS.md` are read-only to it. |
| `farm/` | The loop machinery: runner, capture, publish |
| `devlog/` | One entry per publishing-worthy tick |
| `site/` | The website |

## Tapping the glass

Drop a note in [state/REQUESTS.md](state/REQUESTS.md). The loop reads it next tick and never writes
back. It's a one-way channel on purpose.

To stop everything: `touch state/STOP`.

## Running things by hand

```bash
# regenerate the seed pixel art
python3 game/tools/pixelforge.py

# rebuild the diorama scene from code
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
  --script res://tools/build_diorama.gd

# record a demo scene to mp4/webm + QC frames
farm/capture.sh diorama_showcase 12
```

Capture uses Godot's Movie Maker mode, which renders at a fixed timestep straight to disk — so clips
are deterministic. It needs a real rendering context and will not run headless.
