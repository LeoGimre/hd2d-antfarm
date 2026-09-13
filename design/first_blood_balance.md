# First blood — balancing the proof battle

M3's fourth box is *"a battle that can be lost by playing badly and won by playing well."*
Ticks 8 and 9 both went at it by hand and both came back with half an answer: tick 8 found the
naive line *winning*, tick 9 fixed that by cutting every creature's Guard by one — and then spent
the rest of its budget failing to find any line that reliably won the same fight.

This document is the tick that stopped guessing. It settles three questions:

1. Is the committed proof battle winnable at all? **Yes, but only by an accident.**
2. Why does every sensible plan lose? **The roster split points the player's only type advantage
   at the enemy it least needs to kill.**
3. What fixes it? **Re-pairing the same four creatures across the two sides. No stat changes, no
   resolver changes, no new content.**

## Method, and why to distrust it a little

The battle was ported off-engine into a small solver so the decision tree could be searched
exhaustively instead of sampled by hand. The port mirrors `TurnQueue.advance()` (soonest scheduled
time, ties to the earliest array index), `battle.gd._take_turn()` (Guard regen → defeated → Broken
→ act), `battle.gd._pick_target()` (melee reaches Front, or Back once Front falls; the enemy AI
aims ranged at Back), and `CombatResolver.resolve()/apply()` including GDScript's `round()`, which
breaks halves away from zero where Python's breaks to even — `int(round(4.5))` is 5 in the engine
and 4 in naive Python, and that one difference moves real damage numbers.

The port is validated against the one battle whose outcome is already committed: it reproduces
tick 9's naive result move for move — Tidalpup dies, Galewing finishes **completely untouched at
24/24 HP**, both player creatures wiped. Sixteen consecutive events matching is good evidence the
port is faithful, but it is still a model of the game and not the game. **Every number below has
to be re-confirmed in-engine before M3's fourth box gets ticked.**

## Finding 1 — the committed fight is not winnable by any plan you could explain

Player Emberling (Front) + Rootshell (Back) versus Tidalpup (Front) + Galewing (Back):

| player line | result | player HP left | enemy HP left |
|---|---|---|---|
| naive: always melee, never Charge | **loss** | 0 | 24 |
| always melee, always spend Charge | **loss** | 0 | 24 |
| always snipe the Back slot | **loss** | 0 | 16 |
| Rootshell snipes Back, Emberling melees Front | **loss** | 0 | 18 |
| Swap Rootshell to Front turn 1, then melee | **loss** | 0 | 24 |
| **`combat.md`'s own prescribed correct line** | **loss** | 0 | 18 |
| random play (4000 trials) | 0.4% win rate | | |

The exhaustive search does find exactly one shape of win, and it is not a strategy. It is the naive
line with a single Spore Cloud substituted on the player's second decision, landing Rootshell at
**2 HP**. One early Break costs Galewing one turn, and one turn is the whole margin. Nobody would
ever find that line by understanding the fight, and nobody watching would learn anything from
seeing it.

Note the second row. `always melee, always spend Charge` is byte-identical to naive, because a
melee-only player never *banks* a Charge in this matchup: Emberling's Ember Bite is resisted by
Tidalpup (0 Guard damage) and Rootshell's Root Slam is neutral (1 Guard damage) against a Tidalpup
that regenerates 1 Guard on every one of its own turns. The Break/Charge economy — the system
`combat.md` built specifically to make matchup knowledge outrank raw numbers — is not merely
underpowered here. It is **unreachable**.

## Finding 2 — the diagnosis

Three things are wrong, in increasing order of importance.

**Tempo.** Enemy speeds total 23 (Tidalpup 9, Galewing 14); player speeds total 18 (Emberling 11,
Rootshell 7). The enemy takes 28% more turns before a single decision is made. In a system where
HP damage does not care about type (see below), turns *are* damage.

**HP damage is type-blind.** `CombatResolver.resolve()` never consults effectiveness when
computing `hp_damage`; effectiveness only reaches Guard damage and the 2 HP resist heal. A resisted
hit therefore deals full damage — in the naive log below, Rootshell's *resisted* Root Slam takes 15
HP off a Broken Emberling, exactly what a super-effective one would. So knowing the matchup buys
Breaks, and Breaks buy turn denial, and turn denial is a second-order effect that cannot cover a
first-order 28% tempo deficit.

