# Encounters as data

Who fights whom is content. Right now it is a `const TEAM` dictionary, written
out twice — once in `game/scripts/battle.gd` and once in
`game/tools/build_battle.gd` — with a comment in each asking the next reader to
keep them in sync by hand. Changing which creature stands in which slot is
therefore a two-file code edit, which is the thing pillar 1 says must never
become expensive.

`design/first_blood_balance.md` needs exactly that change made (the four
creatures are paired onto the wrong sides), so the next tick with an engine is
going to touch both tables anyway. This document decides the shape it should
land in, so that tick spends its time confirming a fight rather than inventing a
file format.

## First: what the duplication is actually for

Worth establishing before designing anything, because it turns out to be much
less than the comments imply.

`build_battle.gd` runs standalone and offline, before `battle.gd` ever executes,
and generates `scenes/battle.tscn`. From `TEAM` it uses:

- **the node name** (`PlayerFront`, …) — but that is derived from side and slot,
  not from the creature;
- **the capsule colour** — chosen by *side*, not by creature;
- **the slot position, label lift and label font scale** — all keyed by slot,
  every one of them a value tuned by staring at QC frames, and none of them
  anything to do with which creature stands there;
- **the creature's name, type, HP and Guard**, baked into the `InfoLabel` text.

Only the last one is really about the roster. And `battle.gd._ready()` calls
`_refresh_status_labels()`, which overwrites every one of those labels before the
first frame is presented. **The baked text is never seen.** The two tables have
been kept in sync to agree about a string that is discarded on frame zero.

So the generated scene does not need to know the roster at all. It needs to know
the *board*: four slots, their positions, and their per-slot presentation
tuning. That stays in `build_battle.gd`, where it belongs — it is tuned visual
code, not content. Everything else moves to data, and the second table simply
stops existing.

## The format

`game/data/encounters.json`, alongside the three files that are already there:

```json
{
  "_comment": "Who fights whom. Slot geometry and per-slot label tuning are presentation and live in tools/build_battle.gd; this file only says which creature stands where.",
  "encounters": [
    {
      "id": "first_blood",
      "display_name": "First Blood",
      "player": [
        { "creature": "rootshell", "slot": "front" },
        { "creature": "tidalpup",  "slot": "back"  }
      ],
      "enemy": [
        { "creature": "emberling", "slot": "front" },
        { "creature": "galewing",  "slot": "back"  }
      ]
    }
  ]
}
```

That is the whole thing, and it is deliberately the same shape as
`creatures.json` and `moves.json`: an object wrapping one named array, each entry
carrying an `id`. Three files that parse the same way are three files a new
loader can be written for without re-reading the last one.

**Sides are named arrays, not a `side` field on a flat list.** Two slots per side
is a claim `combat.md` makes about the board, and a format that can express
"three creatures on the player side" invites someone to try it. The arrays make
the shape enforceable at load time in one line.

**Node names are derived, never listed.** `PlayerFront` is
`side.capitalize() + slot.capitalize()`, which is the convention `battle.gd`
already relies on in `_pick_target()` and `_execute_player_swap()`. Putting node
names in the data file would reintroduce exactly the hand-synced mapping this
change exists to delete.

## How each side reads it

A new `EncounterDB` in `game/scripts/`, shaped like `CreatureDB` — a
`RefCounted` that parses one file in `_init()` and answers lookups. Not a method
on `CreatureDB`: an encounter is not a creature, and `CombatResolver` has already
shown the value of keeping these classes free of Node references, since that is
what makes them cheap to put under test in M3's fifth box.

`battle.gd` replaces its `TEAM` loop with a walk over the encounter's two arrays,
building the same `CombatantState` and `TurnQueue` entries it builds today. The
`side` and `slot` it currently reads out of `TEAM` come straight from the data.

`build_battle.gd` reads the same encounter only to bake initial label text, and
keeps its own slot table for positions and tuning — keyed by slot, with no
creature ids in it.

### Which encounter a scene is

`battle.gd` gets an exported `encounter_id`, and `build_battle.gd` sets it on the
root node before packing. The scene then carries its own identity, and building a
second battle scene for a second encounter is the same tool run with a different
id — which is most of what M5's "repeatable region authoring workflow" will want,
arriving early and for free.

One trap to avoid on the way: Godot only serialises an exported property whose
value differs from the script's declared default. Give `encounter_id` an empty
default and always set it explicitly, or a scene built for the default encounter
will silently store nothing and any later change to that default will
retroactively repoint it.

### When the data is wrong

A game whose content grows by editing JSON will have JSON edited wrongly. The
loader should fail loudly and name both halves — the encounter id and the
creature id it could not find — rather than letting `CreatureDB.get_creature()`
raise a bare missing-key error from somewhere down the stack. A creature id
typo'd in an encounter is going to be one of the most common mistakes this
project makes for the next fifty ticks; it should cost ten seconds, not ten
minutes.

**And it will not be caught by the gate.** `farm/verify.sh` smoke-runs the *main*
scene, which is the diorama; nothing in the gate ever loads `battle.tscn`. A
malformed `encounters.json` therefore passes verify and fails only when someone
runs the battle demo. That is not an argument for weakening anything — it is an
argument for the loader's error message being good, and worth remembering the
next time a tick assumes green means the battle still works.

