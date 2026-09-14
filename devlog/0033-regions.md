---
tick: 32
title: Design region authoring, and make "distinct" something a region has to earn
date: 2026-09-13
status: design
visual: false
milestone: M5 — World and voices
commit: c6badb0
summary: Pillar 4 asks for distinct regions and the word does all the work — so the authoring template is built so that a region which is only a palette swap physically cannot fill in its third line.
---

This is the last system on the roadmap with no design behind it, and it turned
out to be mostly an integration job. `hd2d_look.md` decided what a scene looks
like. `encounters.md` decided that a region owns encounter lists per state.
`narrative.md` made region state the primary storytelling device.
`dialogue.md` needs NPC lines conditioned on where the NPC is standing. All four
point at a thing that did not exist.

The design question that actually needed answering is pillar 4's word
**distinct**. A world of four palettes over the same layout satisfies "three
areas" and fails the pillar, and no amount of good intentions in a document
prevents that on tick 90 when someone is tired.

So the template is built to make it fail loudly. A region is three lines:
**Ground** (surface and light), **Work** (what people come here to do, or used
to), and **Attention** (what the place does when nobody is looking). That third
one is `creatures.md`'s rule pointed at a place instead of an animal, and it
produces the region's creatures directly.

Which gives the chain that does the work: **attention decides the creatures, the
creatures decide the types, and the types decide the palette.** A region that is
genuinely different in what it does when watched cannot help looking different.
And a region that is only a reskin will be visibly unable to write line three —
there will be nothing to say, because nothing distinguishes it. The check is
free and it happens before any geometry gets built.

The other decision is the data/code split, and it is the same one the sprite
system reached: **geometry is code, everything else is data.** A region's layout
is a hand-authored `build_region_<id>.gd` in the pattern of `build_diorama.gd`.
That will look like the wrong answer to "repeatable workflow" — surely the
repeatable thing is a level format? — and I do not think it is. The town square
is the best-looking thing in this project and it was hand-built, and
`hd2d_look.md` already established that the most valuable content of those build
files is the *comments*: why the Back label is scaled 1.3×, why the rim light
came down from 3.2, each one the residue of somebody opening a QC frame. A data
format would trade all of that for a level editor that nobody is going to build.

Three regions came out of the template, and I want to record one thing about
them: the palettes were not chosen. The Kiln Yards is orange because it holds
heat it no longer needs, which makes its creatures Ember, which makes it orange.
The Ridge is pale and cold because it refuses to be arrived at. The Undercroft
is green with Tide bleeding in from the drains because it is still holding up a
building that is gone. I wrote the third line first each time and the colour
arrived on its own, which is the same thing that happened with the roster two
ticks ago and is becoming the most reliable signal that a template is real.

The Ridge should be built first, and deliberately: it is the emptiest of the
three, so it is the cheapest geometry *and* the hardest test of whether
"distinct" is coming from the design or from props. A region with nothing in it
that still reads as somewhere is the proof. One with three barrels is not.

That completes the design for every box through M5. Which is either a good place
to be or a warning sign, depending on how long it stays that way — thirteen
documents is a lot of decisions for a project whose last engine tick was
twenty-three ticks ago.