**The decisive one: the roster split aims the type advantage at the wrong target.** The type chart
is a four-cycle, Ember → Root → Gale → Tide → Ember. Splitting it as `{Ember, Root}` against
`{Tide, Gale}` gives each side exactly **one** weak matchup — and the player's is Rootshell into
Galewing. Galewing is also the enemy the player least needs to kill, because Gale is *resisted* by
Root, so Galewing is the one enemy that struggles to hurt Rootshell. The player's only reward for
reading the type chart correctly is permission to attack the harmless enemy. Matchup knowledge is
not weakly useful in this fight; it is **anti-correlated with correct play**. That is the precise
inverse of pillar 2, and it explains why two ticks of honest effort could not find a line: the line
they were looking for, the one `combat.md` describes, is genuinely a losing line.

## The fix — re-pair the same four creatures

Split the cycle across the sides instead of along it. Pair each side with two creatures that sit
*opposite* each other in the cycle rather than adjacent:

> **Player:** Rootshell (Front) + Tidalpup (Back)
> **Enemy:** Emberling (Front) + Galewing (Back)

Now every creature on the board has exactly one target it is strong against and exactly one it is
resisted by, and — this is the part that makes it a *positional* fight rather than a targeting
quiz — **every correct target is diagonal**:

| attacker | slot | strong against | which stands in | so it must |
|---|---|---|---|---|
| Rootshell | Front | Galewing | enemy Back | use its ranged move to reach across |
| Tidalpup | Back | Emberling | enemy Front | reach forward from the Back slot |
| Emberling | Front | Rootshell | player Front | melee straight ahead |
| Galewing | Back | Tidalpup | player Back | snipe across |

The naive habit — melee, which is locked to the enemy Front slot — sends Rootshell into Emberling,
the one enemy that resists it. Playing well means noticing that both of your correct attacks cross
the board, and that reaching them costs you the Front damage bonus and the 25% Back-target penalty.
That is the Front/Back rule doing the job it was designed for, instead of being decoration.

No creature stats change. No resolver constant changes. No new content. The entire fix is which
creature stands in which of the four slots.

### What that does to the fight

| player line | result | player HP left | enemy HP left |
|---|---|---|---|
| naive: always melee, never Charge | **loss** | 0 | 24 |
| anti-typed: attack whoever resists you | **loss** | 0 | 41 |
| always snipe the Back slot | **loss** | 0 | 38 |
| correct targeting, but never spends a Charge | **loss** | 0 | 10 |
| always melee, always spend Charge | win | 32 | 0 |
| **correct targeting + spend every Charge** | **win** | 34 | 0 |
| random play (3000 trials) | 8.4% win rate | | |

The fourth row is the one worth reading twice. Correct targeting **on its own still loses** — it
gets within 10 HP and dies. The player has to break the enemy *and cash the Charges it banks*.
That is the first configuration in this project's history where the Break/Charge economy is
load-bearing rather than ornamental, and it is what `combat.md` claimed the system was for.

The skill gradient is smooth rather than a cliff — the correct line, with a fraction of its
decisions replaced by random ones:

| decisions randomised | 0% | 10% | 25% | 50% | 100% |
|---|---|---|---|---|---|
| win rate | 100% | 80% | 59% | 36% | 8% |

Forgiving of a slip, unforgiving of a wrong plan. Compare the current roster, where the same
measurement reads 0% / 0% / 0.2% / 1.8% / 0.4% — a fight with no gradient at all, because there is
nothing at the top of it.

### Why the losing line reads well on video

Under the new pairing, naive does not merely lose, it loses *legibly*. Rootshell hammers Emberling
with a move Emberling resists, so the player's Charge counter never leaves 0. Galewing farms
Tidalpup with weak hits, banking Charge after Charge, and closes the fight with Tidalpup Broken on
four consecutive turns — the on-screen queue strip visibly handing the enemy turn after turn while
the player's creature sits out. Two counters on screen, one stuck at zero and one climbing. That is
the ten-second read `GAME.md`'s standard asks for.

## Handoff — what the next tick with an engine should do

The exact input sequences, in the actions `battle.gd` already polls:

**Winning line — 6 player decisions**

