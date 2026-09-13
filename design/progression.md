# Progression

Pillar 2: *a skilled player beats an over-levelled one.* Every JRPG this game
shares a shape with answers progression the same way — numbers go up — and that
answer is in direct tension with the pillar. M4's last undesigned box is "party
management and progression," so the tension has to be resolved before anything
is built against it.

The pillar contains a number, so this tick measured it rather than arguing about
it, using the solver that settled `design/first_blood_balance.md` and threw out
two versions of `design/capture.md`.

## The measurement

The re-paired proof battle, in which naive play loses and correct play wins.
Give one side an advantage and ask whether that stays true.

**Advantage to the player** — does naive play start winning anyway?

| advantage | naive line |
|---|---|
| none | loses (as designed) |
| HP ×1.05 | **wins** |
| move power +3 (about +30% on an effective hit) | **wins** |
| Guard +1 | **wins** |
| speed ×1.50 | **wins** |
| every stat ×1.15 | **wins** |

**Advantage to the enemy** — does correct play still win?

| advantage | correct line |
|---|---|
| HP ×1.10 | wins |
| HP ×1.15 | wins |
| HP ×1.20 | **loses** |

**Both sides scaled together** — the classic treadmill:

| both sides | result |
|---|---|
| HP ×1.5 | naive loses, correct wins |
| HP ×2.0 | naive loses, correct wins |
| HP ×3.0 | naive loses, correct wins |

## What that says

**Absolute magnitude is free. Relative advantage is not.** Tripling everyone's
HP changes nothing about whether the fight discriminates skill — the tactical
structure is scale-invariant. Moving one side five percent destroys it.

The window in which pillar 2 holds is roughly **−15% to +5%** of relative power.
That is not a design choice that could be loosened by tuning; it is close to a
theorem. A fight that discriminates skill is a fight sitting near a boundary,
and anything that moves the numbers moves you off the boundary. **Any encounter
tight enough to satisfy pillar 2 is, by construction, this sensitive.**

Two specifics worth carrying:

**Guard must never grow.** A single point of it flips the fight. Guard is not a
stat, it is a discrete gate — how many hits to break — and adding one changes an
outcome rather than a quantity. Nothing in progression may touch it, ever.

**HP-remaining is a bad measure of how close a fight is.** Naive loses the proof
battle with the enemy still holding 24 of 52 HP, which looks comfortable, and
yet five percent more player HP reverses it. The reason is the same discreteness:
surviving one extra hit means taking one more turn, which compounds. Ticks 9 and
10 both used HP margin as the closeness metric and it was misleading both times.
**The real measure of an encounter's balance is its stat-tolerance band** — how
far each side can be moved before the outcome flips — and it should be measured,
not eyeballed.

## Therefore

> **Progression adds options, never magnitude.**

Concretely:

- **Creatures learn moves.** This is the main axis. A new move is new type
  coverage, a new category, a new reach — a plan you did not previously have. It
  does not change throughput, so it cannot move the ratio. A creature that
  learns a ranged move has become able to touch the Back slot, which is an
  enormous change in what is possible and no change at all in how hard it hits.
- **The roster is the progression.** More creatures means more correct answers
  available, which is pillar 1 and pillar 2 pointing the same way for once: the
  reward for playing is options, and options only help a player who knows which
  one to reach for. This is also why capture has to be worth doing.
- **Bonds with memory** — the `GAME.md` seed — must produce *conditional,
  sideways* traits and never a percentage. "While this creature is in Back, its
  ranged moves ignore the Back-target penalty" is a trait. "+10% damage" is a
  pillar-2 violation with a nice name.
- **Difficulty comes from enemy composition, not enemy stats.** A 20% stat bump
  makes correct play lose, which is exactly as bad as the player over-levelling
  — it stops skill mattering, just in the other direction. Harder fights are
  fights with better type coverage against you, better slot discipline, and AI
  that does not waste turns.
- **If numbers ever grow, both sides grow in lockstep.** The treadmill is proven
  harmless here — it changes nothing — which is also the argument against it. It
  is a presentational device, not a reward. Permitted; never the point.

## Party management

Which follows, because if progression is coverage then the party screen is where
progression is *spent*.

A battle fields two creatures a side, Front and Back. A party is larger. So
choosing which two to field, before the fight, is the moment all that accumulated
coverage turns into a plan — and it is a real decision precisely because the
numbers do not save you. Swap, in `combat.md`, trades the two that are already
out; it does not reach into reserve, and it should not, because the board is two
slots and a game that can substitute freely from a bench has no positional
tension left.

That is as far as this document goes. Party size, where reserves live, what
happens when the party is full and a capture lands — those need a UI and a save
system to exist, and neither does yet.

## Rejected

- **Levels and XP.** The default, and measurably incompatible: the growth curve
  of any conventional level system passes through +5% in its first level or two
  and never comes back. It could be salvaged by scaling every enemy in lockstep,
  which is the treadmill, which is proven to change nothing — a lot of machinery
  to move two numbers in the same direction.
- **Equipment.** Same problem wearing a hat, with the extra cost that it is a
  second economy to balance and `combat.md` already rejected a second resource
  for that reason.
- **Player-assigned stat points.** The above, but the player is now the one
  breaking pillar 2, which is worse — they will do it, correctly, because the
  game offered it.

**Caveat:** all of this is the off-engine model, validated against a committed
engine result but still a model, and measured on a single encounter. The
scale-invariance and the Guard result are structural and should hold anywhere.
The exact −15%/+5% window is this fight's, and any encounter should have its own
band measured rather than assuming these numbers.
