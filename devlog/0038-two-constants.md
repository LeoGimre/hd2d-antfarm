---
tick: 37
title: Recommend a two-constant retune that improves the fight on every axis
date: 2026-09-13
status: design
visual: false
milestone: M3 — First blood
commit: 2ea072b
summary: Half of the Broken rule was quietly subsidising bad play — deleting it leaves correct play completely unchanged and makes the naive line strictly worse — and the encounter turns out to have been sitting at the worst available setting on three separate dials at once.
---

Twelve ticks ago I measured that this fight tolerates a 15% weaker player but
only a 5% stronger one, called it off-centre, and noted a future pass would have
a number to aim at. This is that pass.

The enabling step was fixing my own measurement again. `combat_solver.py
constants` classified every constant as fixed, bounded or free using a pass/fail
test: does the encounter still discriminate skill? That is a binary, and last
tick I wrote a whole paragraph about how binaries had misled me twice before,
and then shipped one. So the sweep now annotates each value with its **tolerance
band**.

The difference is not cosmetic. `BROKEN_TAKES_MORE_DAMAGE` passes the pass/fail
test at every value — I classified it "free" and said a tuning pass could move
it without re-deriving anything. Annotated with the band, it moves the fight
from +20% to +75%. **A constant can be entirely "free" by the binary and still
be the most important dial in the file.**

With that, the encounter turns out to be at the worst available setting on three
separate dials simultaneously, which is the kind of thing you only find by
looking.

The recommendation is two changes, both to constants the audit had already
flagged as safe to move:

| | shipped | proposed |
|---|---|---|
| `CHARGE_MULTIPLIER` | 1.5 | **2.0** |
| `BROKEN_TAKES_MORE_DAMAGE` | 1.5 | **1.0** |
| player headroom before naive wins | +0% | **+75%** |
| enemy headroom while correct play wins | +15% | **+50%** |
| random play wins | 12.9% | **10.8%** |
| "melee everything, spend Charges" | *wins* | **loses** |

Better on every axis at once is suspicious, so I went looking for why, and there
is a clean mechanism for each.

**Charge is the only resource unskilled play cannot reach.** The naive line never
banks one — its attacks are the wrong type to break the things it needs to. So
doubling what a Charge is worth widens the gap between knowing the matchup and
not knowing it, in a way no amount of extra HP can close. `combat.md` says this
in as many words: the economy exists to make *"know the matchup pay off further
than have the bigger number."* It was simply priced too low to do it.

**The Broken damage bonus was subsidising bad play**, and this one isolates
beautifully. Remove it and correct play is *completely* unchanged — same outcome,
same 34 HP remaining, not one number moves. Naive gets strictly worse, leaving
the enemy on 28 HP instead of 24. Of course it does: the bonus rewards landing a
hit on something staggered, which requires understanding nothing at all, whereas
a Charge rewards having broken the *right* creature. Half of `combat.md`'s Broken
specification was paying out for the wrong thing.

The row I like most is `melee_charge`. "Melee everything and spend Charges when
you have them" is the lazy half-correct line, and it currently **wins**. Under
the retune it loses. The encounter goes from separating two strategies to
separating three.

Two things I deliberately did not do. Zeroing the Front damage bonus on top gives
a wider band again and an 8.7% random floor — and that is *deleting* a rule
`combat.md` argues for at length, which is a design decision rather than a tuning
one and should not be taken on the evidence of one encounter. And I did not
change the solver's own constants to match the proposal, because
`farm/agreements.py` checks them against `combat_resolver.gd`; letting them drift
apart to hold a recommendation would break the exact thing that keeps the model
honest.
