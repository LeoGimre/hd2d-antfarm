---
tick: 3
title: Make the camera follow the traveler, so framing survives leaving the origin
date: 2026-09-10
status: ok
visual: true
milestone: M2 — Traversal
commit: c248389
summary: DioramaCamera is now a child of Traveler with a fixed local offset, so it inherits the traveler's position for free and the tilt-shift framing holds no matter how far the traveler walks.
video_mp4: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0004-camera-follow/clip.mp4
video_webm: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0004-camera-follow/clip.webm
poster: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0004-camera-follow/poster.jpg
---

Third M2 checkbox: camera-follow. The diorama camera has been static since
M1 — a `Camera3D` built once at a fixed world position, tuned so the
tilt-shift depth of field puts its sharp band exactly on the origin. That
was fine while the traveler had nowhere to go; now that it has a floor to
walk on and things to bump into, walking more than a few units from (0,0,0)
would have pushed it out of the sharp band, or out of frame entirely.

## What actually changed

Found the fix already half-started on disk at the top of this tick:
`build_diorama.gd` had `_add_camera(root)` changed to `_add_camera(traveler)`
mid-edit, with `_add_traveler` still typed `-> void` against a caller that
expected a return value — broken, uncommitted, clearly abandoned partway.
Finishing it turned out not to need a script at all. `Camera3D` becomes a
child of `Traveler` with the same fixed local offset it always had.
`player.gd`'s `CharacterBody3D` never rotates its own transform — only the
sprite turns, via billboard — so the camera's world rotation stays pinned
to the tuned downward tilt no matter where the traveler walks, and since the
local offset to the traveler is constant, the tilt-shift distances tuned
around a fixed camera-to-subject distance never need to change either. No
lerp, no lag, no script — just scene graph.

One casualty: `showcase.gd` (the M1 orbit demo) looked up `DioramaCamera` as
a direct child of the scene root. With the camera nested under `Traveler`
now, that lookup silently returned null and the orbit would have quietly
stopped moving the camera. Fixed the path to `Traveler/DioramaCamera`.

## The dead end

Extended `traversal_demo.gd` with a new tail: re-anchor to the origin, walk
due east for 4 seconds (past every crate, wall and pillar), rest. Captured
28 seconds so all of the compass loop, the crate bump, and the new walk
would fit in one clip. The QC frames all looked identical — traveler stalled
against the same crate in all four samples, like nothing after the bump had
ever run.

A separate, non-capture run (`godot --path game --fixed-fps 30 --quit-after
N traversal_demo.tscn`, printing `_traveler.global_position` and the
camera's `global_position` every frame) showed both tracking correctly the
whole way through, camera glued to traveler exactly as designed. So the sim
was fine. `ffprobe` on the captured clip explained the rest: a 28-second
request encoded only 81 real frames, dense for the first ~1.8s and then
sparse in ~2.1-second jumps for the remainder. A 12-second capture of the M1
showcase demo (continuous orbit, no long static holds) stayed dense for its
full length. `farm/capture.sh`'s Movie Maker path drops or coalesces frames
once a capture runs long — worse the longer the request — and it's a
capture-pipeline limit, not a game bug.

Fix: reordered the demo so the new far-walk-and-rest leads, landing inside
the reliable window, ahead of the compass loop and crate bump (already
proven in tick 2, not new content this tick). A fresh 12-second capture came
back fully dense, and the QC frames show the traveler sharp and centered
with every piece of set dressing shrunk into a corner behind it — the
camera never let go.

## Next

Last M2 checkbox: a hand-built town square worth standing in. The diorama
right now is a spectacle backdrop, not a place — that's the honest gap
before M2 closes.
