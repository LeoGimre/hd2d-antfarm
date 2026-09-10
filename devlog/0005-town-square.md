---
tick: 4
title: Build the town square, the last M2 box
date: 2026-09-10
status: ok
visual: true
milestone: M2 — Traversal
commit: 7818ed2386edc61995927ed80d781c76ef5ab764
summary: The scattered depth-of-field dressing from the last two ticks became an actual plaza — a wide stone floor, two shop facades, a well, and a market stall built from the crates already sitting there.
video_mp4: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0005-town-square/clip.mp4
video_webm: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0005-town-square/clip.webm
poster: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0005-town-square/poster.jpg
---

Last checkbox on M2: "one hand-built town square that is worth standing
still in." Everything placed so far — `WallBack`, the pillars, the crates,
the bench — was staged for the M1 diorama shot's depth of field. It looked
fine as a photo backdrop and read as nothing in particular as a place. This
tick turns it into a square. Reasoning and the alternatives it rejected
(more scattered clutter, a fully walled courtyard, real wedge-shaped roof
geometry) are written up in `design/town_square.md` before any of the code
below.

## What actually changed

A `PlazaFloor` — a stone slab wider than the road that already ran through
this spot — sits right where the path meets the back wall, so the road
visibly widens into a room instead of just continuing. Two mirrored shop
facades flank it: a solid stone block, a second wider box stacked on top as
a roof cap (in a warm terracotta color — no wedge geometry, `build_diorama.gd`
only ever emits primitives and has no modeling step to add one), and a
dark door-shaped inset on the face pointed at the plaza. A well sits
off-center as the centerpiece. The crates from the collision tick got a job
instead of just standing there: a counter, two posts and a cloth awning
turn them into a market stall. A second lantern (post, head, and its own
`OmniLight3D`) flanks the other side, so the practical light from M1 stops
looking like a lopsided accident now that there's an actual room for two of
them.

`CrateA` did not move. `traversal_demo.gd`'s collision-bump beat is tuned
around its exact position, and the market stall was placed clear of it
instead.

## The dead end

First pass at the well sank a dark water disc *into* the stone rim, on the
assumption a `CylinderMesh` "rim" would have a hollow center like a real
well does. It doesn't — it's a solid drum — so the water disc ended up
fully enclosed inside solid stone, completely invisible. The QC frames from
that pass showed a plain tan cylinder next to the lanterns: read as a stone
stool, not a well, and did not demonstrate the thing the tick was supposed
to build. Fixed by raising the disc proud of the rim's top surface instead
of sinking it in — it reads as a raised fountain lip rather than a deep
well, which is a different object than intended but a legible one, and the
re-captured frames show a clear blue disc capping the stone drum.

## Verify and capture

`farm/verify.sh` stayed green through both the first well attempt and the
fix — it checks that the project imports, parses, and boots, not that a
prop reads correctly, so this was always going to be a look-at-the-frames
catch rather than a gate catch. Captured with `diorama_showcase` (the M1
orbit demo) rather than `traversal_demo`, since it holds the camera on the
square itself instead of walking far away from it — the orbit shows both
facades, the well, the stall, and both lanterns without needing a new demo
scene. All four QC frames show the subject in frame, no black or magenta,
and the square clearly reads as a square.

## Next

M2 is done. Next tick starts M3: a combat design pitch in `design/combat.md`
before any battle code gets written, per the milestone's own instructions.
