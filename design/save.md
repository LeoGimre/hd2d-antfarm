# Save and load

M7 lists *"save and load"* as one box among several, which undersells it. Two
finished designs already depend on it and say so:

- `design/narrative.md` — *"Save/load is what makes consequence real. Until it
  exists, this narrative can be prototyped but not felt."*
- `design/dialogue.md` — replies write world flags, and *"they mean nothing
  until save/load exists."*

So this is not an M7 concern that can wait for M7. It is a dependency of the
milestone before it, and the interesting part is not the file format.

## The problem a save file creates

`narrative.md`'s escalation is a practice spreading, visible as a region going
quiet, and its consequence is stated plainly: **this does not reverse.** The
player cannot fix a place by going back and winning harder.

A conventional save system hands them a way to do exactly that. Reload from
before, and the consequence was optional. A game about attention and its cost,
in which every cost can be undone with a menu, is a game arguing with itself —
the same failure `progression.md` identified when it rejected making the
player's own collecting straightforwardly wrong.

That is the decision this document exists to make. Everything else is bookkeeping.

## The decision: one save, written by the game

> **There is one save. The game writes it. The player never chooses when.**

No slots, no manual save, no save-scumming a capture or a fight. It autosaves on
region transitions, after a battle resolves, and after any dialogue that sets a
flag — the moments where something became true.

In exchange, and this is not optional, **the game never asks for an
irreversible decision under time pressure or without information.** That is the
whole deal. A single save is only fair if the player can always see what they
are choosing, and the design already leans that way: combat is deterministic
with a visible turn queue, capture has no dice, and `dialogue.md`'s branching
offers choices in plain language with no hidden checks. A game with hidden rolls
and one save is hostile. A game with no hidden rolls and one save is *serious*,
which is what pillar 3 is asking for.

Two consequences worth being explicit about:

**Losing a battle must not be a dead end.** With one save, a wipe cannot mean
"reload and try again" and it certainly cannot mean "your file is stuck." It
means something in the fiction — the fight ends, something is lost that is worth
losing, and the game continues. What exactly is a combat design question and is
not settled here; `combat.md`'s successor should answer it, and the solver can
help, because "how bad is a loss" is measurable in the same way everything else
has turned out to be.

**Capture cannot be re-rolled**, which was already true and is now enforced.
`capture.md` made capture deterministic precisely so a player could not reload
until the dice cooperated. One save makes that structural rather than polite.

## What is in it

Small, because `progression.md` deleted most of what a JRPG normally saves.
There are no levels, no XP, no equipment, no stat points — progression is
options, not magnitude, so a save records *what you have* and *what you have
done*, not how big your numbers got.

```json
{
  "version": 1,
  "party": [
    { "creature": "rootshell", "hp": 30 },
    { "creature": "tidalpup",  "hp": 32 }
  ],
  "region": "kiln_yards",
  "marker": "NorthGate",
  "region_state": { "kiln_yards": "default", "the_ridge": "quiet" },
  "flags": { "took_the_leash": false, "met_the_stoker": true },
  "talked": { "kiln_yard_woman": 3 },
  "seen": ["emberling", "galewing", "lastcoal"]
}
```

Five things, each owned by a document that already exists: the party
(`progression.md`), where you are (`regions.md`), what each region is currently
doing (`narrative.md`), the flags and visit counts dialogue reads and writes
(`dialogue.md`), and which creatures have been seen — which is the bestiary, and
which under `creatures.md` means something specific, since being *seen* is what
capture is about.

JSON, matching every other data file here, for the same reason: it can be read
by a person, diffed in a commit, and hand-edited when a tick needs to reproduce
a bug at a particular point in the story.

**`version` is not optional.** A save format outlives the code that wrote it, and
the loop will change this file. A loader that meets a version it does not know
should say so and refuse, rather than half-loading a save into a game that has
moved on.

## What this asks for that does not exist

Everything, honestly — party, regions, dialogue and capture are all designed and
none are built. This is worth writing down now anyway, for one reason: the
autosave decision changes how those systems are *built*, not just how they are
saved. A game that autosaves after every consequential moment needs to know
which moments those are, and that is a question each of those systems answers
for itself as it is written. Retrofitting it afterwards means auditing all of
them.

## Rejected

- **Conventional slots and manual saving.** What the genre does, what players
  expect, and it makes every consequence in `narrative.md` optional. Rejected on
  pillar 3, with the cost acknowledged: some players will find one save
  stressful and some will bounce off it.
- **Save anywhere, but some state never reverts.** Tempting — keep the
  convenience, keep the consequence. Rejected because it makes reloading produce
  a world that no save ever described, which is the sort of thing that is
  impossible to reason about six months later and produces bug reports nobody
  can reproduce.
- **No saving at all; the slice is one sitting.** Defensible for M7's 30–60
  minute vertical slice and indefensible for the game `GAME.md` describes, which
  wants a world larger than one sitting can cross. Building the slice around an
  assumption the full game breaks would be building the wrong thing twice.
- **A save that records the whole world.** Every NPC, every creature, every
  region's contents, serialised. Robust and enormous, and unnecessary: the world
  is authored, not generated, so everything except the five fields above can be
  recomputed from `game/data` plus the save. If a future tick finds something
  that cannot, that is a signal the world has started generating itself, which
  `GAME.md` lists as a non-goal.