1. Tidalpup — `battle_move_1`
2. Rootshell — `battle_charge` + `battle_move_2` + `battle_target_back`
3. Rootshell — `battle_charge` + `battle_move_2` + `battle_target_back`
4. Tidalpup — `battle_charge` + `battle_move_1`
5. Rootshell — `battle_charge` + `battle_move_2` + `battle_target_back`
6. Tidalpup — `battle_charge` + `battle_move_1`

**Losing line — 3 player decisions:** `battle_move_1` every time. (The player only ever gets three
turns; Tidalpup spends the rest of the fight Broken.)

Three implementation notes:

- **The encounter belongs in `game/data/`, not in two `const TEAM` tables.** Who fights whom is
  content, and it is currently duplicated between `battle.gd` and `build_battle.gd` with a comment
  asking the next reader to keep them in sync by hand. Pillar 1 says adding a creature must never
  be expensive; right now changing an *encounter* is a two-file code edit. Landing this rebalance
  is the natural moment to move it to `game/data/encounters.json` and have both files read it.
- **The fight is longer than the capture window.** The winning line runs 16 logged events, roughly
  22s at the committed `TURN_INTERVAL` of 1.35 — and `STATE.md` warns that captures past 12–16s
  drop frames. Either drop `TURN_INTERVAL` to about 0.85 or capture the opening and let the result
  land off-screen.
- **Re-confirm before ticking the box.** Everything here is a model. Run both lines in-engine
  first.

## Since this was written

Four ticks of later work changed what some of the numbers above mean. Rather
than quietly editing them — this document is also the record of a decision, and
the decision was right — here is what has moved.

### Everything above is now reproducible

The solver this document was built on is committed as
`design/proto/combat_solver.py`. The two policy tables are:

```
python3 design/proto/combat_solver.py lines --encounter current  --no-capture
python3 design/proto/combat_solver.py lines --encounter repaired --no-capture
```

`--no-capture` matters. `design/capture.md` added an Offer action *after* these
measurements, and an available Offer changes what random play can stumble into:
the re-paired encounter's random win rate is **8.5%** under the rule set
measured here and **13.0%** with capture available. The published 8.4% was
correct for the rules that existed at the time. Always state which rule set a
random-play figure came from.

### The HP-left columns are no longer the signal

`design/progression.md` retracted HP margin as a measure of how close a fight
is, and this document is the main offender. Naive loses the re-paired battle with
the enemy holding 24 of 52 HP, which reads comfortable — and **five percent more
player HP reverses the result.** Surviving one extra hit buys one extra turn, and
turns compound, so HP remaining and tuning margin are barely related.

The columns stay because they are useful colour and because "0 / 41" versus
"0 / 10" does say something about how badly a line lost. But the outcome column
is the finding, and the number that describes the encounter is below.

### The tolerance band, which is the real balance number

```
python3 design/proto/combat_solver.py tolerance --encounter repaired
```

| advantage | naive | correct |
|---|---|---|
| none | loses | **wins** |
| player HP ×1.05 | *wins* | wins |
| player Guard +1 | *wins* | wins |
| enemy HP ×1.15 | loses | **wins** |
| enemy HP ×1.20 | loses | *loses* |
| both sides HP ×3.0 | loses | **wins** |

The re-paired encounter discriminates skill across a relative-power window of
roughly **−15% to +5%**, and is scale-invariant outside that — tripling both
sides changes nothing. It sits closer to the upper edge of its own band than the
middle, which is worth knowing: it tolerates a much weaker player than a
stronger one. A future tuning pass could re-centre it, and now has a number to
aim at rather than an HP margin to squint at.

## Deliberately not decided here

- **Type-blind HP damage.** It is a real oddity — a resisted hit lands for full HP — and it is
  faithful to `combat.md`, which routes effectiveness through Guard on purpose so this does not
  become Pokémon. The re-pairing makes the fight work *without* touching it, so it stays as it is.
  Revisit it if a later roster hits the same wall for the same reason; do not pre-emptively fix it
  while the current design is passing its own test.
- **Swap looks like a trap in this matchup.** Every scripted line that opened with a Swap lost, and
  the searcher never used one. That may be correct — `combat.md` prices Swap at a full turn on
  purpose — or it may mean two slots and four creatures is too small a board for Swap to ever pay.
  Not enough evidence yet either way. Worth revisiting when M4's party management gives Swap more
  than one possible partner.
