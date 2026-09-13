# The Ridge — a second encounter, and what it proves

Almost every balance document here ends with the same caveat: *one encounter,
off-engine model*. `first_blood_balance.md`'s diagonal requirement,
`position.md`'s constant classification, `progression.md`'s tolerance band and
the retune proposed in `first_blood_balance.md` were all measured on a single
fight built from the same four creatures.

This is the second one. It exists to remove that caveat, and it did — twice in
the direction of confirming and once by finding a constraint nobody had stated.

```
python3 design/proto/combat_solver.py lines --encounter ridge
```

## The encounter

Set on The Ridge, from `design/regions.md`. The player fields Rootshell (Root,
Front) and Tidalpup (Tide, Back) — the same pair as the proof battle, so the
enemy side is the only thing that varies.

| | creature | type | slot | HP | speed | Guard |
|---|---|---|---|---|---|---|
| enemy Front | **Ashmoth** | Ember | front | 28 | 12 | 2 |
| enemy Back | **Ridgewalk** | Gale | back | 26 | 14 | 2 |

Stats live in `design/proto/proposed_creatures.json` rather than `game/data`,
because they have not been through an engine. They were **searched, not
invented**: 180 combinations of the two creatures' HP and speed, scored on
whether the encounter discriminates skill and how wide its tolerance band is.

At the shipped constants it behaves like this:

| line | result |
|---|---|
| naive | loses, enemy on 26 HP |
| attack whoever resists you | loses, enemy on 43 |
| always snipe the Back slot | loses, enemy on 40 |
| **correct targeting, spending Charges** | **wins**, 24 HP left |
| correct targeting, hoarding Charges | **loses by 2 HP** |
| random play | 7.1% |

That fifth row is the encounter's best feature. Playing the matchup perfectly and
declining to spend what you bank loses by two hit points.

## Finding 1 — the diagonal requirement is structural

`first_blood_balance.md` found that the original fight only works when each
player creature's correct target stands *diagonally opposite* it, so reaching it
has to go through the Front/Back rule. That was one arrangement of one set of
four creatures, and it could easily have been a coincidence of those numbers.

Both arrangements of this encounter were searched across the same 180 stat
combinations:

| enemy arrangement | settings that discriminate |
|---|---|
| **straight** — Gale Front, Ember Back | **0 of 180** |
| **diagonal** — Ember Front, Gale Back | **7 of 180** |

Zero. Not "harder to balance" — no stat assignment in the searched space makes
the straight arrangement into a fight that rewards skill. Different creatures,
different stats, same requirement. It is structural.

## Finding 2 — a one-type enemy line cannot make a pillar-2 encounter

The Ridge is a Gale region, so the obvious encounter is two Gale creatures. That
was the first thing tried and it failed completely: **0 of 192 stat settings**
produced a fight that discriminates skill, including settings where the enemies
were far weaker than the player.

The mechanism is exact, and it is not about difficulty. Tidalpup is Tide; Gale
*resists* Tide. So every attack Tidalpup makes against a Gale creature does zero
Guard damage — it can never break anything, never bank a Charge, and never
participate in the economy at all. The whole fight then rests on Rootshell,
which means one of two things: either the enemies are weak enough for Rootshell
to win alone, in which case hoarding Charges also wins and the third assertion
fails; or they are not, and correct play loses. There is no gap between.

**So an encounter needs enemies of at least two types** — specifically, enough
type spread that *both* player creatures can break something. This is a real
constraint on `design/regions.md`, which derives a region's creatures from what
the place does when watched and therefore tends toward one type per region. It
is not a contradiction: a region can be predominantly Gale and still field a
resident alongside something that wandered up from the kilns, which is what this
encounter does. But it has to be *deliberate*, and it belongs on
`encounters.md`'s checklist:

> **Every enemy line must give each of the player's creatures something it can
> break.** A creature whose attacks are resisted by everything on the board is
> not merely weak in that fight — it is absent from the Charge economy, and the
> fight cannot discriminate skill.

## Finding 3 — the retune generalises, and makes encounters easier to balance

`first_blood_balance.md` proposes `CHARGE_MULTIPLIER` 1.5 → 2.0 and
`BROKEN_TAKES_MORE_DAMAGE` 1.5 → 1.0, measured on the original fight. Applied
here, on an encounter it was not derived from:

| | shipped | retuned |
|---|---|---|
| stat settings that discriminate | 7 of 180 | **12 of 180** |
| best tolerance band | +0% / +75% | **+75% / +75%** |
| random play at that setting | 15.6% | **6.3%** |

Better on all three, and the first row is the one that matters most for the
project rather than for this fight: the retune nearly doubles the space of
workable stat assignments. Encounters become *easier to balance*, which is
exactly what a roster heading for sixty creatures needs.

## What is still caveated

Two encounters is not many, and both use the same player pair. The next thing
worth measuring is a fight where the *player's* side varies — which needs party
management, and therefore capture, and therefore an engine.

The Front damage bonus question from `position.md` is still open and now has a
second data point available; it was not resolved here because resolving it means
deciding whether to delete a rule `combat.md` argues for, and that deserves its
own tick rather than a paragraph in someone else's.
