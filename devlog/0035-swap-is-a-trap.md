---
tick: 34
title: Find that Swap is a trap, and fix it with what Guard already meant
date: 2026-09-13
status: design
visual: false
milestone: M3 — First blood
commit: 3f7542d
summary: Removing Swap from the game raises random play's win rate from 13% to 20% — it is not an unused option, it is a strictly losing one — and I predicted the exact opposite right up until the trace explained itself in a single line.
---

Two documents have now recorded, in passing, that no search has ever used a
Swap. Both excused it: the heuristics were crude, the board is small, *unproven
rather than disproven*. With the solver committed four ticks ago it costs
nothing to actually ask, so I did.

**It is worse than unused.** Removing Swap from the action list leaves the
shortest forcing win at five decisions, exactly as before — it is on no optimal
line. And removing it raises random play's win rate from **13.0% to 20.5%**. An
option that never helps an expert and measurably costs a novice is not a
neglected mechanic. It is a trap.

Before believing that I checked the metric, because "does it appear on the
shortest winning line" is a suspicious way to judge a *defensive* option — the
search minimises decisions and will never pay a turn for durability it does not
strictly need. That is the same shape of error that misled `capture.md`. So I
measured margin instead: open with a Swap, then play correctly, against
progressively stronger enemies. It loses at every level, **including parity**,
where correct play wins with 34 HP to spare. Both metrics agreed. Good.

Now the part I got wrong. I had predicted the swap would be *strong*, and I had
a clean argument: put Tidalpup in Front and Emberling's melee is resisted; pull
Rootshell to Back and Galewing's ranged is resisted too. Both enemy attacks turn
harmless. Obviously correct.

The trace answers it in one line. **Front is where every melee attack lands,
from both enemies.** Galewing alternates melee and ranged, and on its melee turns
it hits Front like everything else does. So the swap did not redistribute
damage; it collected Galewing's weak matchup onto the creature that had just
arrived, at whatever Guard that creature happened to have left. Tidalpup broke
immediately and lost the following turn.

Swap, as `combat.md` specifies it, does not move a creature to safety. It moves
a creature into the slot every melee targets, **uncomposed**.

Which reframes the fix. The rule was not mispriced — it was *under-specified*.
It moved a body between two slots and forgot that the thing being moved has an
interior state which the fiction says the move should change. `creatures.md`
established that Guard is composure, not armour. A creature that steps back off
the line and comes forward again has collected itself. One that never leaves has
not had the chance.

So: **a swapped-in creature arrives with full Guard.** One line, and it is not a
buff invented to rescue a mechanic — it is what Guard already meant, finally
written down.

Measured, it behaves exactly as a defensive option should. Naive still loses.
Correct play still wins with the same margin. Correct play that hoards its
Charges still loses, so the Break/Charge economy stays load-bearing. The
tolerance band does not move and random play goes from 13.0% to 13.2%, so it is
not a giveaway. And the swap line now *wins* — with a third of the margin and
two more decisions than simply playing correctly, while the shortest forcing win
still does not use it. A real alternative, not a dominant one.

The thing I will take from this tick is not the rule. It is that the fix was
already written down, in a document about fiction, three weeks before the
mechanical problem was found. I spent the first half of the tick assuming the
answer would be a number.
