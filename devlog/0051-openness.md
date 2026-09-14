---
tick: 50
title: Find that an encounter can reward skill and still admit only one party
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: 2ad793a
summary: The Ridge rewarded skill perfectly and could be beaten by exactly one party out of twelve, which is a locked door with a puzzle painted on it — and the fix turned out to be making one enemy *slower*.
---

Last tick measured that only two of twelve player pairs can beat The Ridge, and
I recorded it as an interesting fact about party choice. On reflection it is not
a fact about party choice. It is a fault, and it is mine.

I built The Ridge by searching 180 stat settings for ones that **discriminate
skill** — naive loses, correct play wins, hoarding your Charges loses. It does
all three, beautifully. And it can be entered by one party. Compare
`first_blood`, which I did not tune at all and which admits six pairs and four
different Front creatures.

**A fight exactly one party can win is a key check, not a tactical fight.** The
skill it tests is "did you bring the key." A world made of those is a set of
gates rather than somewhere worth crossing, which is pillar 4's whole ask. And I
would not have noticed, because every metric I had built said the encounter was
excellent.

So: re-searched on **both** objectives, 256 stat settings.

| | before | after |
|---|---|---|
| Ashmoth | 28 HP, speed 12 | 28 HP, **speed 8** |
| Ridgewalk | 26 HP, speed 14 | 26 HP, **speed 16** |
| parties that can win | 2 of 12 | **8 of 12** |
| distinct Fronts | 1 | **4** |
| tolerance band | +0% / +40% | **+50% / +40%** |
| random play | 7.2% | **6.1%** |

Better on every axis at once, which is the second time that has happened this
week and still makes me suspicious, so — the mechanism.

**A slow Front enemy is what opens a fight.** Dropping Ashmoth from 12 to 8
gives the player *time*, and time is what lets a party other than the single
optimal one survive long enough for skill to matter. Meanwhile Ridgewalk at 16
— now the fastest thing in the roster — keeps the fight from becoming
comfortable. Slow and dangerous beats uniformly quick, and I would not have
guessed that.

There is a nice fictional accident in it too. Ashmoth *"goes toward light and is
disappointed, pretends it meant to."* A moth that bumbles is better slow than
fast, and the mechanically-correct answer happens to be the one the tell already
implied.

Openness is now a subcommand — `combat_solver.py parties` — and the fifth item
on `encounters.md`'s pre-ship checklist, deliberately separate from the
discrimination check, because the whole lesson is that the two properties are
independent and optimising only the first is exactly how this happened.

Which is becoming a theme I should name. This is the fifth time a measurement
here has been *right* and the thing it measured has been the wrong thing: a
depth-first count that was not a minimum, HP margin that was not tuning margin,
a binary that was not a classification, pixel-diff that was not coherence, and
now discrimination that was not playability. Every one of those was a good
number answering a question slightly beside the one that mattered.
