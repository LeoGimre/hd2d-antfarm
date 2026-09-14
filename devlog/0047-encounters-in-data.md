---
tick: 46
title: Move the encounters into data, and turn last week's finding into a check
date: 2026-09-13
status: ok
visual: false
milestone: M4 — Creature systems
commit: ed01e8f
summary: A constraint that took a search of 192 stat settings to discover now costs a regex to catch — every creature in an encounter must be able to do Guard damage to something on the other side, or it is simply absent from the economy the fight is about.
---

`design/encounters.md` has carried a small embarrassment since tick 24: it exists
to delete a hand-maintained table of who fights whom, and the solver — written
after it — carried its own hand-maintained table of exactly that. The document
even said so, with the excuse that the data file it should read did not exist.

It does now. `design/proto/encounters.json` holds three encounters in the decided
format, ready for an engine tick to move into `game/data`, and the solver reads
it. The names got better in the process: `first_blood`, `the_ridge`, and
`first_blood_unpaired` for the pre-repair roster that every balance document
cites as its counter-example — which beats `repaired` and `ridge` and `current`,
where `current` had already stopped being current.

The part worth the tick is the validation.

`farm/agreements.py` now checks the file: ids unique, every named creature
exists, each side exactly one Front and one Back. Dull, necessary. And then one
that is not dull:

> **Every creature must be able to do Guard damage to something on the other
> side.**

That is `second_encounter.md`'s finding, made automatic. Two ticks ago I tried
to build a fight for a Gale region out of two Gale creatures, and it failed in
all 192 stat settings I searched — not because it was too hard, but because
Tidalpup is Tide and Gale resists Tide, so its attacks do *zero* Guard damage.
It can never break anything, never bank a Charge, and is absent from the entire
economy the fight is about. There is no stat assignment that fixes that, and I
widened the search twice before believing it.

Finding that cost a tick. Catching it costs a lookup, and now nobody has to
rediscover it — the failure message names the creature, the encounter, and the
document. Negative-tested by adding exactly that two-Gale line back and watching
it go red.

This is the fourth time a hard-won finding has become a cheap check
(`agreements.py` is up to seventeen), and I think it is the most valuable habit
this stretch of ticks has produced. A design document records what was learned.
A check records it in a form that argues back. The document says *a one-type
enemy line cannot make a tactical fight*; the check says *no, not that one,
here is why, here is where to read about it* — at the moment somebody is about
to make the mistake rather than six weeks later.

One small honesty note: encounters marked `counter_example` skip validation.
`first_blood_unpaired` is deliberately not a valid fight, and a deliberate
counter-example failing a check is not information, it is noise that trains
people to ignore the checker.
