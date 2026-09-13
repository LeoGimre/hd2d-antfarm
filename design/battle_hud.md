# The battle HUD, drawn from real state

`capture.md` ends on a requirement rather than a number: the window in which a
creature can be taken rather than killed is nought to two decisions wide in
every encounter, so **the battle UI must announce the Offer the instant it
becomes legal**, and must do it in a way the player cannot miss.

That is a claim about what a screen looks like, and it cannot be settled in
prose. So this document is mostly pictures, and the pictures are generated:

```
python3 design/proto/battle_hud.py            # every encounter with a capture line
python3 design/proto/battle_hud.py --encounter kiln_duel
```

`battle_hud.py` replays a real line out of `combat_solver.py` and draws the
board at every player decision, using the same sprites, stats, Guard values,
turn queue and Offer legality the balance work uses. Nothing in it is invented
for the picture. `farm/agreements.py` regenerates the frames and fails if the
committed ones differ, because a stale picture of a balance decision is worse
than no picture: it looks like evidence.

## The decisive pair

The whole argument is two frames from the tutorial duel.

**Decision 2 — the Emberling is Broken, and there is nothing to decide yet.**

![kiln duel, decision 2](/mockups/kiln_duel_d2.png)

**Decision 3 — two Charges, and a creature on 8 HP that dies to the next hit.**

![kiln duel, decision 3](/mockups/kiln_duel_d3.png)

The difference between those two frames is the entire tutorial. If a player
cannot tell them apart at a glance, the encounter deletes a creature and calls
it a win.

## What the board carries

| element | why it is on screen |
|---|---|
| **NEXT** strip | The queue is deterministic (`combat.md`). A player who cannot read the order is playing a random game with extra steps. Six deep; the current actor is boxed. |
| **CHARGE** pips | The Charge economy is the thing the fight is about, and it is the Offer's price. Reads `ENOUGH TO OFFER` the moment it can pay. |
| nameplate: HP bar | Ordinary. Turns red under 35%. |
| nameplate: Guard pips | `creatures.md` says Guard is composure, not armour. Pips rather than a bar, because it is a small integer and the player counts it. |
| **BROKEN** tag + orange tint | Being Broken is a state with tactical consequences for exactly one turn, so it is loud and it goes away. |
| target cursor | Brackets, not a box: `creature_sprites.md` says only the silhouette reads, and a box eats it. |
| **OFFER** banner | The one thing this file exists for. See below. |
| action list | Deliberately dull. See below. |

## The Offer announcement

Three rules came out of drawing it, and two of them came out of drawing it
*wrong* first.

**1. It is attached to the creature, not to the menu.** The subject of the
decision is a creature, not a verb. The banner sits above the target with a tick
running down to it, and it is the brightest object on the screen.

**2. There is only ever one of them.** The first pass drew a banner over every
offerable enemy, and in `first_blood` two appeared at once. Two unmissable
signals are not an unmissable signal; they are a competition. So the banner
rides the **target cursor**, and any other offerable creature gets a quiet
marker — three rising pips, no words — that says *here too* without shouting.

![first blood, decision 4](/mockups/first_blood_d4.png)

**3. The action list is not the announcement.** `OFFER` does highlight in the
menu when it is legal, and that is exactly the failure mode `capture.md` warns
about if it is the *only* signal: a greyed item ungreying in a corner the player
is not looking at. It is in the mockup so the two can be compared in one frame.
Look at the menu in the two duel frames above and then at the banner. Only one
of them changes the picture.

## What drawing it changed

- **Anchor creatures by their feet, not by the sprite box.** The art is drawn
  with headroom inside a 40×44 box, so a cursor drawn around the box floats a
  body-length above the creature. Everything that points at a creature now
  points at its opaque bounding box.
- **Nameplates go under the feet and get clamped to the canvas.** The first
  layout put the Back creature's plate across the Front creature's sprite.
  Legible in isolation, a mess on the board.
- **Back-row creatures are the same size, tinted toward the sky.** Billboards in
  a diorama do not shrink much over four metres, so depth is carried by height,
  air, and haze rather than scale. This matches what `hd2d_look.md` asks the
  battle camera to do and does not require the camera to do it.
- **The status cluster is top-left, not bottom-left.** Bottom-left is where the
  player's Front creature's nameplate lives, and the two collided.

## Deliberately not drawn

- **Empty slot markers.** `build_battle.gd` draws all four slot markers
  "regardless of occupancy". In the tutorial duel it should not: `tutorial.md`'s
  whole reason for a side of one is that act one must not explain Front and Back
  before it has explained attacking. **An encounter marked `tutorial` hides the
  empty slots.** That is a small loader rule, and this is where it is written
  down.
- **Damage numbers, animation, camera moves, menus for anything but the four
  actions.** None of them bear on the question this file exists to answer.
- **Colour.** The palette here is the Kiln Yards' key colour warmed a little so
  the board reads as a place rather than a grey UI study. It is not a decision;
  `hd2d_look.md` owns that and this file should not fight it.
