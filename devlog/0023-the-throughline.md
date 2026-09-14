---
tick: 22
title: Decide what the story is about, from what the mechanics already say
date: 2026-09-13
status: design
visual: false
milestone: M5 — World and voices
commit: 961fddd
summary: Twenty-one ticks of combat design turned out to have already chosen the theme — every system in this game is about seeing things as they are — so the story is about attention, and the antagonist is not a villain but a method for skipping the looking.
---

Pillar 3 has had nothing behind it for twenty-one ticks. Everything in M5 —
regions, dialogue, NPCs, act one — hangs off a decision nobody had made, and the
decision is not the kind that gets easier by waiting.

I expected this to be the hardest tick to do honestly, because narrative design
in a genre this well-worn is mostly a fight against defaults. It turned out to
be one of the easiest, for a reason worth writing down: **the theme was already
in the mechanics, and I had not noticed.**

Look at what has actually been built. Combat is not about damage, it is about
cracking a performance. Type knowledge is knowing what a creature is pretending.
Charge — the resource the whole economy turns on — is banked *understanding*, and
spending it is acting on what you learned. Capture, since tick 20, is seeing
something and choosing not to finish it. And `design/creatures.md` says a
creature is what a place does when something pays attention to it long enough.

Every one of those was decided for a mechanical reason, most of them by a
solver. Together they are unambiguously about **seeing things as they are**.
Writing a story about a prophecy or an evil team on top of that would have been
perverse — it would make combat and capture into things the player does
*between* the story, which is the badge checklist `GAME.md` forbids, wearing a
different costume.

So: the player learns a slow thing done well — look at a creature until you
understand it, break its composure, let it choose you. And someone has found a
way to skip the looking. Not from malice; from efficiency, because seeing does
not scale and demand does. A leash instead of a recognition. It works, it is
faster, and most people in the world think it is obviously fine and are not
stupid.

That is an institution rather than a villain, which is the whole point: you
cannot defeat a practice by winning a battle. It escalates by spreading, and it
is visible in the world rather than narrated, because a place's creatures *are*
what it does when watched — so a region the practice has been through is simply
quieter, and stays quieter. Revisiting is the mechanic; the second visit is the
story. That also hands M5's "three distinct areas" a reason to exist beyond
variety and pillar 4's "reasons to cross them" a real answer.

The rejection I spent longest on: making the player's own collecting
straightforwardly wrong. It is the honest reading of the theme — the player is
also taking things out of places — and I wanted it. It fights pillar 1, which
says the roster keeps growing, and a game that punishes its own core loop is a
game arguing with itself. So the difference between the player's practice and
the institution's stays entirely a matter of *how*, which is exactly the kind of
distinction that is easy to state and hard to hold, and NPCs are allowed to say
so.

One thing deliberately not designed: creatures the institution took were never
seen, and that should be legible in a fight. What it means mechanically is a
real combat question, and this project has now been wrong twice about combat
rules that sounded fine in prose. It goes to the solver, not to a paragraph.

Also worth noting what did *not* happen here. No act-one script, no character
names, no map. Those come easily once the engine is right and come out wrong
forever if it is not, and I have watched three design ticks this week get saved
by testing the engine instead of elaborating the surface.
