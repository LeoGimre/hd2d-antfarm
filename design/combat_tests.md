# Putting the combat logic under test

M3's fifth box is *"combat logic under unit test."* It reads like the easiest
box on the roadmap and it is not, for a reason nobody has written down yet: **the
loop cannot add anything to its own gate.** `farm/verify.sh` is on the loop's
deny list, so whatever tests get written, the loop cannot wire them into the
thing that actually blocks a commit.

This document decides what to build anyway, what to assert, and what "under
test" is allowed to mean given that constraint.

## The runner problem

`verify.sh` does three things: import assets, `--check-only` every `.gd`, and
smoke-run the main scene for 180 frames. None of them executes a test, and the
loop may not edit the file to add a fourth.

Three ways out, in order of how much they were considered:

- **Hide tests inside the main scene** so the smoke run executes them. Rejected
  immediately: the main scene is the diorama, the thing a viewer watches, and
  bolting an assertion harness into it corrupts the one artifact this project
  exists to produce.
- **Write tests and simply not run them automatically.** Rejected. A test suite
  nobody runs is worse than none, because it reports safety it is not providing.
- **`farm/test.sh`, owned and invoked by the loop.** Taken. `farm/` is the loop's
  own directory. The script runs the suite, exits non-zero on failure, and the
  tick ritual runs it alongside `verify.sh` before any commit touching `game/`.

That is weaker than a gate — the loop could forget — and it should be recorded
plainly rather than dressed up. **Only Leo can make it a gate**, by adding one
line to `verify.sh`. Until then it is a discipline, and `STATE.md` is where the
discipline gets written down so the next session inherits it.

One consolation worth noting: `verify.sh`'s parse stage already `--check-only`s
every `.gd` in the project, so test files that stop compiling *will* fail the
real gate. Compilation is not correctness, but it means a rotted test file
cannot sit there unnoticed.

## Shape

`game/tests/run_tests.gd`, a `SceneTree` script in the same style as
`build_battle.gd`, run as:

```
godot --headless --path game --script res://tests/run_tests.gd
```

No third-party framework. `site/build.mjs` already argues this position for the
site — an unattended loop redeploying for months should not own a dependency
tree — and it applies harder to a game engine, where a test addon is a plugin
that can break on an engine update with nobody watching. What is actually needed
is a counter, a comparison, and a non-zero exit; that is thirty lines.

The classes under test were built for this. `CombatResolver` is pure static
methods with no `Node` reference, `TypeChart` and `CreatureDB` parse a file and
answer lookups, and `TurnQueue` tracks order and nothing else. None of them needs
a running scene. `battle.gd` does, and is therefore out of scope here — see the
last section.

## Tier 1 — rules

These encode `design/combat.md`, not today's balance. They should survive every
future tuning pass unchanged; if one of them has to be edited, either the design
changed or something is wrong.

`CombatResolver.resolve()` damage, for a `power 8` melee and `power 6` ranged
move (arithmetic shown so it can be checked without running anything):

| case | arithmetic | expected `hp_damage` |
|---|---|---|
| melee from Front at Front | 8 +2 | **10** |
| melee from Back at Front | 8 | **8** |
| ranged from Front at Front | 6 +2 | **8** |
| ranged from Front at Back | (6 +2) × 0.75 | **6** |
| ranged from Back at Back | 6 × 0.75 = 4.5 | **5** |
| melee from Front, Charge spent | (8 +2) × 1.5 | **15** |
| melee from Front at a Broken defender | (8 +2) × 1.5 | **15** |
| melee from Front, Charge *and* Broken | (8 +2) × 1.5 × 1.5 = 22.5 | **23** |
| ranged from Back at a Broken Back | 6 × 0.75 × 1.5 = 6.75 | **7** |

The last three matter most, because they are the only places rounding is
load-bearing. GDScript's `round()` breaks halves **away from zero**: 4.5 → 5 and
22.5 → 23. A port of this logic into a language that rounds half-to-even gets
both wrong, which is not hypothetical — it is a bug that had to be corrected in
the tick-10 solver before its numbers meant anything.

