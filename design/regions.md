# Regions

M5's first box is *"a repeatable region authoring workflow."* Its second is
*"three distinct areas with transitions between them."* Pillar 4 wants a large
explorable world of **distinct regions worth crossing, with reasons to cross
them** — and the word doing the work there is *distinct*, because a world of
reskins is one region with four palettes.

This is the last system in the roadmap without a design. It is also mostly an
integration job: `hd2d_look.md` decided what a scene looks like,
`encounters.md` decided that a region owns encounter lists per state,
`narrative.md` made region state the primary storytelling device, and
`dialogue.md` needs NPC lines conditioned on where they are standing. What is
missing is the thing those four hang from.

## What a region is authored from

Three lines, deliberately shaped like `creatures.md`'s place/habit/tell, because
that template has now been used twenty times and it generated rather than
decorated.

**Ground** — the surface and the light. *Produces the look:* which of
`hd2d_look.md`'s three permitted knobs get turned (sky, ambient energy, key
colour and energy), which ground texture, whether there is fog and how much.

**Work** — what people come here to do, or used to. *Produces the set dressing,
the NPCs, and the reason to cross it.* Pillar 4 asks for reasons; a region where
nobody has ever wanted anything does not have one.

**Attention** — what the place does when it is watched. *Produces its
creatures*, directly, via `creatures.md`: a creature is what a place does when
something pays attention to it long enough. It also produces the region's
narrative state, because `narrative.md`'s escalation is a place doing less of it.

The chain matters: **Attention decides the creatures, the creatures decide the
types, and the types decide the palette.** So a region that is genuinely
different in what it does when watched cannot help looking different, and one
that is only a palette swap will be visibly unable to fill in line three. That
is the check against reskins, and it is free.

## What is data and what is code

The same split the sprite system settled on, for the same reason.

**Geometry is code.** A region's layout lives in a `build_region_<id>.gd` tool
in the pattern of `build_diorama.gd` — hand-authored, run offline, saving a real
`.tscn`. The town square was hand-built and is the best-looking thing in the
project, and `hd2d_look.md` records that the most valuable content of those build
files is the *comments*, which explain why each tuned number is what it is. A
data-driven layout format would trade that for a level editor nobody has built.

**Everything else is data**, in `game/data/regions.json`:

```json
{
  "regions": [
    { "id": "kiln_yards",
      "display_name": "The Kiln Yards",
      "look": { "sky": "dusk_ash", "ambient_energy": 1.05,
                "key_color": [1.0, 0.86, 0.66], "key_energy": 1.2, "fog": 0.010 },
      "encounters": { "default": ["kiln_pair", "kiln_lone"],
                      "quiet":   ["kiln_lone"] },
      "conversations": ["kiln_yard_woman", "the_stoker"],
      "exits": [ {"to": "the_ridge", "from_marker": "NorthGate"} ] }
  ]
}
```

`look` may only set the knobs `hd2d_look.md` permits — sky, ambient energy, key
colour and energy, fog. Tonemap, glow, SSAO, adjustment, FOV and the key
**angle** are house style and are not per-region, because the key angle is baked
into every creature sprite and a region that moved it would light the whole
roster wrong.

`encounters` is the per-state list `encounters.md` deferred to this layer, and
it is why an encounter stays atomic: a quieter version of a place is a shorter
list here, not a condition inside a fight.

## The workflow, as steps

The box says *repeatable*, so it should be a list rather than a paragraph:

1. Write the three lines. If line three is hard, the region is a reskin — stop.
2. Add the creatures it produces to `design/roster.md` and the generator.
3. Add its entry to `regions.json`: look knobs, encounter lists per state,
   conversations, exits.
4. Copy `build_diorama.gd`'s environment block, change only the permitted knobs,
   author the geometry, and **check the DOF band's arithmetic against the actual
   subject distance** — `hd2d_look.md` records that a band bracketing nothing is
   indistinguishable, in the file, from one that works.
5. Balance each new encounter with `combat_solver.py`'s four-step checklist from
   `encounters.md`.
6. Write conversations, holding `dialogue.md`'s bar: every NPC needs one line
   that only appears because the player changed something.
7. Capture a clip and *look at it*.

## Transitions

An exit is a marker in the region's scene plus a destination id. Walking into it
loads the destination and places the player at the reciprocal marker. That is
all; there is no path-finding, no world map, no streaming.

Reciprocity is the thing that rots, so it belongs in `farm/agreements.py`:
**every exit's destination must exist, and must have an exit back.** A one-way
door is then a deliberate thing somebody wrote down rather than a typo.

**Both are checked now.** `design/proto/regions.json` holds the three regions
below in this format, and `agreements.py` validates it: unique ids, every
referenced encounter exists, every exit's destination exists and has a way back
unless the exit is marked `"one_way": true` — and, the one that matters most,
**a region's `look` may only set the knobs `hd2d_look.md` permits.** Sky, ambient
energy, key colour, key energy, fog. Anything else, and above all the key light
*angle*, is house style and is rejected by name, because the angle is baked into
every creature sprite and a region that moved it would light the whole roster
wrong. That was a rule in a document; it is now a rule that argues back.

One detail in the data worth pointing at: The Ridge's `quiet` encounter list is
**empty**. That is not a placeholder. `narrative.md`'s escalation is a place
doing less of what it does when watched, and a region's creatures *are* that —
so a Ridge the practice has been through produces nothing to meet, and showing
it needs no new content at all.

## Three regions, sketched

Concrete enough to build against, drawn from the places the roster already
implies.

**The Kiln Yards.** *Ground:* fired brick and ash, low warm light, everything
slightly too orange. *Work:* people fired pots here, and two of five kilns still
run. *Attention:* it holds heat it no longer needs — things here sit on warmth
and pretend it is coming back. → Ember. Emberling, Stokewake, Lastcoal,
Bellowsback.

**The Ridge.** *Ground:* bare rock, thin cold light, nothing between you and the
sky. *Work:* the fastest way between two valleys, and nobody stops. *Attention:*
it refuses to be arrived at — things here perform being out of reach. → Gale.
Galewing, Ridgewalk, Doorslam, Bellhang.

**The Undercroft.** *Ground:* wet stone under a town that grew over it, lit by
what falls through gratings. *Work:* it was foundations, then storage, then
forgotten. *Attention:* it keeps holding up something that is no longer there.
→ Root, with Tide bleeding in from the drains. Holdfast, Gravebind, Downspout,
Wellmouth.

Three grounds, three kinds of work, three different answers to what the place
does when watched — and consequently three palettes that fell out rather than
being chosen. The Ridge is the one to build first: it is the emptiest, which
makes it the cheapest geometry and the hardest test of whether "distinct" is
coming from the design rather than from set dressing.

## Rejected

- **A data-driven level format.** The obvious reading of "repeatable," and it
  needs an editor to be usable, which is a bigger project than the regions it
  would author. It also loses the build files' comments, which are where the
  expensive knowledge lives.
- **Procedural region generation.** A `GAME.md` non-goal, stated outright: the
  world is authored. Noted only so nobody re-derives it.
- **Per-region key light angles.** Would make each region visually distinctive
  for free, and would light every creature sprite wrong in every region but one,
  since the shading is baked. `hd2d_look.md` computed the number; this is where
  it bites.
- **A world map screen.** Cheap navigation and it deletes the point of pillar 4.
  If crossing a region is not worth doing, the fix is the region.
