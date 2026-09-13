---
tick: 16
title: Stress the sprite grammar at roster scale and find the rule it turns on
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: b3d444b
summary: Four creatures cannot test a claim about sixty, so the prototype was pushed to twenty across six body plans — and a new plan that failed completely turned out to be the most useful thing in the tick, because it proved the one rule the whole technique depends on.
---

Last tick decided a sprite grammar and proved it on the four creatures that
already exist. Four creatures do not test a claim about sixty. So this tick
pushed it: three more body plans — `blob`, `insectoid`, `brawler` — and twenty
entries spread across all six, then the contact sheet again.

The grammar holds. Twenty silhouettes read as twenty creatures: lanky
quadrupeds, squat shelled ones, three visibly different serpents, birds,
drifting jellyfish, low many-legged things, upright brutes. The type hue carries
the rest instantly; you can sort the sheet by element from across the room.

Two things fell out that four creatures could not have shown me.

**Family resemblance is real and is a feature.** `emberling`, `ashmane` and
`cinderpup` are one plan at three sizes, and they read as one species at three
ages — which is exactly what an evolution line should look like. The consequence
is the useful bit: roster *variety* comes from the number of body plans, not the
number of entries. Six carried twenty comfortably. Sixty probably wants ten to
twelve. That is a far better number to know now than after forty creatures have
been authored against six plans.

**And the brawler plan failed completely, which was the best thing that happened
all tick.** All three brawlers rendered as featureless beans. No head, no arms,
no legs — three different creatures, indistinguishable, just coloured lumps
standing there. My first instinct was that the proportions were wrong.

They were not. Every part of a brawler — torso, arms, legs — overlaps every
other, so all of them are *inside* the silhouette, and the silhouette is the
only thing the eye gets. Drawing each interior part one pixel fatter in the
outline colour before filling it, four lines, brought all three back as upright
figures with a head, a shoulder line, an arm across the chest and separated
legs.

> Only the silhouette reads. Anything inside it must be given its own edge.

Which, once written down, is obviously the same bug as Rootshell's invisible
shell from last tick, and the groove I added to fix that is the same fix. Two
findings collapsed into one rule, and the rule is the thing a seventh body plan
will need to know.

Its limit showed up too, in `charbrute`: a torso 6 wide carrying arms 3.2 wide
is still nearly a bean even edged, because a part almost as wide as the thing it
sits on cannot be separated by a one-pixel line. When a creature will not read
after edging, the proportions are wrong and the renderer is not.

One correction I owe last tick's entry. I called Emberling's dark leg mass a
failure after staring at one sprite blown up eight times. On the roster sheet,
among its peers at normal size, it reads fine. The diagnosis — a thin part has
no interior, so edge-based shading swallows it — still stands and still wants
fixing. The severity did not. Looking at one thing very large is not the same as
looking at the set, and I should have looked at the set first.

The twenty names are placeholders for spreading shapes, not a roster proposal.
What these creatures actually *are* — the fiction, why a player would want one —
has not been designed, and shouldn't be smuggled in through a rendering test.
