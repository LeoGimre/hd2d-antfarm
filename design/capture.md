# Capture

`GAME.md` seeds capture as *"not a coin flip — engineer a board state that makes
a creature willing. The setup is the fun."* `design/combat.md` deferred it to M4
and guessed the odds would key off Guard and Broken state.
`design/creatures.md` then removed the need for odds entirely: Guard is
composure, Breaking it is the moment a creature's pretence fails and it is seen,
and a creature that was seen and not finished is what willingness is made of.

This document turns that into a rule, and — because the last three attempts at
balancing something in this project by reasoning about it all failed — tests it
in the same off-engine solver that settled `design/first_blood_balance.md`.

## No dice

`combat.md` already argued this for turn order: no randomness, no hidden checks,
*so when a plan goes right or wrong it is readable as a plan*. A probabilistic
capture would put the single most emotionally loaded moment in the game on a
roll, and undo that argument at the worst possible point. Capture is
deterministic. You either arranged the board or you did not.

## The rule

**Seen.** The first time a creature's Guard is broken in a battle, it is *Seen*,
for the rest of that battle. Being seen does not un-happen, so this is a state
and not a window.

**Offer** is an action a creature can take on its turn, in place of attacking.
It costs **two banked Charges**. It reaches either slot — it is not an attack.
It lands if and only if the target is Seen and still alive.

A creature that accepts leaves the battle and joins the party at the HP it had.
If it dies first, it is gone.

That is the whole rule, and everything that makes it hard is already in the game:

- **Breaking requires knowing the matchup.** Guard damage is the only thing type
  effectiveness touches, so a creature you have the wrong types for is a
  creature you cannot make Seen.
- **Two Charges means you must break twice**, so one lucky hit is not a capture.
  You have to have understood the fight, not landed a swing.
- **The target has to survive**, while it is still attacking you and while you
  are spending turns not killing it.
- **Charges are the resource that wins fights faster**, so a capture spends
  two bursts. See the correction below: in this small encounter that does *not*
  measurably lengthen the fight, and "capture should cost tempo" remains an
  unmet design goal rather than something the rule currently delivers.

## What the solver said

Searched against the re-paired proof battle from
`design/first_blood_balance.md` — player Rootshell/Tidalpup, enemy Emberling
(Front, speed 11) and Galewing (Back, speed 14). Every row below is reproducible
from the committed tool:

```
SEEN_MODE=window OFFER_COST=1 python3 design/proto/combat_solver.py capture
```

Decision counts are **minima**, found by iterative deepening. "Capture and win"
means capture the named creature *and* still finish the battle alive, which is
the question that actually matters.

| variant | Emberling | Galewing | random play captures |
|---|---|---|---|
| one-turn Broken window, 1 Charge | 2 (5 to also win) | **impossible** | — |
| one-turn Broken window, 2 Charges | **impossible** | **impossible** | — |
| Seen persists, 1 Charge | 2 (4 to also win) | 3 (4) | 16.9% / 12.8% |
| **Seen persists, 2 Charges** | 3 (5 to also win) | 3 (5) | **3.3% / 4.5%** |
| Seen persists, 3 Charges | 4 (6) | 4 (5) | 0.6% / 0.8% |

Two findings, neither of which I would have got by thinking about it.

**A one-turn window makes fast creatures uncapturable, not hard to capture.**
This was the first design, and it was elegant: break the creature, and while it
is Broken and losing a turn, make the offer. Against Galewing — speed 14 against
a party of 7 and 9 — no player turn ever lands inside the window. Not difficult.
Impossible, across 69,520 searched states. A collection game with an
uncollectable creature has a bug, not a challenge. Requiring two Charges on top
of the window makes *both* enemies uncapturable, because the second Charge
cannot be banked before the first window closes.

**A capture that pays for itself is not a plan.** With one Charge, the break
that makes a creature Seen banks exactly the Charge that then buys it. Random
play stumbles into a capture about one battle in six. Requiring two forces the
payment to come from somewhere other than the moment of the capture — which is
the "setup" the `GAME.md` seed asks for — and drops accidental captures to
around one in twenty-five. Three Charges drops it to one in a hundred and fifty,
which is past the point of being a plan and into being a chore.

### Correction: capture does not currently cost tempo

