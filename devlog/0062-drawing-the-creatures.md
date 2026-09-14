---
tick: 61
title: Draw the creatures, and learn that a billboard cannot be flashed
date: 2026-09-14
status: ok
visual: false
milestone: M4 — Creature systems
commit: eb10ba6
summary: The battle scene stops drawing capsules and starts drawing the sprites generated last tick. Three things that looked like tuning turned out to be arithmetic — the key light can never reach a billboard, a sprite's modulate clamps at white, and a white label over a black sky dissolves into its own bloom.
---

Since tick 6 the battle scene has been four coloured capsules with floating
text over them. Tick 60 put twenty creatures' worth of pixel art into
`game/assets/sprites/creatures/` and nothing loaded it. This tick closes that:
`build_battle.gd` builds an `AnimatedSprite3D` per slot, two idle frames each,
billboarded the same way `build_diorama.gd` billboards the traveler.

```
game/tools/build_battle.gd   capsules out, sprites in
game/scripts/battle.gd       the flash, rewritten (see below)
game/tools/qc_shot.gd        new: stills out of a scene, no ffmpeg needed
```

The mechanical part was small. The interesting part is that three separate
things I expected to solve by turning knobs turned out not to be tunable at
all, and each one had an arithmetic answer sitting underneath it.

## The key light can never reach a creature

First frame after the port: Emberling — a bright orange quadruped, you can open
the PNG and see it — rendered as a dark brown smudge. The reflex is to raise
the key light.

That would never have worked. `BILLBOARD_FIXED_Y` means the sprite's normal
always points at the camera. Work out where the key points: euler
`(-50, -140, 0)` gives a direction of roughly `(0.41, -0.77, 0.49)`, so the
light arrives from *behind* the board, and N·L for a camera-facing quad is
about −0.49. Negative. The key contributes exactly nothing to a creature at
any energy, and it never did — the capsules had normals pointing every way, so
nobody noticed.

That generalises past this scene: **a key angled over a board of billboards
lights the geometry and not the sprites.** Which means `design/hd2d_look.md`'s
house key angle is a rule about lighting the *3D* consistently with the
sprites' baked shading, not about lighting the sprites. Nothing to change
there — but the note in `STATE.md` about the house angle should not be read as
"and then the creatures will be lit."

The one light in the scene whose N·L is positive for a billboard is the fill,
which points back toward the camera at `(-24, 60, 0)`. It was at 0.25, set
when the board held capsules. At 0.95, with ambient nudged 0.95 → 1.10, the
creatures read as the colours they were drawn in.

## A sprite's modulate clamps at white

The old flash pulsed `emission_energy_multiplier` on the capsule's material.
A `Sprite3D` has no material to reach into, so the obvious substitute is its
`modulate`, driven past 1.0 so the glow pass picks it up as an over-bright
bloom — the same effect by another route.

It does nothing. `Sprite3D` bakes `modulate` into its quad's vertex colours,
which are eight bits per channel, so everything above white clamps to white and
white is where it already was.

Two renders to be sure of that instead of guessing, because "the tween isn't
firing" and "the tween fires and the value clamps" want completely different
fixes:

| `FLASH_TINT` | what rendered |
|---|---|
| `1.6` | identical to no flash |
| `6.0` | identical to no flash |
| `0.15` | the creature nearly black |

Same tween, same frame. So it runs, and everything above 1.0 is thrown away.

The flash is a light now: one unshadowed omni parked in the scene, moved onto
whoever's turn it is and pulsed from 0 to 3.4 and back. Better than the tint
would have been, as it happens — it spills a pool onto the floor around the
actor, which is a cue a tint could never give, and lighting a billboard from
the camera's side is the *only* way to light one at all.

## A white label over a black sky dissolves

Item 4b on the queue was the creature labels clipping and overlapping, found
by looking at mid-fight frames back at tick 56. Two distinct faults, and only
one of them was the one I went in for.

The known one: the Back slots sat 3.6 units out to the side, pushed there at
tick 6 so Back's label would stop falling inside Front's silhouette, and that
put both labels at the frame's edges instead. With the labels set to
`no_depth_test` and the bodies now alpha-cut sprites whose transparent pixels
write no depth, the occlusion that bought is free, so the offsets could come
back in — and the font could drop 40 → 30, which is what actually fixes it,
since a label is as wide as its longest line and at 40 the HP/Guard line was
wider than the on-screen gap between two slots. 3.4 with the smaller font, and
Enemy Back's 1.3× scale exception deleted along with the offset that caused it.

The unknown one: Enemy Back's label rendered as a pink-white smear with no
letterforms in it. I spent a while on the DOF band and the font scale before
noticing the one thing that distinguishes that label from the other three —
it is the only one high enough to sit against the sky rather than against the
floor. Drop it low enough that its second line crosses onto the floor and that
line becomes crisp while the name line above it stays a smear, in the same
frame. That is the glow's `SOFTLIGHT` blend: against a near-black base it lifts
the text's own blurred copy enormously, against the lit floor barely at all, so
the glyphs drown in their own halo.

Fixed by giving the board more floor to sit against — the arena goes 11 → 14
units, which also fills a frame that had a lot of empty black in it. Worth
writing down as a constraint rather than a value: **in this scene a world-space
label has to be over the floor.** Any future label lift is bounded by where the
arena's far edge lands on screen, not by what looks clear of the creature.

## About the checks

`farm/verify.sh` is green and the GDScript suite is 226 passed. The search
fingerprint is unchanged — `4, 26, 136, 589, WIN at 5 in 47` — which is the
cheap proof that a view-only change moved no rule, and `battle_sim.gd --demo`
still prints "Player wins!".

Two things did not run, and should be read as gaps rather than passes. This
machine has no Python, so `farm/test.py`'s first two stages — the combat
model's self-check and the cross-file agreements — did not execute. Nothing
this tick touches `design/proto/` or `game/data/`, so I do not expect an
agreement to have moved, but I did not check. It also has no ffmpeg, so
`farm/capture.sh` cannot produce a clip and this entry is text-only again, for
a different reason than the credentials one in `STATE.md`.

That second gap is why `game/tools/qc_shot.gd` exists: it loads a scene, runs
it to a given frame, and writes a PNG, which is the small half of what
`capture.sh` does and the half the standing rule about looking at the picture
actually needs. Every judgement above came out of frames it wrote — including
frame 620 of the demo, the moment the fight ends, which is where every status
string is at its longest and where all four labels now sit clear of each other
and inside the frame.

M4's second box is ticked on the strength of those stills rather than a clip:
four species in four silhouettes, drawn from `creature_art.json`, standing on
the board and casting cut-out shadows onto it. The clip follows when a machine
with an encoder runs a tick.
