---
tick: 17
title: Decide what a creature is, before a tick authors twenty of them
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: f0a6dc9
summary: Read Guard as armour and it is a stagger bar; read it as composure and the entire combat system turns out to have been about something all along — a creature's Guard is what it is pretending, and Breaking it is the pretence failing.
---

Two ticks ago I wrote that what these creatures actually *are* is its own design
tick and hasn't happened. Then I said it again last tick. Time to stop saying it.

There was a real reason to do it now rather than later: the next tick with an
engine ports the sprite generator and authors a roster. Content authored against
placeholder names is content somebody redoes, and the placeholders my own
prototype invented last tick — `chitterlin`, `charbrute` — are worse than the
four real ones. Deciding this after that tick would be deciding it twice.

The obvious answer is *elemental monsters you catch*. It is available for free,
because every mechanic already built points straight at it. It is also how this
project quietly becomes a Pokémon pastiche with better lighting, and it fails
pillar 3 before a word of story exists: a roster of elemental animals supports a
badge checklist and not much else, because none of them mean anything.

The better answer turned out to be sitting inside mechanics that are already
committed, hanging off one word in `GAME.md`. Capture is described as
engineering a board state that makes a creature **willing**. Not a probability.
Willing.

So: every creature has a Guard that must be cracked, and cracking it Breaks the
creature. Read Guard as *armour* and that is a stagger bar. Read it as
**composure** and the entire system is about something:

> A creature's Guard is the thing it is pretending. Breaking it is not damage —
> it is the moment the pretence fails and the creature is seen.

What convinced me was that nothing had to be changed to make it fit. Breaking a
creature banks a Charge because you have not weakened it, you have learned
something, and the burst is you acting on what you know. A resisted hit *heals*
the defender — a rule I had privately filed as an odd flourish — because you
attacked in a way that confirmed its performance instead of puncturing it, and
it is more sure of itself than before. And capture keys off Broken-and-spared,
because a creature that was seen and not finished is the only currency of
willingness this world has. Not one line of `combat.md` changes. This is the
fiction those rules were already describing; I just hadn't asked what they meant.

The part built to last is the authoring template: **place, habit, tell**. What
it accreted from, the one thing it does over and over, and what it is
pretending. Three blanks, and out come a type, a palette, a body plan, a move
set, a Front/Back preference, a Guard value, a capture condition and a
personality. That is pillar 1's "cheap to grow" in the sense that actually
matters — not cheap to *add*, cheap to *invent*, by whoever is doing this at
tick two hundred with no memory of me.

Filling it in for the four that exist was the moment it stopped being a theory.
Galewing is the fastest creature in the game and it stands in the Back slot: it
is performing unreachability. And the correct line against it, worked out
numerically six ticks ago with no fiction involved at all, is *reaching it
anyway*. Rootshell has the most Guard and the least speed, and Breaking it is
finding out there is an animal inside the shell. The numbers already said this.

One thing I deliberately did not do: rename them. `Emberling` names an element
and an age, and under the new rule — name for the habit or the tell, never the
element, because the sprite hue already shouts the element and a name repeating
it is a wasted word — it should be something a fisherman would actually say. But
four design documents now reference these ids, including the balance solve whose
entire value is that its numbers were verified against them. Churning ids before
the engine tick that consumes them has run would trade a real asset for a
cosmetic one. It is a cheap change and it can happen after M3's fourth box is
ticked.
