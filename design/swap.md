# Swap is a trap, and the fix is what Guard already means

`design/combat.md` prices Swap at a full action: spend a turn to trade a
creature between Front and Back. The document is explicit that this is the size
of decision the system exists to create — *"pulling a cracked or low-HP creature
to safety costs the tempo of an entire turn."*

Two documents have since recorded, in passing, that no search has ever used one.
`first_blood_balance.md` filed it as "Swap is unproven, not disproven," blaming
the crude heuristics that had been tried. With the solver committed, it is
cheap to actually find out.

## It is worse than unused

**Removing Swap does not change the optimum.** The shortest forcing win in the
re-paired proof battle is five player decisions with Swap available and five
without. It is on no optimal line.

**Removing Swap makes random play better.** 20.5% of random battles are won with
the action gone, against 13.0% with it available. That is the definition of a
trap: an option that never helps an expert and actively costs a novice, because
it dilutes the choice set with a strictly losing move.

## Checking the metric before believing it

"Is it on the shortest winning line" is a suspicious question to judge a
*defensive* option by. The search minimises decisions, so it will never pay a
turn for durability it does not strictly need — exactly the way a depth-first
count misled `capture.md`. So the second measurement asked about margin instead:
a policy that opens with a Swap and then plays correctly, against progressively
stronger enemies.

| enemy HP | correct play | open with a Swap |
|---|---|---|
| ×1.00 | **wins**, 34 HP left | loses |
| ×1.10 | **wins**, 34 HP left | loses |
| ×1.15 | **wins**, 29 HP left | loses |
| ×1.20 | loses | loses |

It does not buy margin either. It loses at parity, where correct play wins
comfortably. Both metrics agree, which is the answer I did not want and the one
that mattered.

## Why — and I predicted the opposite

Before running it I reasoned the swap should be *good*: putting Tidalpup in
Front means Emberling's melee is resisted, and pulling Rootshell to Back means
Galewing's ranged is resisted too. Both enemy attacks turn harmless. Obviously
correct.

It is wrong, and the trace says why in one line. **Front is where every melee
attack lands, from both enemies.** Galewing alternates melee and ranged, and on
its melee turns it hits Front like anything else does. So moving Tidalpup
forward did not redistribute damage — it collected Galewing's melee, which hits
Tide for weak, onto the creature that had just arrived, at whatever Guard it
happened to have. It broke immediately and lost the turn after that.

Swap, as specified, does not move a creature *to safety*. It moves a creature
into the slot every melee attack targets, uncomposed.

## The fix: a swapped-in creature arrives composed

> **Swapping restores the swapped-in creature's Guard to full.**

This is not a buff invented to rescue a mechanic. It is what Guard already
means. `design/creatures.md` established that Guard is composure and Breaking it
is a creature's pretence failing — so a creature that steps back off the line
and comes forward again has *collected itself*, and one that never leaves has
not had the chance. Under that reading the original rule was not mispriced, it
was **under-specified**: it moved a body between slots and forgot that the thing
being moved has an interior state the fiction says the move should change.

It also makes the tempo cost legible. A turn buys a full Guard pool on the
creature that most needs one. That is a trade a player can evaluate, which
"a turn buys a change of position" never was.

### What it does to the fight

Everything measured with `SWAP_MODE=guard`:

| line | result |
|---|---|
| naive | still loses |
| correct targeting | still wins, 34 HP, 6 decisions |
| correct targeting hoarding its Charges | still loses — Charge stays load-bearing |
| **open with a Swap, then correct targeting** | **wins**, 8 HP, 8 decisions |
| random play | 13.2%, against 13.0% before |
| shortest forcing win | still 5 decisions, still does not use Swap |
| stat-tolerance band | unchanged |

That is the shape a defensive option should have. It **works**, and it wins with
a third of the margin and two more decisions than simply playing correctly — so
it is a real alternative rather than a dominant one, and the fastest line still
does not need it. Random play barely moves, so it is not a giveaway either.

## Considered and rejected

- **A free Swap** — the creature swaps and still acts. Not implemented and so
  not measured, which is why it is listed here rather than compared above. It
  would almost certainly work, and it deletes the decision: a positioning change
  that costs nothing is one you always take when it is even slightly good.
  `combat.md` is right that the cost is the point.
- **Cheapening Swap some other way** — a half-turn, a discount. Every version
  requires inventing a new unit of time the turn queue does not have, to fix a
  problem that turned out not to be about price at all.
- **Removing Swap entirely.** Honest, and simpler, and it was the leading option
  after the first measurement. Rejected because `combat.md` builds the entire
  Front/Back trade around the existence of a way to change your mind, and because
  the fix that works costs one line and was already implied by the fiction. A
  mechanic that is wrong is worth one attempt at being right.

**Caveat:** measured on one encounter with the off-engine model, which
`--self-check` keeps honest but which is still a model. The trap finding is
robust — two independent metrics, and a mechanical explanation that does not
depend on these particular numbers. The reprice should be re-measured on the
second encounter that exists.
