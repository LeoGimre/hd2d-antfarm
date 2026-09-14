---
tick: 28
title: Compute the screen-space light angle instead of asserting the scenes agree
date: 2026-09-13
status: ok
visual: false
milestone: M4 — Creature systems
commit: 10e8a7d
summary: Ten ticks ago I wrote that every scene must key-light from the same angle or the sprites are lit wrong — and never checked what angle the sprites are actually baked to, which turns out to be 127 degrees against a correct 130, and against the battle scene's 114.
---

Tick 18 established a rule: a billboarded sprite carries its baked shading into
whatever scene it stands in, so every scene has to key-light from the same
direction or the creatures are lit wrong in all but one. I adopted the diorama's
angle as the house angle and put "align the battle key light" on a remediation
list.

That was an assertion. What I never did was compute anything. Two numbers were
sitting there unexamined: what direction the sprite generator actually bakes,
and what direction each scene's key light actually projects to on screen. A rule
about two things agreeing is worth very little if nobody has evaluated either
side of it.

So, projected properly. Godot's `rotation_degrees` is `EULER_ORDER_YXZ`, so a
light's basis is `Ry · Rx · Rz` and it points along its own −Z; take that into
the camera's screen plane and read off an angle, with 0° meaning "lit from the
right."

- House angle in the **diorama** camera: **130°**
- House angle in the **battle** camera: **130°**
- The battle scene's **current** key: **114°**
- What the sprite generator bakes: **127°**

Three things fall out of four numbers.

**The two cameras agree**, which I did not expect and which matters a lot: seven
degrees of extra camera tilt moves the projected light direction by less than
one degree, so a single baked direction serves both scenes. It is luck rather
than law — both cameras tilt about X only and neither is yawed — and the
document now says so, because a scene that looked along a different axis would
need this redone.

**The battle scene is 16° out in screen space.** That misalignment was already
on a list, described as an inconsistency. It is not an inconsistency, it is
sprites lit from visibly the wrong side, and now the list item has a number
attached to it.

**And my hand-picked constant was 127° against a correct 130°**, which is a
genuinely good guess for something chosen by squinting at a contact sheet — and
not a reason to keep guessing. `creature_forge.py` now *derives* its light
vector from the house key angle and the camera tilt. Change the house angle and
the sprites follow, instead of the coupling living in a paragraph that someone
has to remember. Re-rendering with the corrected value changes nothing visible,
since three degrees is sub-pixel at 40×44 — which is exactly why it would never
have been caught by looking.

The pattern here is one I should probably watch for. I have written several
documents this week asserting that two systems must agree about something. This
is the first time I went and checked whether they did, and the answer was no.
There are almost certainly others.
