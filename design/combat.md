# Combat — the M3 pitch

M3's first checkbox is this document. Everything below is the decision the next several ticks
build against: turn order, position, and the resource that makes cracking a guard worth more than
just hitting harder. Four creatures and a battle scene come after this, not alongside it.

## What "tactical, not a stat-check" means here

Pillar 2 is the test every decision below has to pass: a skilled player beats an over-levelled
one, and a fight winnable by holding confirm has failed. That rules out the simplest version of
either half of GAME.md's own reference points — Octopath's turn-based combat has no positioning at
all, and Pokémon's single-target type chart is famous for degrading into "did you over-level and
pick the right type" once the player already knows the matchup. Neither alone clears the bar.
The design below borrows a piece from each and adds the piece neither has: **position**. That's
the thing that makes good play look different from a bigger number — a well-placed team survives
an attack a badly-placed identical team dies to, independent of level.

## The three systems

### 1. Turn order — a visible queue, not hidden speed rolls

Every combatant has a Speed stat. Initiative is deterministic: on entry, each combatant gets a
scheduled time of `1000 / Speed`; whoever's scheduled time is soonest acts next; after acting, they
get a new scheduled time of `now + 1000 / Speed`. No randomness, no hidden agility checks — the
same team composition produces the same turn order every time, so when a plan goes right or wrong
it's readable as a plan, not a dice roll.

This queue renders as a horizontal strip of the next 5–6 turns along the top of the battle screen,
portraits in order. This is the milestone's "readable state" box: a viewer watching a captured clip
should be able to predict who acts next without the game telling them, and a player should be able
to plan two turns ahead because the information to do so is already on screen.

### 2. Position — two slots per side, not a grid

Each side fields creatures into two slots: **Front** and **Back**. That's the entire board — no
row/column grid, no facing, no terrain.

- Melee moves can only target Front. If Front is empty, they hit Back directly — there is no free
  pass for emptying the front slot.
- Ranged and area moves can target either slot, but deal 25% less damage to Back than Front —
  Back is safer, not safe, so hiding there forever is a real cost (less damage dealt, since the
  creature dealing damage from Back also loses the front-only bonus described below) rather than a
  dominant strategy.
- Front deals slightly more damage than Back with any move (a flat bonus, not a multiplier that
  scales with power) — front-line pressure is rewarded, so the choice to advance or protect a unit
  is a real trade, not a strictly-better move.
- **Swap** is a full action: spend a turn to trade a creature from Front to Back or vice versa.
  Pulling a cracked or low-HP creature to safety costs the tempo of an entire turn, which is the
  size of the decision this system exists to create.

Two slots, not a 3×3 grid, because the milestone's box is "a battle that can be lost by playing
badly and won by playing well" with four creatures total — a bigger board multiplies the state a
player has to read before the fight has content worth spreading across it. A grid is a plausible
later evolution once the roster and move pool are big enough to need more shapes than "hits front"
and "hits either"; nothing here forecloses it.

### 3. Break and Charge — the resource that rewards precision over power

Each creature has, alongside HP, a **Guard** value (small integer, e.g. 3 for M3's four creatures).
Every move has a type; every creature has a type. Hitting a creature with a move it's weak to costs
it 2 Guard; a neutral hit costs 1; a resisted hit costs 0 and grants the defender a small heal-back
in spite instead. Guard regenerates by 1 at the start of its owner's own scheduled turn, so leaving
a creature alone lets it recover — pressure has to be sustained, not applied once.

At 0 Guard, a creature is **Broken**: it loses its next scheduled turn outright (removed from the
queue for one pass) and takes 50% more damage from any hit landed before it recovers. Breaking a
creature banks one **Charge** for the attacker's side. A banked Charge can be spent, at the moment
of declaring any move, to empower that move — roughly +50% power, or ignoring the Front-only
restriction on a melee move for one hit. Charges do not expire between turns but do not carry
between battles.

This is the system that makes "know the matchup" pay off further than "have the bigger number": an
over-levelled creature with wrong-type moves cracks Guard slowly, feeds no Charge, and never gets
its burst hit — a correctly-typed underdog can break, burst, and kill something twice its level
before it acts again. It is also the direct build of the pillar-seed already named in GAME.md
("cracking [guards] banks a resource spent on burst turns"), narrowed to specific numbers so the
next tick can implement it instead of re-deciding it.

## Scope: what this pitch is not deciding

- **Capture** is a seed for M4, not this milestone. M3's battle plays to a loss/win condition
  (HP to zero), full stop. Engineering a board state to make a creature willing to join is a
  separate system with its own combat hooks (likely: a capture attempt costs a turn and its odds
  key off Guard/Broken state) — worth designing once there's a battle loop to hang it on, not
  before.
- **Bonds with memory** (traits accruing from creatures fielded together) needs persistent party
  state across battles, which doesn't exist until party management lands in M4. Noted as a seed
  worth returning to, not addressed here.
- **The type chart's actual shape** (how many types, what beats what) is a data question, not a
  combat-loop question — belongs in `game/data/types/` next to the creature and move data, sized
  to whatever four creatures the next tick invents. This document fixes the *rules* a type chart
  plugs into (weak/neutral/resist → Guard damage), not the chart's contents.

## Rejected alternatives

- **Plain HP race, no Guard/Break.** The simplest possible turn-based combat and exactly what
  pillar 2 forbids: two teams trading damage until one hits zero is a stat-check by definition —
  the bigger numbers always win, full stop, no play pattern changes that.
- **Real-time ATB bars (ticking gauges, interruptible casts).** More faithful to some JRPGs' feel,
  but a filled gauge is illegible in a captured clip the way a static top-of-screen turn queue
  isn't — this project is watched while built, and "the standard" in GAME.md explicitly prefers
  legible-in-ten-seconds over technically purer. A discrete, deterministic queue is the version
  that reads instantly on video.
- **A full tactics grid (Fire Emblem / FFT style, multi-tile movement and facing).** The eventual
  ceiling for a "large and growing roster" with real positional depth, but it is a far bigger build
  than four creatures and one proof battle justify, and most of its value (reach, zones, formation)
  is already captured at this scale by two slots and a Front/Back reach rule. Revisit once the
  roster and move pool have outgrown two slots, not before.
- **Mana/AP pool spent on all moves (final-fantasy-style resource for every action).** Redundant
  with Charge: two currencies gating the same kind of decision (can I afford my strong move) adds
  bookkeeping without adding a tactical question that Guard/Charge doesn't already ask. One
  resource, earned by playing the matchup correctly rather than accumulated by waiting, is enough.

## What "worth losing badly, winning well" looks like

A concrete shape for the first proof battle, for whoever builds the battle scene next: two
creatures per side. The naive line — both player creatures in Front, attacking whatever's in the
enemy's Front slot every turn regardless of type — should lose: it feeds no Charge, takes repeated
front-line damage, and never breaks anything before the enemy's own Charge turns a fight. The
correct line — identify the type each enemy is weak to, put the creature that carries that type in
Front while the other supports from Back, break the enemy Front, spend the resulting Charge on the
kill, swap the exposed creature back before the enemy's burst lands — should win the same matchup,
same levels, same four creatures. If a future tick builds the four creatures and that second line
doesn't reliably beat the first, the numbers in this document (Guard size, the Back damage
penalty, Charge's power bonus) are the ones to retune, not the shape of the systems.
