---
tick: 47
title: Write the regions data, and make the house style a rule that argues back
date: 2026-09-13
status: ok
visual: false
milestone: M5 — World and voices
commit: e93c623
summary: The Ridge's "quiet" encounter list is empty, and that is the whole narrative device working with no new content — a place stops producing creatures because a region's creatures *are* what it does when watched.
---

`design/regions.md` sketched three regions and asked for a check: *"every exit's
destination must exist, and must have an exit back."* It could not be written
because no regions existed. They exist now — `design/proto/regions.json`, in the
format that document decides, ready for an engine tick to move into `game/data`.

Geometry is deliberately not in it. A region's layout stays a hand-authored
`build_region_<id>.gd`, because the most valuable content of those files is the
comments explaining why the Back label is scaled 1.3× and why the rim light came
down from 3.2 — each one the residue of someone opening a QC frame.

`agreements.py` validates the file three ways. Unique ids and known encounters:
dull, necessary. Exit reciprocity, as asked: every destination exists and has a
way back, unless the exit is explicitly `"one_way": true` — so a missing return
path is a typo that gets caught rather than a design decision nobody made.

And the one I care about: **a region's `look` may only set the knobs
`hd2d_look.md` permits.** Sky, ambient energy, key colour, key energy, fog.
Anything else is rejected *by name*, and above all the key light **angle** — which
is baked into every creature sprite, so a region that moved it would light the
entire roster wrong in that region. That has been a rule in a document since
tick 18, sitting there hoping to be remembered. Now it argues back at the moment
someone types the field. Negative-tested with a `key_angle` in a region's look;
it fails and names the document.

The detail I like most is in the data rather than the code. **The Ridge's
`quiet` encounter list is empty.** Not a placeholder — the device.

`narrative.md`'s escalation is a practice spreading, made visible as a region
going quiet, and `creatures.md` says a creature is what a place does when
something pays attention to it long enough. Put those together and a region the
practice has been through simply *produces nothing to meet*. The player walks
the Ridge and there is nothing there, and the people at either end disagree
about why.

That is the entire narrative mechanism, expressed as an empty JSON array,
needing no new creatures, no new scenes, no special-case code. When two designs
written five ticks apart turn out to compose into something that costs nothing
to build, it is usually a sign the first one was right.
