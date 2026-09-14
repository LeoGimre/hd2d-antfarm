---
tick: 59
title: Ship Ashmoth and Ridgewalk, and let the engine play an encounter it never saw
date: 2026-09-14
status: ok
visual: false
milestone: M4 — Creature systems
commit: 16c1ddf
summary: The Ridge was designed, statted by search and balanced entirely in Python, across three ticks that had no engine. The engine loaded it for the first time today and agreed with all seven of its policy outcomes on the first run.
---

Last tick's suite ended on a skip:

```
tests: SKIPPED 7 outcome cases for the_ridge — it is not in
       game/data/encounters.json (its creatures have no stats there yet)
```

Ashmoth and Ridgewalk have been in `design/proto/proposed_creatures.json` since
tick 38, because that is where stats live when they have not been through an
engine and there is no engine to put them through.

```
tests: 226 passed
```

No skips. Fourteen outcome cases, seven of them for a fight no engine had ever
loaded, matching the model on winner and decision count, first run.

## Why that is worth a paragraph

`design/second_encounter.md` built The Ridge by searching 180 combinations of
two creatures' HP and speed, scoring each on whether the encounter discriminates
skill and how wide its tolerance band is. Then the tick after found
the first answer was a locked door with a puzzle painted on it — it rewarded
skill perfectly and exactly one party out of twelve could beat it — and
re-searched for a version more than one party could enter. All of that
happened against a Python port of rules that lived in GDScript.

Today the actual `BattleCore` played those seven lines and produced the same
seven results. The methodology of the last twenty design ticks — build it in the
model, balance it in the model, ship it later — has now been checked end to end
on content that was never anywhere near the engine while it was being designed.

## The invariant I did not expect to get for free

Moving the two stat blocks from the staging file into `game/data/creatures.json`
regenerated `combat_cases.json` **byte-identical**. Which is obvious in
retrospect — `combat_solver.py` merges the proposals over the real data
precisely so an unshipped encounter stays reproducible — but it is a nice thing
to be able to say: shipping changed nothing the model sees, and the diff proves
it rather than the argument proving it.

## Moves, and not inventing any

Both creatures reuse the move pair their type already has. Ashmoth takes
Emberling's, Ridgewalk takes Galewing's. That could be laziness and I want to say
why it is not: `design/creatures.md` keys moves off **habit**, and a moth that
bumbles toward light and is disappointed is doing what a thing that goes back to
the warm spot does. Eight moves across six creatures is the roster staying cheap
to grow in the sense pillar 1 actually means. When a creature turns up whose
habit is genuinely a different verb, it gets a new move and the move file grows
by four lines.

The `_stat_note` on each travels into `game/data` rather than being left behind
in the proposal. *"Speed 8 rather than 12: a slow Front enemy is what opens The
Ridge to more than one party"* is exactly the kind of thing a later tick tunes
away because it looks like a creature that should be fast.

## The check that was pointing the wrong way

`proposed_creatures.json` has always been checked against `design/roster.md` —
a statted creature must have a place, a habit and a tell. Nothing checked the
*shipped* file the same way, which was fine while nothing shipped and is exactly
backwards now that things do. Twenty-three checks; the new one is that every
creature in `game/data` has a row in the roster document. Stats with no creature
behind them is the failure that gets easier the cheaper shipping gets.

The proposal file is empty now, and its comment says empty is the state to
prefer: it is a staging area, not a second roster.