## Deliberately not in the format yet

Each of these has an obvious slot in the shape above, and none of them has a
caller:

- **Per-encounter stat overrides** (`"level": 8`, or a flat HP multiplier). There
  are no levels. When there are, they belong on the entry next to `creature`.
- **Enemy AI policy.** The AI is currently hardcoded in `battle.gd`: alternate
  melee and ranged, aim ranged at Back. Different encounters will eventually want
  different behaviour, and `"ai": "..."` on the side is where it goes. Not until
  a second behaviour exists to name.
- **Rewards, capture eligibility, dialogue hooks.** M4 and M5. Adding empty keys
  for them now is forecasting, and `GAME.md` is explicit that hooks for
  non-goals do not get left lying around.
- **Boards other than two slots.** `combat.md` already argues a grid is a
  plausible later evolution. If it happens, it is a new board shape with its own
  slot names, not a variable-length array smuggled into this one.

## Requirements added after this format was written

This document was written at tick 13. Three documents since have imposed things
on it, and one of them looked like a format change. Reconciled here so the tick
that builds this is not implementing a format that three other decisions have
already invalidated.

### An encounter must be able to differ between visits — but not here

`design/narrative.md` makes region state the primary storytelling device: a
place the antagonist's practice has been through is quieter, and that is visible
in what the player meets there. It calls this "a direct requirement on
`design/encounters.md`'s format."

On inspection it is not, and this is worth getting right rather than bolting a
`when:` field onto the entries above. **An encounter is atomic: who fights
whom.** *Which* encounter occurs, in a given place, at a given point in the
story, is a different question with a different owner — a region layer that does
not exist yet. Putting world-state conditions inside encounter entries would put
narrative logic in the combat content file, and every later region feature would
have to grow a matching field here.

So: the requirement is satisfied by a region owning a list of encounter ids per
state, and this file stays a flat list of atomic encounters. **Do not add a
condition field to an encounter.** If a region needs a quieter version of a
fight, that is a second encounter with its own id, which is also easier to
balance, because it can be measured independently.

One consequence for the "which encounter is this scene" decision above: baking
`encounter_id` into the generated scene is right for M3, where there is one
battle, and wrong the moment a region picks encounters at runtime. `battle.gd`
will need to accept an encounter id at load time as well as from the scene. That
is a small change and it is not needed yet; it is recorded so it is not a
surprise.

### Every creature must be capturable by a party the player can plausibly have

From `design/capture.md`. Capturability is a property of the encounter and the
party, not of the creature — a party with the wrong types cannot break a
creature, and a creature that cannot be broken cannot be taken. Across forty
encounters that is invisible; while authoring one it is obvious.

It is also checkable, which turns it from a good intention into a step:

```
python3 design/proto/combat_solver.py capture --encounter <id>
```

### Balance is a tolerance band, not an HP margin

From `design/progression.md`. An encounter that satisfies pillar 2 sits near a
boundary, and how far each side can move before the outcome flips is the number
that describes it. HP remaining is not that number and has misled two ticks: the
proof battle's naive line loses with the enemy holding 24 of 52 HP, and five
percent more player HP reverses it.

```
python3 design/proto/combat_solver.py tolerance --encounter <id>
```

### The solver should read this file

`design/proto/combat_solver.py` currently carries its own hardcoded `ENCOUNTERS`
dict, duplicating exactly the table this document exists to delete — acceptable
only because the file it should read does not exist yet. When it does, the
solver reads it, and the balance tool and the game are checking the same bytes.

### The checklist, then

Before an encounter ships:

1. `python3 design/proto/combat_solver.py --self-check` — the model still
   matches the engine; nothing below counts otherwise.
2. `lines` — naive loses, correct play wins, and correct play that hoards its
   Charges loses. That third one is what makes the Break/Charge economy
   load-bearing rather than ornamental.
3. `tolerance` — where the encounter sits in its band, and ideally near the
   middle of it rather than at one edge.
4. `capture` — every creature in it is capturable by a party the player could
   have.

## Rejected alternatives

- **One file per encounter, in a `game/data/encounters/` directory.** Tempting for
  a project expecting a lot of them, and rejected because the site already tried
  exactly this guess for creatures and got it wrong — the project's actual
  convention is one flat file per content kind. Consistency with the three files
  that exist beats a layout chosen for a volume that does not.
- **Leaving the roster in `battle.gd` and deleting only the copy in
  `build_battle.gd`.** Halves the duplication for much less work. Rejected because
  it leaves adding an encounter as a code edit, which is the actual complaint;
  the second table is the symptom, not the disease.
- **Generating the scene at runtime instead of from a build tool.** Would delete
  the duplication outright by deleting `build_battle.gd`. Rejected: the per-slot
  positions, label lifts and font scales in that file were each arrived at by
  looking at QC frames, and the record of *why* each value is what it is lives in
  its comments. Moving that into runtime code trades a hand-synced table for the
  loss of the most expensively-earned knowledge in the scene.