An earlier draft of this document claimed the proof battle takes 6 player
decisions to win and 7 to capture-and-win, and concluded that the cost of
collecting was visible in the count. **Both numbers were wrong.** They came from
a depth-first search that returns *a* line rather than the shortest one, so its
length depended on the order the search happened to list moves in — which is not
a fact about the game. Measured properly by iterative deepening: the shortest
win is **5** decisions, with or without capture available, and capture-and-win
is also 5.

So the tempo cost is not there. Two Charges is still the right cost — the
self-financing argument and the accident rate are the real evidence, and both
survive — but the claim that collecting slows you down does not, in this
encounter. It may reappear in longer fights where Charges are scarcer relative
to the number of turns. Until something measures that, it is an aspiration.

The lesson generalises past capture: **a decision count from a depth-first
search is not a minimum**, and quoting one as though it were is how a design
argument ends up resting on the order of a `for` loop.

## What capture actually costs: the window

`tutorial.md` found that in a duel the turn you can finally take a creature is
the turn your next attack kills it. The obvious next question is whether that is
a fact about duels or a fact about this game. It is a fact about this game.

```
python3 design/proto/combat_solver.py window --encounter first_blood
```

| encounter | target | win | capture | cap+win | HP at the Offer | window | shut by |
|---|---|---|---|---|---|---|---|
| kiln_duel | Emberling | 3 | 3 | 3 | 8 | **0** | the creature dies |
| first_blood | Emberling | 5 | 3 | 5 | 20 | **2** | the battle ends |
| first_blood | Galewing | 5 | 3 | 5 | 18 | **0** | the battle ends |
| the_ridge | Ashmoth | 5 | 3 | 5 | 20 | **2** | the battle ends |
| the_ridge | Ridgewalk | 5 | 3 | 5 | 20 | **2** | the battle ends |

"Window" is how many further decisions of *correct* play the Offer survives
after it first becomes legal. Zero means the next correct decision takes the
creature off the table.

Two things fall out.

**The tempo correction above is stronger than it was stated.** `cap+win` equals
`win` in every encounter measured, not just the proof battle. Capture has never
cost a decision anywhere. The aspiration at the end of that section — that a
cost might appear in longer fights — is still unmeasured, but it is now
unmeasured across three encounters instead of one.

**What capture costs is the noticing.** The Charge economy pays out its second
Charge at almost exactly the moment the fight resolves, because the same hits
that bank Charges are the hits that end the battle. So the Offer is never a
comfortable "now decide" beat; it is a thing that opens and shuts inside a
couple of decisions, and in the fights with the least slack, inside one.

That is a good design and a dangerous one, and which it is depends entirely on
presentation:

> **The battle UI must announce the Offer the moment it becomes legal, and make
> it impossible to miss.** Not a greyed-out button that ungreys — a state change
> the player cannot fail to see. A window this narrow is a lesson if the game
> tells you it is open and a bug if it does not.

This is the same requirement `tutorial.md` derived from the duel. It is not a
tutorial requirement. It is the requirement, in every fight.

**Why "the battle ends" and not "the creature dies".** In a two-a-side fight the
window usually shuts because the player wins, not because they killed the
creature they wanted. That is worse, not better: dying is legible feedback and
winning is not. A player who wins cleanly and walks away has no way to know
anything was on offer.

## What this means for encounters

Whether a given creature is capturable is a property of **the encounter and the
party**, not of the creature. Under the one-turn-window design that was a fatal
flaw; under Seen-persists it is mild, but it does not vanish — a party with the
wrong types cannot break a creature, and cannot capture it.

That responsibility belongs to whoever authors an encounter, and
`design/encounters.md` is where it should be written down when encounters become
data: **every creature must be capturable by a party the player can plausibly
have when they first meet it.** It is an authoring constraint, not a rule, and
it is the kind of thing that is obvious while designing one encounter and
invisible across forty.

## Deliberately out of scope

- **Party management** — where a captured creature goes, what happens when the
  party is full, swapping between battles. Its own M4 box.
- **Progression.** A captured creature joins at the HP it had, and nothing else
  about it changes. Levels do not exist yet and this design does not need them.
- **Capture outside battle.** There is no mechanism and no reason to invent one;
  the entire point is that the board state is the puzzle.
- **A refusal.** There is no "the offer failed" outcome, because there is no
  randomness for it to come from. An offer you cannot make is greyed out; an
  offer you can make lands. If a creature should be harder to take, that is a
  Guard number or an encounter, not a die.
