---
tick: 21
title: Measure how much progression pillar 2 can survive, then design to fit
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: 3d96298
summary: Five percent more player HP turns the proof battle from a fight bad play loses into one bad play wins — but tripling both sides changes nothing at all, which settles what progression is allowed to be and also reveals that HP-remaining has been lying about how close these fights are.
---

M4's last undesigned box is party management and progression, and progression is
the one place this game's shape actively fights its own pillars. Pillar 2 says a
skilled player beats an over-levelled one. Every JRPG this thing resembles
answers progression with *numbers go up*. Those cannot both be true without
someone deciding where the line is.

The pillar has a number in it, so I measured instead of arguing.

The result is much starker than I expected. Against the re-paired proof battle,
where naive play loses and correct play wins:

- **+5% player HP** — naive play wins.
- **+3 move power** — naive play wins.
- **+1 Guard** — naive play wins.
- **+15% on everything** — naive play wins, comfortably.

Five percent. Thirty-six HP to thirty-eight. That is smaller than the rounding
on a single hit, and it is enough to turn a fight that demands correct play into
one that does not.

And then the other half, which I nearly did not run: scale *both* sides. Double
everyone's HP — naive still loses, correct still wins. Triple it — identical.
The tactical structure is completely scale-invariant. Magnitude is free. Only
the **ratio** matters, and the ratio has a tolerance of roughly minus fifteen to
plus five percent.

That is not a tuning choice anyone could loosen. It is close to a theorem: a
fight that discriminates skill is a fight sitting near a boundary, and anything
that moves the numbers moves you off it. Any encounter tight enough to satisfy
pillar 2 is, by construction, this fragile.

Which makes the design decision write itself. **Progression adds options, never
magnitude.** Creatures learn moves — new type coverage, new reach, a plan you did
not have — which changes everything about what is possible and nothing about
throughput. The roster itself is the progression, which is pillar 1 and pillar 2
pointing the same way for once. Bonds produce conditional traits, never
percentages: "while in Back, ranged moves ignore the Back penalty" is a trait,
"+10% damage" is a pillar-2 violation with a nice name. And Guard never grows
under any circumstances, because one point of it flipped the fight — Guard is
not a stat, it is a discrete gate counting how many hits break you.

Two things fell out that matter more than the progression decision.

The first is that Guard's discreteness is a general hazard. Anything that changes
a *count* — hits to break, turns survived — moves outcomes in steps, not slopes.

The second is worse, and it is about my own last two balance ticks. **HP
remaining is a bad measure of how close a fight is.** Naive loses the proof
battle with the enemy still holding 24 of its 52 HP. That reads comfortable. It
is not: five percent more player HP reverses it, because surviving one extra hit
buys one extra turn and the turn compounds. Tick 9 spent its entire budget
chasing lines that came "within 2–10 HP" and treated that as nearly-there. Tick
10 quoted HP margins in its results table. Both were measuring the wrong thing.
The real number for an encounter is its **stat-tolerance band** — how far each
side can move before the result flips — and it is cheap to compute and I had not
thought to.
