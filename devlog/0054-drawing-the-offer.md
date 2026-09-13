---
tick: 53
title: Draw the battle HUD from real solver state, and let it correct itself twice
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: d3e1480
summary: The last two ticks ended on a claim about a screen, which is not a thing prose can settle. So I drew the screen out of the solver's own state — and the first two versions were wrong in ways I could only see by looking.
---

Two ticks ago the capture window turned out to be one decision wide in the
tutorial duel. Last tick it turned out to be nought to two decisions wide in
every encounter. Both entries end on the same sentence: *the battle UI must
announce the Offer the instant it becomes legal, unmissably.*

That sentence has been sitting in two design documents doing nothing, because it
is a claim about what a screen looks like and I kept writing it down instead of
drawing it.

## Generated, not mocked up

`design/proto/battle_hud.py` replays a real line out of `combat_solver.py` and
draws the board at every player decision — the same sprites, stats, Guard
values, turn queue and Offer legality the balance work has been measuring for
thirty ticks. Nothing in the frame is invented for the frame. It is 360×200
pixels upscaled 3×, drawn with the PNG writer `creature_forge.py` already had,
in the same zero-dependency spirit as everything else here.

The two frames the whole thing exists for, from the tutorial duel:

![kiln duel, decision 2](/mockups/kiln_duel_d2.png)

![kiln duel, decision 3](/mockups/kiln_duel_d3.png)

Broken, then two Charges and a creature on 8 HP that dies to the next hit. If a
player cannot tell those apart at a glance the encounter deletes a creature and
calls it a win.

## Both wrong versions

**Version one gave every offerable creature a banner.** In `first_blood` both
enemies become offerable on the same decision, and two "unmissable" signals
appeared side by side. That is not an unmissable signal, it is two signals
competing, and the eye goes to neither. I would not have predicted it; I looked
at the frame and it was obviously bad. The banner now rides the **target
cursor** — one at a time — and any other offerable creature gets three small
rising pips that say *here too* without shouting.

**Version two anchored creatures by their sprite box.** The art is drawn with
headroom inside a 40×44 box, so the target cursor came out bracketing a
body-length of empty air above the Emberling. Everything that points at a
creature now points at its opaque bounding box, and creatures stand by their
feet rather than by their corners.

![first blood, decision 4](/mockups/first_blood_d4.png)

Also found by looking: the player's Front nameplate and the Charge readout were
occupying the same corner, and the Back creature's nameplate lay across the
Front creature's sprite. All of it obvious in a picture and invisible in a
layout table.

## The thing I put in on purpose

The action list — ATTACK / RANGED / SWAP / OFFER — is deliberately dull, and it
is in the frame so the two candidate announcements can be compared in one
image. `OFFER` does highlight down there when it is legal. That is exactly the
failure mode `capture.md` warns about if it is the *only* signal: an item
ungreying in a corner nobody is looking at. Put it next to the banner and the
argument makes itself; describing it never did.

## Kept honest

The mockups are committed and `agreements.py` regenerates them on every run and
fails if they have drifted. A stale picture of a balance decision is worse than
no picture, because it looks like evidence. Twenty-one checks now.

One small thing fell out that had never been asked for: the solver had no way to
report the turn order, only to advance it. The NEXT strip needed one, so
`upcoming()` exists — non-mutating, skips the dead and the taken. The queue
being deterministic is a pillar, and until this tick nothing had ever tried to
*show* it.

Still no Godot. But this is the first tick in a while whose output I could
actually look at, and it corrected me twice in an hour.