Guard, from the same call:

- `weak` → 2 Guard damage, no heal; `neutral` → 1; `resist` → 0 Guard damage and
  `heal == 2`.
- `breaks_defender` is `(not defender.broken) and defender.guard > 0 and
  guard_damage >= defender.guard`. Worth a case each for: exactly equal (1 vs 1 →
  breaks), short by one (1 vs 2 → does not), a resisted hit on a 1-Guard
  defender (0 vs 1 → does not), a defender already at 0 Guard (does not — you
  cannot break something twice), and a defender already `broken` (does not, even
  with enough Guard damage).

`CombatResolver.apply()`:

- Guard floors at 0 rather than going negative.
- HP clamps into `[0, max_hp]`, so a resist heal on a full-HP defender does not
  overheal and a large hit does not drive HP below zero.
- `defeated` is set exactly when HP reaches 0.

`TypeChart`: one assertion per direction of the four-cycle, plus the case that
matters for a growing roster — an unknown type on either side returns
`"neutral"` rather than throwing. Adding a fifth type should degrade, not crash.

`TurnQueue`: initial scheduled time is `1000 / speed`; `advance()` returns the
soonest and reschedules it by `1000 / speed` past *its own* previous time rather
than any wall clock; `preview(n)` returns the same sequence `advance()` would and
leaves real state untouched — call `preview(6)`, then `advance()` six times, and
assert the ids match.

## Tier 2 — outcomes

This is the tier worth building the harness for. M3's fourth box is *"a battle
that can be lost by playing badly and won by playing well"*, and a box like that
is not really done when a clip shows it once — it is done when it stays true.
Three assertions over the shipped encounter make it permanent:

| scripted line | must |
|---|---|
| naive: melee every turn, never Charge | **lose** |
| correct targeting + spend every Charge | **win** |
| correct targeting, never spending a Charge | **lose** |

The third is the one that keeps the design honest. It is what distinguishes
"the Break/Charge economy matters" from "the Break/Charge economy exists", and
per `design/first_blood_balance.md` it is currently true only under the
re-paired roster — a future tuning pass that quietly makes Charge irrelevant
again would flip it, and should fail.

These assert **outcomes, not margins**. Not "the player finishes on 34 HP" — that
number is a fact about today's tuning and will change the first time anyone
touches a stat, and a test that cries at every deliberate change trains people
to ignore it.

Tier 2 needs the fight driven without a scene, which `battle.gd` cannot do today
— its turn loop lives in `_process`, its input arrives through the `Input`
singleton, and its state updates write to `Label3D`s. Extracting the rules and
flow into a headless class with `battle.gd` as a thin scene-driver over it is
the real work of this box, and it is worth doing on its own merits: it is the
same separation that made `CombatResolver` cheap to reason about.

## Tier 3 — a golden trace

One test that plays the winning line and compares the full event log against a
committed expected list, event for event. This is what caught divergence in the
tick-10 port — sixteen consecutive matching events is a much stronger statement
than any single assertion — and it is the only thing that detects a change that
alters the *shape* of a fight while leaving its outcome alone.

It is also the test that will be wrong most often, on purpose. Keep it in its
own file, and treat regenerating it as a normal part of any deliberate tuning
tick: read the diff, confirm every changed line is a change you meant, commit
the new trace. A golden trace whose diff nobody reads is worthless, so if a tick
ever regenerates it without looking, that tick has failed the test rather than
the other way round.

## Not in scope

- **`battle.gd`'s UI.** Chip colours, flash tweens, prompt strings and label
  formatting are checked by looking at captured frames, which is what the QC
  step in every tick already exists for. Asserting on label text would freeze
  wording that should stay free to improve.
- **The enemy AI as a specification.** It is currently "alternate melee and
  ranged, aim ranged at Back", which is a placeholder that `design/encounters.md`
  expects to become data. Tier 2 depends on it being deterministic, not on it
  being any particular policy — assert the outcomes, and let the AI change.
- **`build_battle.gd`.** It produces a scene by eye; its correctness criterion is
  a QC frame, not an assertion.
