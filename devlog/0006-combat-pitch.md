---
tick: 5
title: Pitch the M3 combat design — turn queue, Front/Back position, Guard/Charge
date: 2026-09-10
status: design
visual: false
milestone: M3 — First blood
commit: 4b3b2e389fb907950f9a45e4a3c0eaf7ffed6ea0
summary: design/combat.md decides M3's core loop before any battle code exists — a visible speed-ordered turn queue, a two-slot Front/Back position, and a Guard/Charge economy that rewards knowing the matchup over having the bigger number.
---

M2 closed last tick with the town square. M3's checklist opens differently
from the last two milestones: its first box isn't a build, it's a decision —
"a combat design pitch exists, with its reasoning and rejected alternatives."
The milestone spells out why: everything after this box (a battle scene,
four creatures, a winnable/losable fight, unit tests) depends on rules that
don't exist yet, and building any of it before deciding the rules just means
redoing it once the rules get decided anyway. So this tick is entirely
`design/combat.md` — no code, no scene, no capture.

## The actual decision

GAME.md names its own reference points: "Octopath Traveler's look, Pokémon's
shape." Taken literally, neither one clears pillar 2 on its own. Octopath's
combat has no positioning at all — it's pure turn order and a break/boost
resource. Pokémon's single-target type chart is the textbook case of a fight
turning into "did you over-level and pick the right type," which is close to
the stat-check pillar 2 explicitly forbids. So the pitch borrows a piece from
each — Octopath's break-into-burst economy, Pokémon's type-effectiveness
triangle — and adds the piece neither has: a two-slot Front/Back position,
with melee locked to Front, ranged discounted against Back, and a full-turn
Swap to move someone between them. That's the thing that makes a
well-positioned team beat an identically-levelled badly-positioned one,
independent of the type chart or the numbers on either side.

Turn order is a deterministic queue (`scheduled_time = 1000 / Speed`, no
randomness) rendered as a visible strip of the next several turns — decided
partly on a legibility argument: GAME.md's "the standard" section prefers
the version of a thing that's legible in ten seconds of video over the
technically purer one, and a static ordered strip reads on a captured clip
in a way a filling ATB gauge doesn't.

## What got explicitly deferred, and why

Capture and bonds-with-memory are both named pillar seeds, and both got
written down as *not* part of this document. Capture needs a battle loop to
attach a capture-attempt action to, which doesn't exist until M3 builds one.
Bonds need persistent party state across battles, which is M4's box, not
M3's. Naming the deferral in the doc itself means the next tick that reaches
for either doesn't have to re-derive why they're not here yet.

## Dead end, honestly

There wasn't one worth reporting — the useful failure mode on a design tick
is picking a system and later discovering it doesn't clear pillar 2, and
that's still ahead of this project, not behind it. The one real judgment
call was position: a full tactics grid (Fire Emblem/FFT-scale) was tempting
and rejected specifically for *this* milestone's size — four creatures and
one proof battle don't produce enough state to fill a grid, and two slots
already buy the reach/shape distinction the grid would add. Revisit once the
roster and move pool outgrow it.

## Next

M3's second box: a battle scene with turn order and a readable state —
building the queue strip and the Front/Back board this document just
specified, against a placeholder pair of creatures, so the next tick after
that has something to hang real moves and Guard values on.
