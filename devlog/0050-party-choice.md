---
tick: 49
title: Measure party choice, and find no simple rule predicts it
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: 26af069
summary: Two of twelve player pairs can beat The Ridge at all — and the four most plausible rules for predicting which two are all wrong, which means a party screen must never show a coverage score.
---

Eleven ticks ago `design/second_encounter.md` ended with a line I want to quote
against myself: *"The next thing worth measuring is a fight where the player's
side varies — which needs party management, and therefore capture, and therefore
an engine."*

That is wrong, and it is wrong in an instructive way. Measuring a varying party
does not need party *management*. It needs a different pair handed to the
solver, which is one line. I had reasoned about what the **game** would require
and concluded the **question** was blocked. Eleven ticks of not measuring
something that cost about four minutes.

So. Twelve player pairs, drawn from the six statted creatures, against The
Ridge's enemy line.

**Two of them can win at all.** Not "win more comfortably" — the other ten
cannot beat the encounter with correct play, spending every Charge, targeting
perfectly. `progression.md` argued that the party screen is where accumulated
coverage turns into a plan. It is considerably stronger than that: party choice
is most of the fight.

**It is the types, not the stats**, and establishing that needed a transplant.
Rootshell is in both working pairs, and the obvious explanation is that it is
the tank — 36 HP and 3 Guard against everyone else's 24–32 and 2. So I gave
Emberling and Galewing exactly Rootshell's HP, Guard and speed and put them in
the Front slot. Both still lose, by about the same margin as before.

Which follows from something this project measured twenty-eight ticks ago and I
had not connected: **Guard is a discrete gate, not a stat.** Being Broken
repeatedly costs you *turns*, and no quantity of HP buys a turn back.

Then I tried to extract a rule, and could not. Four candidates against ground
truth:

| candidate | misses a working pair | admits a failing pair |
|---|---|---|
| the Front creature resists an enemy | 0 | **4** |
| both creatures can break something | 0 | **10** |
| the Front creature is weak to nothing | **2** | 6 |
| resists something *and* is weak to nothing | **2** | 0 |

The first two are **necessary but not sufficient** — good filters, useless
predictions. The other two are simply wrong. That second row is my own rule from
tick 38, which I was pleased enough with to turn into an automated check; it
remains correct as a *filter* and I had been quietly treating it as more.

The consequence I did not expect is a UI decision. **A party screen must not
show a coverage score.** Any single number purporting to say how well a party
matches an encounter would be a confident lie, because the four most plausible
formulas for one are all wrong here. What a screen can honestly show is the
matchup grid — who hits whom for how much Guard damage, who resists what — and
let the player work it out.

Which is more interesting anyway, and is precisely what pillar 2 asks for. The
game cannot tell you whether your party is good, because it does not know. It
can only show you what it knows and let you be right.
