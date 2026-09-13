# The Kiln Yards duel — the tutorial is the thesis

`narrative.md` gives act one as *one creature, understood, taken by consent*.
This is the fight that has to deliver it, and the interesting thing is that it
delivers it without a line of tutorial text — the numbers already say it.

```
python3 design/proto/combat_solver.py tutorial --encounter kiln_duel
python3 design/proto/combat_solver.py trace  --encounter kiln_duel
```

## The encounter

One creature each. The player's Tidalpup (Tide) meets an Emberling (Ember) in
the yards where it lives.

| | creature | type | HP | speed | Guard |
|---|---|---|---|---|---|
| player Front | **Tidalpup** | Tide | 32 | 9 | 2 |
| enemy Front | **Emberling** | Ember | 28 | 11 | 2 |

A duel, not a two-a-side board, because act one should not have to explain
Front and Back before it has explained attacking. Both `combat_solver.py` and
`build_battle.gd` already tolerate an empty slot — the scene has always drawn
all four markers "regardless of occupancy" — so a side of one is a data change,
not an engine change. It was not, quite: the solver's policy functions still
had the enemies hard-coded at indices 2 and 3, which is what this tick actually
went and fixed.

## What the fight does

Every policy in the battery wins it. Random play wins 100% of the time. By the
checklist in `encounters.md` this encounter is worthless: it does not
discriminate skill even slightly.

It is still doing work, because what it teaches is not in the win column.

```
Emberling  Ember Bite -> Tidalpup   resist   -10 HP -0 Guard   [Tidalpup hp=24]
Tidalpup   Tide Slam  -> Emberling  weak     -10 HP -2 Guard BREAK  [Emberling hp=18]
Tidalpup   Tide Slam  -> Emberling  weak     -10 HP -2 Guard BREAK  [Emberling hp=8]
Tidalpup   ... and here the player has two Charges and an Emberling on 8 HP.
```

Take the Offer and it joins you. Swing again — the obvious thing, the thing
every player does — and Tide Slam's 10 damage kills a creature on 8 HP.

**The window is exactly one decision wide.** Not one turn of slack: none. The
turn capture becomes possible is the same turn the next attack takes it away.

## Nobody tuned that

This is the part worth writing down. The one-decision window is not a number
anyone chose; it falls out of Guard and HP being damaged by the same swings.

Two weak hits break Guard twice, which is the two Charges an Offer costs. Three
hits kill. Two is one less than three. That is the whole derivation, and it
holds across the roster: of the eight duels in the current roster where capture
is possible at all, six have **zero** spare attacks and two have one.

| player | enemy | decisions | HP when the Offer opens | spare attacks |
|---|---|---|---|---|
| Tidalpup | Emberling | 3 | 8 | 0 |
| Tidalpup | Ashmoth | 3 | 8 | 0 |
| Galewing | Tidalpup | 3 | 12 | 1 |
| Rootshell | Galewing | 3 | 4 | 0 |
| Rootshell | Ridgewalk | 3 | 6 | 0 |
| Ashmoth | Rootshell | 4 | 6 | 0 |
| Ridgewalk | Tidalpup | 3 | 12 | 1 |
| Ridgewalk | Ashmoth | 4 | 2 | 0 |

The near-tidy claim I nearly wrote here was *capture in a duel requires the type
advantage*, because Guard only falls faster than HP when your hits do 2 Guard
damage instead of 1. It is wrong. Ridgewalk against Ashmoth is neutral in both
directions and captures in four decisions — it just needs enough HP on the
target to survive the four hits that bank two Charges. The correct statement is
about a ratio, not a type: capture is reachable when `hits-to-kill` exceeds
`hits-to-two-breaks`, and the type advantage is only the most common way to buy
that.

## Consequences

**The battle UI has to announce the Offer the instant it is legal.** A
one-decision window is fine as a lesson and indefensible as a trap. This is now
a requirement on the engine work, not a balance number: if the second Break
does not visibly change what the player can do, the encounter teaches nothing
and just quietly deletes a creature.

*Measured a tick later, and worse than written here:* this is not a tutorial
requirement. `capture.md` now carries the window for every encounter and it is
0–2 decisions wide everywhere. In the two-a-side fights it shuts because the
player **wins**, which is less legible than killing the creature, not more — a
player who wins cleanly has no way to know anything was on offer. The duel is
only where the narrowness was easiest to see.

**The Kiln Yards keep producing the duel.** `regions.json` now lists
`kiln_duel` as the region's default encounter, and the recovery from mashing is
that the place offers another. Act one's premise does not get to die because
the player pressed A three times. That is also what a region is *for* — the
alternative was giving the tutorial Emberling a bespoke +50% HP stat block so
the window is two decisions wide (measured: 42 HP gives two spare attacks), and
a creature whose stats lie about which creature it is buys the wrong thing.

**`OFFER_COST` widens the window and was left alone.** At a cost of 1 Charge,
capture is available after one Break with 18 HP still on the Emberling and one
spare attack. That is a kinder tutorial and a worse game — `capture.md` prices
the Offer at two Breaks because two Breaks is what "you have understood this
creature" costs everywhere else, and making the tutorial cheap would be tuning
the whole capture system to fix a tooltip.

**`GUARD_REGEN=0` makes capture impossible outright.** A creature that stays
Broken can never be Broken a second time, so the second Charge never arrives.
`position.md` already has GUARD_REGEN as BOUNDED rather than free, so this is
not a constant changing category — but it fails for a different reason than the
one that put it there, and a duel is where that shows.

## Why the checklist does not apply

`encounters.md`'s rule — every creature must be able to do Guard damage to
something opposite it, or it is absent from the Charge economy and the fight
cannot discriminate skill — rejects this encounter. Tide resists Ember, so the
Emberling can never Break the Tidalpup.

That rule is right and this encounter is right; they are about different
things. A tactical fight must discriminate skill, so naive play must lose. A
tutorial must not be losable, because a player who has not been told the rules
plays naively and has to survive it. Those are opposite requirements, and one
checklist cannot hold both.

So `encounters.json` marks the duel `"tutorial": true`, the Charge-economy rule
skips it, and `farm/agreements.py` holds it to a contract of its own instead:

1. naive play wins — the tutorial is not losable;
2. the enemy is capturable — there is something to learn;
3. mashing attack costs you the creature — the lesson has teeth.

An exemption without a replacement rule is just a hole. This one is checked
every run.
