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

To stop everything: `touch state/STOP`. It halts within a few seconds, even mid-wait.

## Running the farm

```bash
MAX_TICKS=200 caffeinate -dims farm/run.sh
```

Usage limits are expected, not exceptional. A tick blocked by one never got to work, so it does
not count against `MAX_TICKS` and does not trigger failure backoff — the runner reads the reset
time out of the message, sleeps until then, and resumes on its own. If a stated reset time proves
optimistic, the wait escalates (15m, 30m, 1h, ...) rather than hammering the limit.

| Variable | Default | What |
|---|---|---|
| `MAX_TICKS` | unlimited | Ticks that actually ran. Limit waits are not counted. |
| `BUDGET_USD` | unlimited | Halt once cumulative spend passes this |
| `COOLDOWN` | 60 | Seconds between successful ticks |
| `FAIL_BACKOFF` | 300 | Seconds after a real failure |
| `MAX_FAILS` | 5 | Consecutive real failures before halting for a human |
| `TICK_TIMEOUT` | 2700 | Watchdog, seconds |

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
