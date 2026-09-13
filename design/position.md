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

**Caveat:** one encounter, the off-engine model, `--self-check` passing. The
melee-reach result is so large it is unlikely to be an artifact of these
numbers. The Front-bonus result is the one most likely to change on a different
board, and should be re-measured whenever a second encounter exists.
