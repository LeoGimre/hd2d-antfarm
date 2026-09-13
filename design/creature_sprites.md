# Composable creature sprites

M4's second box is *"composable creature sprite system: parts, palettes,
per-species proportions."* The tool that exists today, `game/tools/pixelforge.py`,
calls itself the seed of that system, and it is — but only of the palette half.
The traveler in it is one hand-authored 24×32 character map. That is the right
way to make one hero and a completely impossible way to make sixty creatures,
and pillar 1 says the roster keeps growing.

This document decides the grammar. It is backed by a working generator,
`design/proto/creature_forge.py`, which was run and whose output was looked at —
that is the only reason to believe any of the claims below.

## The grammar

> A creature is **(body plan, proportions, palette, features)**.

- A **body plan** is a *function* of proportions that emits a silhouette:
  `quadruped`, `serpent`, `avian`, and however many more the roster needs.
- **Proportions** are the numbers that plan takes: body radii, leg length and
  width, neck length, head radius, tail length, splay.
- A **palette** is five colour roles — outline, shadow, base, light, spec —
  generated from a single hue and saturation, which come from the creature's
  type.
- **Features** are small overlays with their own draw functions: horns, crest,
  shell, fins.

An author adding a creature writes one entry:

```python
"rootshell": dict(plan="quadruped", type="Root", feats=["shell"], p=dict(
    body_rx=8.6, body_ry=5.6, leg=3, leg_w=2.4, neck=3, neck_w=2.2,
    head_r=3.0, snout=1.6, tail=3, tail_w=1.4, tail_lift=0, splay=1.2)),
```

That entry is data and belongs in `game/data/` next to the creature's stats.
Body plans and feature functions are code, because they are genuinely new art
rather than new content — the same line this project already draws between
`creatures.json` and `combat_resolver.gd`.

**The body plan has to be a function, not a stored map.** This is the whole
trick and it is worth being explicit about, because "parts stamped onto a
template" is the obvious design and it cannot express the middle word of the
box's own title: a hand-drawn map has already committed to its proportions, so
"per-species proportions" can only be a parameter of something that draws.

## Three mechanical passes do most of the art

The generator's real value is not composition. It is that the parts of pixel art
which read as *craft* are mechanical, and can therefore be free:

1. **Auto-outline.** Draw the silhouette, then set every empty pixel
   4-adjacent to a filled one to the outline colour. Coherent outlines are most
   of what separates pixel art from a coloured blob, and nobody has to draw one.
2. **Distance-field shading.** Compute each filled pixel's distance from the
   silhouette edge, take the direction from the sprite's centroid to that pixel,
   and dot it against a light direction. Rim toward the light, shadow away from
   it, base tone in between.
3. **Drawing order as depth.** Parts drawn into a `FAR` channel shade flat dark,
   whatever the light says.

**One light direction for the entire roster.** Pillar 6 wants every frame to read
as one lit diorama; a creature lit from its own private angle breaks that
instantly. Which means the baked direction has to agree with the scene's key
light — `build_battle.gd` currently puts `Key` at `rotation_degrees
(-50, -140, 0)`. If that ever moves, the sprites are wrong, and nothing will
tell you except your eyes.

## What running it actually taught

Five of these were not obvious before there were pixels to look at, which is
the argument for prototyping a design rather than only describing one.

**Drawing order is depth, and without it four legs are one blob.** The first pass
drew all four legs into the same channel; every quadruped came out with a single
dark mass beneath the body. Drawing the far pair first, offset back and up, into
a channel that always shades flat dark — which is what a sprite artist does by
hand, since the point is separation and not description — fixed it in one change.

**Shading belongs on edges; interiors carry the colour.** The first shading rule
darkened any pixel facing away from the light. Every leg is below the centroid,
so every leg pixel faced away, so the legs went black. Restricting the shadow
band to pixels within one or two of the edge and letting interiors keep the base
tone is both more correct and much closer to how the art form actually works.

**An overlay feature merges invisibly unless it draws its own seam.** Rootshell's
shell was a perfect ellipse sitting inside a body of the same colour: completely
invisible. Forcing a one-pixel dark groove along the overlay's boundary is what
makes it read as sitting *on* the creature.

**The eye must be drawn after shading and never shaded.** One dark pixel on a
dark flank does not exist. An eye needs its own light field to sit in, and at
this size that field is two or three pixels of the brightest ramp role with the
pupil inside it. Adding this did more for "reads as a creature" than any other
single change.

**A hue ramp needs hue drift, not a brightness slider.** Five roles from one
hue works, but only if the hue itself drifts warm into the light and cool into
the shadow. Straight value steps on a fixed hue look like a UI gradient.

### What it did not solve

