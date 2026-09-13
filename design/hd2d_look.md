# The HD-2D house style

Pillar 6 says HD-2D always, and that visual identity is a pillar rather than a
polish pass. M1 ticked six boxes establishing the look. Every number that
implements them lives in comments inside `game/tools/build_diorama.gd`, and a
second, slightly different set lives inside `game/tools/build_battle.gd`.

M5's first box is *"a repeatable region authoring workflow."* A workflow that
begins with "read two builders and guess which of their differences were on
purpose" is not repeatable. This document is the recipe, plus an audit of how
far the second scene has already drifted from the first — because it has, and
nobody noticed, which is the argument for writing it down.

**A caveat that matters:** this is a static audit. This container has no engine,
so nothing below was seen — it was read out of two files and checked with
arithmetic. Where it says a setting is inert, that is a fact about numbers.
Where it implies the scene looks worse for it, that is a hypothesis, and the
tick with an engine should look at a frame before changing anything.

## The recipe

M1's six boxes, and the setting that actually delivers each:

| the look | what delivers it |
|---|---|
| billboarded pixel sprite, upright | `Sprite3D`/`Label3D` billboard, `TEXTURE_FILTER_NEAREST_WITH_MIPMAPS` |
| a real shadow on 3D geometry | one shadow-casting `DirectionalLight3D`, `shadow_blur 2.6`, `shadow_normal_bias 1.4` |
| diorama camera | **narrow FOV from far away**, tilted down ~30–40° |
| tilt-shift depth of field | `CameraAttributesPractical`, near and far blur bracketing the subject |
| bloom and tonemapping | ACES tonemap, `glow_blend_mode SOFTLIGHT`, `glow_hdr_scale 2.2` |
| a lit environment with a practical | a warm `OmniLight3D` at high energy, short range, shadow-casting |

The one that is easiest to get wrong is the camera, and the diorama's own comment
says why: *narrow FOV from far away is the Octopath flattening trick*. Perspective
convergence is what makes a 3D scene look 3D; pushing the camera back and
narrowing the lens removes it, and the sprites stop looking like cardboard
standing in a room and start looking like a diorama. Widening the lens to fit
more in undoes the pillar. Backing further away with the same lens does not.

## The two scenes, side by side

| | diorama | battle | |
|---|---|---|---|
| tonemap | ACES, white 6.0 | ACES, white 6.0 | same |
| exposure | 1.00 | 1.05 | ~same |
| glow blend / hdr scale | SOFTLIGHT / 2.2 | SOFTLIGHT / 2.2 | same |
| glow intensity / strength / bloom | 1.15 / 1.2 / 0.35 | 1.25 / 1.3 / 0.40 | ~same |
| glow hdr threshold | 0.72 | 0.65 | battle blooms sooner |
| ssao intensity / radius / power | 0.9 / 1.0 / 1.4 | 0.9 / 1.0 / 1.4 | same |
| shadow blur / normal bias | 2.6 / 1.4 | 2.6 / 1.4 | same |
| contrast / saturation | 1.06 / 1.18 | 1.08 / 1.12 | ~same |
| ambient energy | 1.30 | 0.95 | **deliberate** |
| sky | daylight blue | night violet | **deliberate** |
| key light | warm (1.0, 0.88, 0.70) @ 1.25 | cool violet (0.86, 0.80, 1.0) @ 1.1 | **deliberate** |
| key angle | (−44, −118, 0) | (−50, −140, 0) | **see below** |
| depth fog | on, density 0.008 | **absent** | **drift** |
| camera FOV | **18°** | **28°** | **drift** |
| camera position | (0, 13.5, 21) | (0, 15, 19) | closer *and* wider |
| DOF sharp band | 21 → 27 | 17 → 50 | **inert, see below** |

The deliberate ones are good and should stay: a battle is cut away from the town,
at night, lit cold. That is exactly the kind of variation a house style should
permit. Three of these are not that.

## The drift

**1. The battle scene's tilt-shift is present and does nothing.** The camera sits
at `(0, 15, 19)`. The four slots are 22.0, 22.4, 24.8 and 25.4 units from it.
Near blur acts below 17; far blur acts beyond 50. The entire board sits in the
gap, so neither half of the effect touches a single pixel. An M1 box that was
ticked on the diorama is, in the scene where all the gameplay happens, switched
off by arithmetic.

Half of this was a real decision — a comment in `build_battle.gd` explains that
far distance was pushed out on purpose, because tilt-shift blur was washing out
the Back slots' HP/Guard labels, and `GAME.md`'s standard puts legible-in-ten-
seconds above a purist blur. That reasoning is sound and it is *recorded*, which
is exactly right. The near side has no such comment, and pushing far to 50 rather
than to just past the Back slots (about 27) overshot by more than the problem
needed. The fix is a narrower band that still clears the labels, not no band.

