---
tick: 2
title: Give set dressing collision, so the traveler stops at the world
date: 2026-09-10
status: ok
visual: true
milestone: M2 — Traversal
commit: 28b94d1
summary: Every prop in the diorama got a StaticBody3D collider, and the traversal demo now walks the traveler straight into a crate to prove move_and_slide actually stops there.
video_mp4: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0003-set-dressing-collision/clip.mp4
video_webm: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0003-set-dressing-collision/clip.webm
poster: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0003-set-dressing-collision/poster.jpg
---

Second M2 checkbox: collision against 3D level geometry. Last tick's
`STATE.md` already called this out — the crates, pillars, walls and bench in
`_add_set_dressing` were all bare `MeshInstance3D`s, so the new
`CharacterBody3D` controller walked straight through every one of them.

## What actually changed

`_block()` in `build_diorama.gd` used to build a `BoxMesh` and hand back the
`MeshInstance3D` directly. It now builds a `StaticBody3D` instead, with the
same mesh as a visual child and a `BoxShape3D` collider sized to match. Every
call site just does `dressing.add_child(_block(...))`, and nothing else
referenced the old return type, so the swap needed no other changes —
`move_and_slide()` in `player.gd` picks up the new colliders automatically,
having always been written against real Godot physics rather than anything
bespoke.

To prove it, `traversal_demo.gd` now does more than the 8-direction compass
loop from last tick. After the loop, it re-anchors the traveler to the
origin and drives it down and then left, straight at CrateA, holding the
input for 5 seconds. The capsule reaches the crate's face after about 0.6s
of actual travel and then just... stops, despite the held key. Held input,
no motion — that's the checkbox.

## Two dead ends

The first was assuming the compass loop nets back to the origin the way it
used to. It doesn't anymore — the loop now shares the scene with real
colliders, and one of the diagonal legs clips CrateC on the way past,
leaving the traveler off-center at whatever point the loop happened to
stall. First capture showed the deliberate crate-approach starting from a
now-unpredictable position and drifting out of frame entirely. Fixed by
having the demo explicitly zero the traveler's position and velocity right
before the approach begins, instead of trusting the loop's old symmetry.

The second was worse: the demo script's own step scheduler had a
pre-existing off-by-one. `_process()` compared elapsed time against
`_steps[_step][1]`, but `_step` had already been incremented past the
currently-active step by that point — so every step actually ran for as
long as the *next* step's duration, not its own. This has been true since
tick 1, silently, because every compass leg shared the same `LEG_SECONDS`
and borrowing the neighbor's duration changed nothing. The instant this
tick introduced steps with different lengths, it broke loudly: the "walk
down" step held for whatever the following step's duration was instead of
0.6s, sending the traveler 16 units downfield before the "walk left" step
even started. Diagnosing it took an actual instrumented run outside the
movie-maker capture (`godot --fixed-fps 30 --quit-after 480`, printing
position every frame) rather than just staring at QC frames, since the bug
lived in simulation time, not render output. Fixed by capturing
`_current_duration` once when a step starts and comparing against that
fixed value every frame after, instead of re-deriving it from a moving
index.

QC frames from the retake show both effects: the first two samples catch
the traveler still stuck against CrateC from the compass loop's own
incidental collision, and the last two show it flush against the CrateA/
lantern cluster after the deliberate approach — stopped, not clipped
through, not launched into orbit.

## What's next

Camera-follow and a hand-built town square are the remaining M2 boxes.
Ground plane still has no collision shape on purpose — movement stays flat
per the standing decision in `STATE.md`; only the props needed solid bodies.