Emberling — long thin legs under a small body, on the unlit side — still reads
as a torso above a dark mass, and three attempts did not fix it. The diagnosis is
general and worth writing down: **a thin part has no interior**, so any
edge-based shading rule swallows it whole. A 3-pixel leg is all edge. The fix is
probably a forced mid-tone spine down the centre of thin limbs, or a weak second
light from below; both need trying against pixels rather than reasoning about.

The rest of the roster came out legible: Rootshell reads as a shelled
quadruped, Tidalpup as a serpent rearing off the ground, Galewing as a winged
biped, each in its type's colour, all under the same light. Three out of four
from one generator is enough to believe the grammar; the fourth is a tuning
problem, not a structural one.

## Does it scale?

The grammar's whole claim is about sixty creatures, and four creatures do not
test it. So the prototype was pushed to **twenty entries across six body plans**
— three more plans (`blob`, `insectoid`, `brawler`) and enough proportion spread
to cover a roster's worth of shapes — and the sheet was looked at again.

**It holds.** Twenty silhouettes read as twenty creatures: lanky quadrupeds,
squat shelled ones, three visibly different serpents, birds, drifting jellyfish,
low many-legged things, upright brutes. Type hue does the rest of the work
instantly.

Two structural things came out of it.

**Same plan plus different proportions produces family resemblance, and that is
a feature.** `emberling`/`ashmane`/`cinderpup` read as one species at three
sizes, which is exactly what an evolution line should look like. But it means
roster *variety* is driven by the number of body plans, not by the number of
entries. Six plans carried twenty comfortably; sixty probably wants ten to
twelve. That is a much better number to know now than after forty creatures
have been authored against six.

**And the rule that matters most:**

> **Only the silhouette reads. Anything inside it must be given its own edge.**

The `brawler` plan proved this by failing completely. Its torso, arms and legs
all overlap, so all three brawlers rendered as featureless beans — three
different creatures, indistinguishable, no head, no arms, no legs. Nothing was
wrong with the proportions; the parts were simply *inside* the silhouette, and
the silhouette is the only thing the eye gets. Drawing each interior part one
pixel fatter in the outline colour before filling it — `taper_edged()`, four
lines — brought all three back as upright figures with a head, a shoulder line,
an arm across the chest and separated legs.

That rule subsumes the shell finding from the first pass. A shell merging into
a body and an arm merging into a torso are the same bug, and the groove and the
edged limb are the same fix. Worth stating once, at the top, for whoever writes
body plan number seven.

Its limit is visible too. `charbrute` — a torso 6 wide with arms 3.2 wide — is
still nearly a bean even with edges, because a part nearly as wide as the thing
it sits on cannot be separated by a one-pixel line. When a creature will not
read after edging, the proportions are wrong, not the renderer.

One correction to the first pass: Emberling's dark leg mass, which looked
fatal at 8× on its own, reads acceptably at roster scale among its peers. The
diagnosis — a thin part has no interior — still stands and still wants fixing,
but it was judged too harshly from a single blown-up sprite. Looking at one
thing very large is not the same as looking at the set.

**The twenty names are placeholders.** They exist to spread shapes across the
plans, not to propose a roster. What these creatures actually *are* — the
fiction, the naming, why a player would want one — is its own design tick and
has not happened.

## Rejected alternatives

- **One hand-authored character map per creature**, as the traveler is done
  today. It is what pixelforge already supports and it produces better sprites
  than any generator will. Rejected on arithmetic: M6 wants sixty creatures, and
  sixty hand-drawn maps is sixty ticks that produce no systems. The traveler
  stays hand-drawn precisely because there is one of him.
- **Parts stamped onto a fixed template.** The obvious composable design, and
  unable to express proportions, as above. It also puts the hardest artistic
  judgement — where two parts join and how the outline flows through the seam —
  on the person adding a creature, which is exactly the cost pillar 1 forbids.
- **A skeleton with procedurally-grown limbs.** More expressive than parametric
  plans and much harder to keep legible at 40×44, where every pixel is about
  three percent of the sprite's width. Worth revisiting only if the roster
  outgrows what a handful of plans can shape.
- **Rendering 3D models to sprites.** The standard way to get a large consistent
  roster cheaply, and a direct violation of GAME.md's non-goals: no 3D character
  models, sprites only, because that is what makes this HD-2D.

## Handoff

The prototype is Python and lives in `design/proto/` rather than
`game/tools/` on purpose: this container has no Godot, and new PNGs in
`game/assets/` need `godot --headless --import` to generate their `.import`
files or they load as null textures — a failure `verify.sh` does not catch.
Shipping half of that would be worse than shipping none.

For the engine tick that picks this up: port the generator into
`game/tools/creature_forge.py` alongside `pixelforge.py`, move the roster block
into `game/data/`, generate, import, and look at the frames before believing
any of it. Then the composable-sprite box is real, and the battle scene can stop
being four coloured capsules.
