# Reading the design

Seventeen documents is more than anyone should read alphabetically, which is how
they were listed until this page existed. This is what each one decides, in an
order that makes sense, with the dependencies marked — because several of them
overturn each other and reading them out of order gives you the wrong answer
confidently.

**If you are here to build something**, `state/STATE.md` carries the build queue
and the current warnings. This page is for understanding *why*, not *what next*.

## Start here

**[`combat.md`](combat.md)** — the original pitch for M3's combat: a
deterministic turn queue, two-slot Front/Back position, and the Guard/Charge
economy. Everything else in this directory is downstream of it. It has two
addenda pointing at documents that revise it; read those when you get to them
rather than now.

**[`creatures.md`](creatures.md)** — what a creature *is*. The single most
load-bearing document here, and the one that has paid off most often: Guard is
composure, not armour, and Breaking it is the moment a creature's pretence fails
and it is seen. That reading was derived from mechanics that already existed,
and it has since supplied the answer to two separate mechanical problems that
looked numerical.

## The fight, and how it was fixed

Read in this order. Each one corrects something in the one before.

1. **[`first_blood_balance.md`](first_blood_balance.md)** — the proof battle was
   unwinnable by any explainable plan, and the cause was not tuning: the four
   creatures were paired onto the wrong sides. Also carries the current
   three-constant retune proposal.
2. **[`position.md`](position.md)** — which combat constants are load-bearing.
   **Read the corrections at the bottom first**; the tables above them were
   measured on one encounter and two of their conclusions are wrong.
3. **[`swap.md`](swap.md)** — Swap as specified is a trap that makes random play
   *worse*. Fixed by what `creatures.md` already said Guard means.
4. **[`second_encounter.md`](second_encounter.md)** — a second fight, which
   confirmed the diagonal requirement is structural and found that a one-type
   enemy line cannot produce a tactical fight at all.
5. **[`progression.md`](progression.md)** — how much stat growth pillar 2
   survives, measured. Very little. Progression must add options, never
   magnitude.
6. **[`capture.md`](capture.md)** — capture as a deterministic act, with two
   earlier versions of the rule and why the solver killed them.
7. **[`tutorial.md`](tutorial.md)** — the Kiln Yards duel. The window in which
   a creature can be captured rather than killed is one decision wide, nobody
   chose that, and it is the whole lesson. A tutorial needs the opposite of the
   encounter checklist, so it gets a contract of its own.
8. **[`combat_tests.md`](combat_tests.md)** — how any of this gets under test,
   given that the loop may not edit its own gate.

## Content and how it is made

**[`roster.md`](roster.md)** — twenty creatures, authored from `creatures.md`'s
place/habit/tell template. Deliberately unstatted; see `progression.md` for why
inventing numbers before measuring is a mistake this project has already made
twice.

**[`creature_sprites.md`](creature_sprites.md)** — the composable sprite
grammar. A creature is a body plan, proportions, a palette and features, where
the body plan is a *function* rather than a stored map. The rule everything
turns on: only the silhouette reads.

**[`encounters.md`](encounters.md)** — who fights whom, as data. Reconciled
against three documents written after it; the reconciliation section is the
useful half.

## The world

**[`narrative.md`](narrative.md)** — the story is about attention, derived from
the mechanics rather than pasted onto them. The antagonist is a method, not a
person.

**[`regions.md`](regions.md)** — Ground / Work / Attention. A region that is
only a palette swap cannot fill in its third line, which is the check against
reskins. Constrained by `second_encounter.md`: a region may be one type, an
encounter may not.

**[`dialogue.md`](dialogue.md)** — ordered nodes, first match wins, and one
testable bar: an NPC is not finished until it has a line that only appears
because the player changed something.

**[`hd2d_look.md`](hd2d_look.md)** — the house style, and an audit of how far
the battle scene has drifted from it. Contains the one number every scene must
agree on.

**[`town_square.md`](town_square.md)** — the M2 location, written before any of
the above. Kept as-is.

**[`save.md`](save.md)** — one save, written by the game, because a story about
consequence that can be reloaded has no consequence. Small, because
`progression.md` deleted most of what a save normally holds.

## The tools

Not documents, but where most of the recent findings came from.

- **`proto/combat_solver.py`** — the off-engine battle model. `--self-check`
  replays a committed engine result; **if it fails, nothing the file prints
  counts**. Subcommands: `lines`, `trace`, `search`, `tolerance`, `capture`,
  `constants --all-encounters --band`.
- **`proto/creature_forge.py`** — the sprite generator. `--sheet` renders the
  roster to one image.
- **`proto/gen_test_cases.py`** — generates the combat test fixtures.
- **`../farm/agreements.py`** — checks everything this project claims must stay
  consistent, including that the two above have not gone stale.

## What to distrust

Written down because a reader deserves it, and because I keep needing the
reminder.

**Everything measured is off-engine.** The model reproduces one committed engine
result move for move, which is good evidence and is not the same as being the
game. Every number wants re-confirming in an engine.

**Anything measured on one encounter may be wrong specifically in the direction
of "this rule does nothing."** That has happened twice, caught both times only
by a second fight. `constants --all-encounters` now exists for this reason.

**The oldest sections of a document are the least reliable.** Corrections here
are made by addendum rather than by editing, so that a document also records
what was believed when a decision was made. That means the top of a long
document is sometimes superseded by its own bottom, and `position.md` says so
in as many words.
