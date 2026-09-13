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
- **Charges are the resource that wins fights faster.** Every capture is
  literally paid for with the tempo that would have ended the battle sooner.

## What the solver said

Searched exhaustively against the re-paired proof battle from
`design/first_blood_balance.md` — player Rootshell/Tidalpup, enemy Emberling
(Front, speed 11) and Galewing (Back, speed 14). "Capture" means capture the
named creature; "capture and win" means capture it *and* still finish the battle
alive, which is the question that actually matters.

| variant | Emberling | Galewing | random play stumbles in |
|---|---|---|---|
| one-turn Broken window, 1 Charge | **2 decisions** | **impossible** | 5.8% / 0.0% |
| one-turn Broken window, 2 Charges | impossible | impossible | 0.0% / 0.0% |
| Seen persists, 1 Charge | **2 decisions** | 4 decisions | 14.3% / 9.3% |
| **Seen persists, 2 Charges** | 4 (7 to also win) | 4 (5 to also win) | **3.7% / 3.0%** |

Three findings, none of which I would have got by thinking about it.

**A one-turn window makes fast creatures uncapturable, not hard to capture.**
This was my first design, and it was elegant: break the creature, and while it
is Broken and losing a turn, make the offer. Against Galewing — speed 14 against
a party of 7 and 9 — no player turn ever lands inside the window. Not difficult.
Impossible, across 8151 searched states. A collection game with an uncollectable
creature has a bug, not a challenge.

**A capture that pays for itself is not a plan.** With one Charge, the break that
makes a creature Seen banks exactly the Charge that then buys it. Capture
collapsed to two decisions — hit it once, take it — before the enemy had
meaningfully acted. Requiring two is what forces the Charge to come from
somewhere other than the moment of the capture, which is the "setup" the
`GAME.md` seed is asking for, and it drops accidental captures from 14% to under
4%.

**Capture costs tempo, measurably.** Winning the proof battle takes 6 player
decisions. Capturing Emberling *and* winning takes 7. The price is visible in
the numbers, which is what a resource cost should be.

**Caveat, same as always:** this is the off-engine model, validated against a
committed engine result but still a model. Re-confirm in-engine before ticking
anything.

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
