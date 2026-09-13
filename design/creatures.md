# What a creature is

Sixteen ticks in, this project has creature *stats*, a creature *type chart*, and
now a creature *sprite grammar*. It has no answer to what a creature is. The four
that exist are an element plus a noun — Emberling, Tidalpup, Galewing, Rootshell
— and the twenty placeholders the sprite prototype invented last tick are worse.

That was fine while nothing depended on it. It stops being fine now, because the
next engine tick ports the sprite generator and authors a roster, and content
authored against placeholders is content someone redoes. Deciding this is
cheaper before that tick than after it.

## The problem with the obvious answer

The obvious answer is "elemental monsters you catch," and it is available for
free because every mechanic already built points at it. It is also how this
project ends up as a Pokémon pastiche with better lighting, which fails pillar 3
before a word of story is written: a roster of elemental animals supports a badge
checklist and not much else, because none of the creatures *mean* anything.

There is a better answer sitting in the mechanics that are already committed,
and it comes from one word in `GAME.md`. Capture is described as engineering a
board state that makes a creature **willing**. Not a probability. Willing.

## Guard is composure, not armour

Every creature has a Guard that must be cracked. Cracking it Breaks the creature:
it loses its next turn and takes more damage until it recovers.

Read that as armour and it is a stagger bar. Read it as **composure** and the
whole system becomes about something:

> A creature's Guard is the thing it is pretending. Breaking it is not damage —
> it is the moment the pretence fails and the creature is *seen*.

That is why breaking one banks a Charge: you have not weakened it, you have
learned something, and the burst you spend the Charge on is you acting on what
you now know. It is why a resisted hit heals the defender "in spite" — you
attacked it in a way that confirmed its performance instead of puncturing it, and
it is more sure of itself than before. And it is why capture works the way
`GAME.md` says it does: a creature that has been Broken and *not* finished has
been seen and spared, which is the only currency this world has for willingness.

None of that requires a mechanical change. Every rule already in
`design/combat.md` stays exactly as written. This is the fiction those rules were
always describing, found rather than added.

## The authoring template: place, habit, tell

A creature is three lines. This is the part designed to survive to tick two
hundred, when whoever is inventing creature sixty-one has no memory of this
document beyond the template.

**Place** — what it accreted from. A creature is what a place does when
something pays attention to it long enough. *Determines type and palette.*

**Habit** — the one thing it does over and over. *Determines body plan, moves,
and where it wants to stand.*

**Tell** — what it is pretending, and therefore what Breaking it reveals.
*Determines its Guard, its capture condition, and its voice.*

Three blanks, and out the other side come a type, a palette, a body plan, a move
set, a Front/Back preference, a Guard value, a capture condition and a
personality. That is the roster staying cheap to grow in the sense pillar 1
actually means — not just cheap to *add*, cheap to *invent*.

### The four that exist

| | place | habit | tell |
|---|---|---|---|
| **Emberling** | banked hearths and burnt ground | goes back to the warm spot | pretends it is not cold |
| **Rootshell** | old growth that outlived the wood around it | does not move | pretends the shell is the whole of it |
| **Tidalpup** | the line the water keeps returning to | comes back with the tide | pretends to be leaving |
| **Galewing** | ridgelines and updrafts | never lands | pretends nothing can reach it |

Every one of those tells is legible in a fight without a line of dialogue.
Galewing is the fastest creature in the game and stands in the Back slot: it is
performing unreachability, and the entire correct line against it in
`design/first_blood_balance.md` is reaching it anyway. Rootshell has the most
Guard and the least speed, and Breaking it is finding out there is an animal
inside. That is not a retrofit — it is what the numbers already said, once
someone asked what they meant.

## Naming

Name a creature for its **habit or its tell**, never for its element.

The element is already the loudest thing on screen: the sprite grammar gives
every creature a hue keyed to its type, so "Ember-" in a name is a word spent
repeating what the player can see. Spend it on the half they cannot see.

Names should sound like something a person in this world would call the thing,
which usually means compound, plain, and slightly unkind. `Tidalpup` names an
element and an age. `Comeback`, `Neverlands`, `Won't-Be-Cold` name a behaviour
and a lie, and are the kind of thing a fisherman would actually say.

**Not renaming the existing four in this tick.** Four design documents currently
reference `emberling`, `rootshell`, `tidalpup` and `galewing` by id, including
the balance solve whose whole value is that its numbers were verified. Churning
those ids while the engine tick that consumes them has not run yet would trade a
real asset for a cosmetic one. Renaming is a cheap, self-contained change and it
should happen *after* M3's fourth box is ticked, not during.

## What this unlocks that was blocked

- **Capture** (M4) stops needing a probability table. The design question becomes
  "what does this creature need to have seen before it is willing," which is the
  tell, which is already written. `combat.md` guessed the odds would key off
  Guard and Broken state; under this fiction they do not key off anything —
  Broken-and-spared *is* the condition, and the tactical act is engineering that
  rather than a kill.
- **Bonds with memory** (a `GAME.md` seed, deferred to M4) gets its content.
  Creatures fielded together accrete traits *from each other's tells* — the thing
  that pretends it is not cold, fielded beside the thing that never lands, learns
  something specific. That is a bond with a reason rather than a counter.
- **Voice** (pillar 5) gets a rule. Creatures do not speak. But an NPC who
  describes a creature by its tell rather than its type is a character; one who
  says "that's a Gale-type, weak to Root" is a signpost in human clothing, which
  `GAME.md` names as a failure by that exact phrase.
- **Regions** (pillar 4) get a reason to be distinct. Place is the first line of
  the template, so a region that is not distinct cannot produce creatures that
  are. "What does this place do when it is watched" is a much better region brief
  than "forest area."

## Rejected

- **Elemental spirits bound into bodies.** The default, and it explains where
  creatures come from without making any of them mean anything. Every creature
  ends up interchangeable with a recolour.
- **Creatures as fragments of a broken thing, collected to reassemble it.**
  Strong narrative engine — it turns collection into plot, which is exactly what
  pillar 3 wants. Rejected because it makes the roster *finite and ordered* by
  construction, and pillar 1 says it keeps growing. A design where creature
  sixty-one has to be justified against a cosmology is a design that stops at
  sixty.
- **Creatures as ordinary animals, changed.** Warm and grounded, and it makes
  every creature's identity a reference to a real animal the player already
  knows, which caps how strange the roster is allowed to get. The place/habit/tell
  template can produce a thing that is recognisably a dog *and* a thing that is
  recognisably nothing; a "changed animals" premise can only produce the first.
