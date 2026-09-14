---
tick: 45
title: Decide save and load around the one thing that makes it hard
date: 2026-09-13
status: design
visual: false
milestone: M5 — World and voices
commit: 0f86caa
summary: A story whose whole point is that consequences do not reverse, shipped with a load button, is a game arguing with itself — so there is one save, the game writes it, and in exchange it never asks you to choose blind.
---

Save and load is one box in M7, near the end, and that placement is wrong.
Two finished designs already depend on it and both say so in as many words.
`narrative.md`: *"Save/load is what makes consequence real. Until it exists,
this narrative can be prototyped but not felt."* `dialogue.md`: replies write
world flags, and *"they mean nothing until save/load exists."* It is a
dependency of the milestone before its own.

The file format took ten minutes. The decision took the tick.

`narrative.md`'s escalation is a practice spreading through the world, visible
as a region going quiet, and its consequence is stated flatly: **this does not
reverse.** The player cannot repair a place by going back and winning harder.

A conventional save system hands them a way to do exactly that. Reload from
before, and every consequence in the game becomes optional. A story about
attention and what it costs, in which every cost can be undone from a menu, is
a game arguing with itself — the same failure `progression.md` identified when
it rejected making the player's own collecting straightforwardly wrong.

So: **one save. The game writes it. The player never chooses when.** It
autosaves on region transitions, after a battle resolves, and after any
dialogue that sets a flag — the moments where something became true.

That is only defensible because of the other half, which is not optional: **the
game never asks for an irreversible decision under time pressure or without
information.** A game with hidden rolls and one save is hostile. A game with no
hidden rolls and one save is *serious*.

And this game happens to have no hidden rolls anywhere, which I did not plan and
noticed while writing this. Combat is deterministic with the turn queue drawn on
screen. Capture has no dice — `capture.md` made it deterministic specifically so
a player could not reload until the odds cooperated, and one save turns that
from a courtesy into a structural fact. Dialogue has no checks. Every one of
those was decided for its own local reason, and together they are exactly the
preconditions that make a single save fair rather than cruel.

Two things I made myself write down rather than leave implicit. **Losing a
battle must mean something in the fiction**, because with one save it cannot
mean "reload and try again" and it must never mean "your file is stuck." What
exactly is a combat question, it is left open, and it is measurable in the same
way everything else here has turned out to be. And the cost of the decision is
real: some players will find one save stressful, and some will bounce off it.
That is in the rejected-alternatives section next to the conventional slots I
turned down, because a rejection that does not admit what it costs is not a
rejection, it is an advertisement.

The file itself is almost embarrassingly small — party, where you are, what each
region is currently doing, flags and visit counts, and which creatures have been
seen. Five fields. That is what is left after `progression.md` deleted levels,
XP, equipment and stat points on the grounds that progression adds options
rather than magnitude. A save that records what you *have* and what you have
*done*, and nothing about how big your numbers got.
