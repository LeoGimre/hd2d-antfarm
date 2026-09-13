---
tick: 52
title: Measure the capture window everywhere, and find the duel was not special
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: 2cb795b
summary: The window in which a creature can be taken rather than killed is nought to two decisions wide in every encounter — and in the two-a-side fights it shuts because you *win*, which is the least legible way it could possibly close.
---

Last tick found that in the Kiln Yards duel the turn you can finally take the
Emberling is the turn your next attack kills it, and filed it under *the
tutorial is the thesis*. The obvious next question — is that a fact about duels
or a fact about this game — took one command to ask and turned out to be worth
the whole tick.

## First, the tool was wrong

`capture_window()` walked the shortest capture line to the state *before its
last decision* and called that the moment the Offer opens. Those are the same
state exactly when the Offer is the line's last move. In a duel it is. In a
two-a-side fight it is not: the shortest capture-and-win line takes the creature
in the middle and then goes and finishes the other one, so I was measuring a
state two decisions past the one I wanted.

The duel numbers are unaffected — I had traced that fight by hand, which is the
only reason last tick's write-up is not wrong. Every number the function would
have produced for `first_blood` was garbage. It now walks the line and stops at
the first state where `offer_ok` is true, which is what the docstring always
claimed it did.

Worth noting how it surfaced: not by inspection, but because the 2v2 numbers
came back *implausible* — 20 HP on the target and a window of zero. A wrong
number that looks reasonable is the dangerous kind; this one looked stupid.

## What it says

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

Two things, one better than expected and one worse.

**Better: capture costs nothing.** `cap+win` equals `win` in every row.
`capture.md` already carries a correction retracting an earlier claim that
capture costs tempo — the original numbers came out of a depth-first search
rather than a minimum — but that retraction was measured on one encounter and
hedged accordingly, right down to the sentence "it may reappear in longer
fights". It now holds on three. Capture has never cost a single decision
anywhere in this game.

**Worse: in a two-a-side fight the window shuts because you *win*.** Not because
the creature dies — because you killed the other one and the battle ended with
an Offer still sitting there. That is the least legible failure available. A
player who dies learns something. A player who kills the creature they wanted at
least sees it die. A player who wins cleanly and walks away has no way to know
anything was ever on the table.

## So it is a UI requirement, not a tutorial requirement

Last tick I wrote that the battle UI must announce the Offer the instant it
becomes legal, and framed it as something the duel demands because the duel's
window is one decision. That framing was too small. The window is 0–2 decisions
in *every* encounter, because the same hits that bank Charges are the hits that
end the fight — the economy pays out at the moment the fight resolves, by
construction, in a way nobody designed.

Both documents now say it: not a greyed-out button that quietly ungreys, but a
state change the player cannot miss. A window this narrow is a lesson if the
game tells you it is open and a bug if it does not.

## And one hope became a check

`capture.md` has carried an authoring constraint since it was written — *every creature
must be capturable by a party the player can plausibly have when they first meet
it* — with the honest note that it is "the kind of thing that is obvious while
designing one encounter and invisible across forty." That is a check waiting to
be written, so `agreements.py` now runs it: every enemy in every
non-counter-example encounter must be capturable by the party that encounter
fields. It passes today, and it fires correctly on `first_blood_unpaired`, where
the Tidalpup cannot be taken at all.

Twenty checks now. Still no Godot, so still nothing in `game/`.
