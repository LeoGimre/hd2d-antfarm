# Dialogue

Two of M5's boxes are *"dialogue system with branching and character voice"* and
*"NPCs worth talking to twice."* `design/narrative.md` adds a requirement:
dialogue has to **remember**, because the interesting reactions are to what the
player has done — which creatures they carry, and whether they took the shortcut
they were offered.

This decides the data shape and the authoring rules. It does not write any
dialogue.

## The bar, stated as a test

Pillar 5 is unusually blunt: *people the player remembers; dialogue that sounds
written, not generated; signposts in human clothing are a failure.* And
`GAME.md` names the exact failure sentence — an NPC who says "that's a Gale-type,
weak to Root" is a signpost. `design/creatures.md` gave the corresponding
success: an NPC who describes a creature by its **tell** is a character.

The second box is even more testable, so make it the standard:

> **An NPC is not finished until it has at least one line that only appears
> because of something the player did.**

Not "has more than one line." Not "cycles through three greetings." A reaction to
a change. That is the whole difference between a character and a vending
machine, and it is checkable by reading one file.

## The shape

`game/data/conversations.json`, matching the convention every other data file
already follows — an object wrapping one named array of entries with ids:

```json
{
  "conversations": [
    {
      "id": "kiln_yard_woman",
      "nodes": [
        { "when": {"party_has": "lastcoal"},
          "say": "You've got one of the coal-sitters. They wait on ground that isn't going to warm up again, you know. Nobody's told them." },
        { "when": {"flag": "took_the_leash"},
          "say": "You've got one of the new collars. No, it's fine. Everyone does." },
        { "when": {"talked": ">0"},
          "say": "Still here." },
        { "say": "Kiln's cold since spring. Something still wakes up when I light the small one, though." }
      ]
    }
  ]
}
```

**First match wins, top to bottom.** No priorities, no weights. The author writes
most-specific-first and reads the file in the order it will fire, which is the
only ordering rule anyone remembers under pressure.

**The last node must be unconditional.** That is the line when nothing else
applies, and a conversation without one can dead-end. `farm/agreements.py` should
check it — it is exactly the class of thing that file exists for.

**`talked` is free.** The engine records a per-conversation count, so the most
common condition — *have we met?* — costs the author nothing and no bookkeeping.
Nearly every "worth talking to twice" line starts here.

### Conditions

Deliberately few, and all reading state rather than computing it:

| condition | true when |
|---|---|
| `talked` | the visit count matches (`">0"`, `"0"`, `">2"`) |
| `flag` | a named world flag is set |
| `not_flag` | it is not |
| `party_has` | a creature with that id is in the party |
| `party_type` | any party creature has that type |

That is enough for everything `narrative.md` asks for and stops well short of a
programming language. If a line needs a condition this cannot express, the honest
move is usually to add a flag rather than a new operator.

### Branching

A node may carry replies:

```json
{ "say": "...",
  "replies": [
    { "text": "Where did you get it?", "goto": "the_collar" },
    { "text": "(say nothing)", "set": {"refused_to_ask": true} }
  ] }
```

`goto` names another node by id; `set` writes world flags. A reply may do either,
both, or neither. That is the entire branching model, and it is enough for
`narrative.md`'s central scene — the method being *offered* to the player,
helpfully, by someone with no bad intentions, where refusing costs time and
accepting is allowed.

## Three authoring rules

**No templating. Ever.** No `"Nice {creature}!"`. Every line is written whole. A
sentence assembled from a template is precisely the thing pillar 5 calls
generated, and once one exists the pressure is always to add another rather than
write. The condition system exists to make specific lines *affordable*, not to
make generic ones parameterisable.

**Name the tell, not the type.** `creatures.md`'s rule, restated where the
dialogue author will be standing. "One of the coal-sitters, waiting on ground
that isn't going to warm up" is a person talking. "That's an Ember-type" is a
tooltip.

**Every NPC has a relationship with attention.** `narrative.md` made this the
spine of the story, and it is also the most useful character prompt available: the
one who watches too much; the one who sells the leashes and is kind to her
customers; the one who could once name every creature on a ridge, cannot now, and
does not connect the two facts. An NPC without such a relationship will end up a
signpost, because there is nothing else for them to be.

## What this needs that does not exist

- **World flags with a lifetime.** `set` writes them and conditions read them,
  and they mean nothing until save/load exists (M7). Until then dialogue can be
  built and demonstrated within a session but not *felt*, in the same way
  `narrative.md` notes consequence cannot be.
- **A party.** `party_has` and `party_type` need `design/progression.md`'s party
  to exist, which needs capture, which needs the encounter work.
- **A region layer**, for the same reason `encounters.md` now defers region state
  to one: an NPC in a place the practice has been through should have different
  lines, and that is a region's fact, not a conversation's.

None of that blocks writing the format down, and all of it argues against
building the format until at least the party exists — otherwise half the
conditions are untestable.

## Rejected

- **An existing dialogue language (Ink, Yarn, Twine).** Genuinely good, and
  rejected twice over: it is a dependency in a project that has refused every
  dependency so far on the grounds that an unattended loop should not own a tree
  of them, and its expressiveness invites logic to migrate into dialogue files.
  The format above cannot express a loop, which is a feature.
- **A node graph with explicit edges everywhere.** More general than
  first-match-wins, and it needs an editor to stay legible. No editor exists, and
  authoring a graph in JSON by hand is worse than authoring an ordered list.
- **Dialogue attached to the scene or the NPC node.** Fastest to build and it
  puts content in scenes, which `encounters.md` already argued against for the
  same reason: content growth must not require touching code or scenes.
- **Randomised flavour lines.** The cheap way to make an NPC feel alive, and it
  works against the box. Random variety is not a reaction; talking twice should
  reward you for having *changed something*, not for pressing the button again.
