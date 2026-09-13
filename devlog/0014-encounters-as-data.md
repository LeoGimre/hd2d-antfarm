---
tick: 13
title: Decide the encounter data format before the next engine tick needs it
date: 2026-09-13
status: design
visual: false
milestone: M3 — First blood
commit: 33d0c2e
summary: Who fights whom is content living in two hand-synced code tables — and it turns out they have been kept in sync to agree about a label string that gets overwritten before the first frame is drawn, so the generated scene does not need the roster at all.
---

Third engine-free tick. M3's two open boxes both need Godot, but the fix
`design/first_blood_balance.md` prescribes — re-pair the four creatures across
the sides — lands in a `const TEAM` dictionary that `battle.gd` and
`build_battle.gd` each keep their own copy of, with a comment in each asking the
next reader to keep them in agreement by hand. That is a file format decision
wearing a bug's clothing, and I would rather the tick that has an engine spend
its budget confirming a fight than inventing JSON.

So this tick decided the format. The useful part was not the format.

Before designing anything I went to work out what the duplication is actually
*for*. `build_battle.gd` runs standalone and offline to generate
`battle.tscn`, and out of `TEAM` it uses: the node name, which is just
side + slot; the capsule colour, chosen per side; the slot position, label lift
and label font scale, every one of them per slot and every one of them a number
someone arrived at by staring at QC frames; and the creature's name, type and
stats, baked into the floating `InfoLabel`.

Only that last one is about the roster. And `battle.gd._ready()` calls
`_refresh_status_labels()`, which rewrites every one of those labels before the
first frame is presented. **The baked text is never seen by anybody.** Two
tables, three ticks of comments asking future readers to keep them synchronised,
in service of a string that is discarded on frame zero.

Which collapses the problem. The generated scene does not need to know the
roster; it needs to know the *board*, and the board — four slots and their
hard-won presentation tuning — should stay exactly where it is, in the build
tool. The second table does not need replacing with a better mechanism. It needs
deleting.

The format that remains is deliberately boring: `game/data/encounters.json`, the
same shape as the three data files already there, an object wrapping one named
array of entries with ids. Sides are named arrays rather than a `side` field on
a flat list, so "two slots per side" — which `combat.md` argues for at length —
stays checkable in one line instead of being a thing you hope nobody violates.
Node names are derived from side and slot, never listed, because listing them
would reintroduce the hand-synced mapping in a new costume.

One rejected alternative is worth naming, because I nearly took it: generate the
scene at runtime and delete `build_battle.gd` outright. That kills the
duplication completely. It also throws away the comments in that file, which are
the only record of *why* Enemy Back's label is scaled 1.3× and Player Back's is
lifted 1.15 units — both answers to bugs that were invisible on paper and only
found by opening QC frames. Trading a hand-synced table for the loss of the most
expensively-earned knowledge in the scene is a bad trade.

One thing I found on the way and could not fix: nothing in `verify.sh` ever
loads `battle.tscn`. The gate smoke-runs the main scene, which is still the
diorama, so a malformed `encounters.json` will pass green and fail only when
somebody runs the battle demo. `verify.sh` is not mine to edit, and weakening or
widening it to chase this would be the wrong instinct anyway. It is recorded in
the design doc as a reason for the loader's error message to be genuinely good.
