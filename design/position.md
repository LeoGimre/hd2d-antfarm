# Which positional rules are actually holding the fight up

`design/combat.md` specifies three positional rules and argues for them at
different lengths:

1. **Melee can only target Front** (or Back once Front has fallen). Two
   sentences.
2. **Ranged hits Back for 25% less.** Two sentences — *"Back is safer, not
   safe."*
3. **Front deals a flat +2 damage with any move.** The longest justification in
   the section: *"front-line pressure is rewarded, so the choice to advance or
   protect a unit is a real trade, not a strictly-better move."*

`design/swap.md` found last tick that Front is where every melee attack lands
from both enemies, which is a fact about rule 1 that nobody had stated. That
raised the obvious follow-up: of these three, which are doing the work?

Each was removed in turn and the battery re-run against the re-paired proof
battle. The three assertions that define the encounter are: naive play must
lose, correct play must win, and correct play that hoards its Charges must lose
(which is what makes the Break/Charge economy load-bearing rather than
ornamental).

| configuration | naive | correct | hoards Charges | random | verdict |
|---|---|---|---|---|---|
| as specified | loses | **wins** | loses | 13.0% | discriminates |
| no Front bonus | loses | **wins** | loses | 10.3% | **discriminates** |
| no Back penalty | loses | **wins** | *wins* | 12.4% | **broken** |
| melee may reach Back | loses | *loses* | loses | 0.7% | **broken** |

```
FRONT_BONUS=0 python3 design/proto/combat_solver.py lines
BACK_MULT=1.0 python3 design/proto/combat_solver.py lines
MELEE_REACH=any python3 design/proto/combat_solver.py lines
```

## The ordering is the reverse of the emphasis

**Melee-locked-to-Front is structural.** Remove it and the fight is not merely
unbalanced, it is unwinnable: correct play loses and random play falls to 0.7%.
With both enemies able to reach either slot, and the enemy AI already preferring
Back with its ranged attacks, Back becomes the *most* dangerous place to stand
and there is nowhere left to put anything. This is the rule the whole board rests
on and it got two sentences.

**The Back penalty is what keeps the Charge economy honest.** Remove it and
correct targeting alone wins without ever spending a Charge — `typed_hoard`
flips from a loss to a win. The 25% discount is not primarily a safety
mechanism, whatever "Back is safer, not safe" implies; it is the thing that
stops sniping the enemy Back slot from being sufficient on its own, and
therefore the thing that forces a player to break, bank and burst.

**The Front bonus is not load-bearing.** Setting it to zero changes none of the
three outcomes. It moves random play from 13.0% to 10.3%, so it does something —
it slightly rewards whoever is standing in Front, on both sides — but the "real
trade, not a strictly-better move" argument it was given is not what makes this
encounter work.

That last one deserves care rather than a deletion. *Not load-bearing for three
binary outcomes in one encounter* is a much narrower claim than *useless*. The
bonus may well matter for feel, for other board shapes, or for encounters that do
not exist yet. What the measurement says is where the design's weight actually
sits, not which rules to throw away.

## The actionable part

`design/progression.md` established that Guard must never grow, because it is a
discrete gate rather than a stat. This adds two more entries to the same list of
things a balance pass may not touch casually:

- **The melee reach rule and the Back multiplier are structural.** Changing
  either invalidates every balance result in `first_blood_balance.md`,
  `capture.md` and `progression.md`, because all of them were measured on top of
  these two. Any change requires re-running the full battery, and probably
  re-solving the encounter.
- **The Front bonus is a free knob.** A future tuning pass can move it without
  re-deriving anything, which makes it the right dial to reach for first.

That distinction did not exist before this tick. Every constant in
`combat_resolver.gd` looked equally adjustable, and two of them are not.

## Extended to every constant, and one correction

The three-rule audit above was done by hand. It is now a subcommand, so the
answer stays current instead of being a snapshot:

```
python3 design/proto/combat_solver.py constants
```

It sets each constant to a range of values, re-runs the three assertions, and
classifies the result. Two things came out that the hand audit missed.

**Correction: the Front bonus is bounded, not free.** The section above tested
it at zero, found nothing changed, and called it a free knob. Tested upward it
breaks: at +4 the encounter stops discriminating. So it is safe anywhere in
**0–2** and not above, which is a materially different instruction to a tuning
pass than "move it freely."

**Two rules are decorative.** Neither of these changes any outcome:

- **`BROKEN_TAKES_MORE_DAMAGE`** works at every value from 1.0 to 2.0 — including
  1.0, which removes the bonus entirely. `combat.md` sells Broken as two things:
  *"it loses its next turn outright and takes 50% more damage."* Measured, only
  the first half is doing anything. The value of Breaking a creature is the turn
  you take from it.
- **`RESIST_HEAL`** works at 0. The "small heal-back in spite" can be deleted
  without affecting the encounter — though it must not *grow*: at 4 the fight
  breaks.

Neither should be deleted on this evidence alone. Both are cheap, both carry
fiction that `creatures.md` leans on, and "changes no outcome in one encounter"
is not "does nothing." But a tuning pass should know that reaching for them will
not move the fight.

The full picture, as of this tick:

| | constants |
|---|---|
| **fixed** — one working value | `MELEE_REACH` (Front only) |
| **bounded** — safe inside a range | `FRONT_DAMAGE_BONUS` 0–2 · `BACK_TARGET_MULTIPLIER` ≤0.75 · `CHARGE_MULTIPLIER` ≥1.5 · `RESIST_HEAL` ≤2 · `GUARD_REGEN` ≥1 |
| **free** — every tested value works | `BROKEN_TAKES_MORE_DAMAGE` · `SWAP_MODE` |

`CHARGE_MULTIPLIER ≥ 1.5` has a readable cause: below it, spending a Charge is
not worth the declaration, correct play collapses into hoarding, and hoarding
already loses. `GUARD_REGEN ≥ 1` likewise — with no regeneration nothing ever
recovers its composure and the fight stops being about pressure at all.

**Caveat:** one encounter, the off-engine model, `--self-check` passing. The
melee-reach result is so large it is unlikely to be an artifact of these
numbers. The Front-bonus result is the one most likely to change on a different
board, and should be re-measured whenever a second encounter exists.