**2. Depth fog is absent from the battle scene entirely.** The diorama runs
`FOG_MODE_DEPTH` at density 0.008 with a cool light colour, which is a real part
of how its depth reads. The battle scene never sets fog at all. There is no
comment saying it was dropped, which usually means it was not dropped — it was
never carried over.

**3. The battle camera is wider and closer.** 28° at z=19, against 18° at z=21.
That is the flattening trick run backwards on both axes at once. There is no
comment explaining it, and the obvious motive — fitting a board four slots wide
into frame — is better served by keeping 18° and moving the camera back, which
costs nothing and preserves the pillar. This one most deserves a look at an
actual frame before anyone touches it, because a wider board may genuinely need
it and the clips from ticks 6 to 9 presumably looked acceptable.

## A new constraint: one key-light angle for the whole game

This is not drift yet, but it is about to be, and it is the reason this document
exists now rather than at M5.

`design/creature_sprites.md` bakes a light direction into every generated
creature sprite — shading is computed once, at generation time, from a fixed
direction. A billboarded sprite carries that baked light into whatever scene it
stands in. Which means:

> Every scene in the game has to key-light from the same direction, or the
> creatures are lit wrong in all but one of them.

The two scenes already disagree: `(−44, −118, 0)` versus `(−50, −140, 0)`. With
capsules and a hand-drawn traveler that costs nothing, because a capsule is lit
by the scene and the traveler's own shading is subtle. The moment generated
creature sprites ship, it is a visible error in one scene or the other, and the
cheap fix — pick one angle, use it everywhere — is only cheap before there are
sprites and scenes to redo.

**Decision: the diorama's key angle, `(−44, −118, 0)`, is the house angle.** It
was tuned first, against the traveler and the town square, on the scene whose
frames have been looked at most. The sprite generator's baked direction should
be derived from it, and any new scene adopts it. Colour and energy stay free —
a scene may light cold or warm, bright or dim, but not from somewhere else.

### The number, computed

Asserting that scenes must agree on a key angle is not the same as knowing what
the sprites are baked to. Both sides of that coupling have now been worked out
rather than assumed.

A `DirectionalLight3D`'s direction projected into the camera's screen plane —
Godot's `rotation_degrees` is `EULER_ORDER_YXZ`, so the basis is `Ry * Rx * Rz`
and the light points along local −Z:

| light | camera | screen angle (0° = from the right) |
|---|---|---|
| house `(−44, −118, 0)` | diorama, tilt −31° | **130°** |
| house `(−44, −118, 0)` | battle, tilt −38° | **130°** |
| battle's current `(−50, −140, 0)` | battle, tilt −38° | **114°** |
| *what the sprite generator bakes* | — | **130°** |

Three things follow.

**The two cameras agree.** Despite an 7° difference in tilt, the house angle
projects to the same screen direction in both, within a degree, so **one baked
direction serves both scenes**. That is luck rather than law: both cameras are
tilted about X only and neither is yawed. A scene whose camera looks along a
different axis would need this recomputed, and would probably need its key
angle chosen to match rather than inherited.

**The battle scene's key is 16° off in screen space**, which is the real cost of
the misalignment already on the remediation list below — not an abstract
inconsistency but sprites lit from noticeably the wrong side. Aligning it fixes
lighting and sprites in one edit.

**The bake is now derived, not eyeballed.** `creature_forge.py` computes its
light vector from `HOUSE_KEY_EULER` and the camera tilt rather than carrying a
hand-picked constant, so changing the house angle changes the sprites instead of
obliging someone to remember that it should. For the record the hand-picked
value was 127° against a correct 130° — a good guess, and not a reason to keep
guessing.

## Rules for a new scene

For whoever builds region two:

1. Copy the environment block from `build_diorama.gd` and change only the sky,
   ambient energy, and key light *colour and energy*. Everything else — tonemap,
   glow, SSAO, adjustment, fog — is house style.
2. Key light at `(−44, −118, 0)`. Not negotiable while sprites carry baked
   shading.
3. FOV 18. To fit more in frame, move the camera back, never widen the lens.
4. Set the DOF band around the subject's actual distance from the camera, and
   then *check the arithmetic*, because a band that brackets nothing looks
   exactly like a band that is turned off, and neither `verify.sh` nor a glance
   at the file will tell you which you have.
5. At least one practical light. A directional key alone reads as a render; a
   warm point source in the scene reads as a place.

## Remediation, for a tick with an engine

In order, cheapest first, each one a frame to look at before and after:

- Add the diorama's fog block to `build_battle.gd`. One paste.
- Pull the battle DOF band in to bracket the board — roughly 20 → 28 — and check
  the Back labels are still readable. If they are not, the far edge goes out
  until they are, and *that number gets a comment*.
- Try FOV 18 with the camera pulled back to about z = 26, and compare frames
  against the current 28°/19. Keep whichever reads better as a diorama, and write
  down which and why either way.
- Align the battle key light to `(−44, −118, 0)`, keeping its cold colour.
