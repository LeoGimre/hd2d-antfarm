# The throughline

Pillar 3 asks for *a grand narrative — a throughline with escalation and
consequence, not a badge checklist.* Twenty-one ticks in, it is the only pillar
with no design at all, and M5's last box is "act one playable," so everything in
that milestone hangs off a decision nobody has made.

This document decides the **engine** of the story — what escalates, what it
costs, and how it is told — not the story. Scenes and dialogue come later and
come easily once this is settled; they come out wrong forever if it is not.

## The constraints, which are unusually helpful

- **Not a badge checklist.** `GAME.md` names the failure mode directly, which
  rules out the default structure of the genre: eight authorities, defeat each,
  a league, a rival, a team in matching uniforms.
- **No cutscene cinematics, no voice acting.** Both are non-goals. So the story
  cannot be *shown to* the player between gameplay; it has to be carried by
  things the player is already doing.
- **The fiction is already half-decided.** `design/creatures.md` established
  that Guard is composure, that Breaking it is the moment a creature's pretence
  fails and it is *seen*, and that capture is what happens when something seen
  is spared. `design/capture.md` turned that into a rule with no dice in it.

That third constraint is the useful one, because a theme is already sitting in
the mechanics and it would be perverse to write a story about something else.

## The spine: attention

Every system this game has built is about **seeing things as they are**.

Combat is not about damage; it is about cracking a performance. Type knowledge
is knowing what a creature is pretending. Charge — the resource — is banked
understanding, and spending it is acting on what you learned. Capture is seeing
something and choosing not to finish it. Even the creatures themselves are, per
`creatures.md`, what a place does when something pays attention to it long
enough.

So the story is about attention, because the game already is. That is not a
theme pasted onto a genre; it is the only theme these rules could honestly
support.

## The engine of escalation: a contested practice

The player learns to do a slow thing well: look at a creature until you
understand it, break its composure, and let it choose you.

**Someone has found a way to skip the looking.** Not out of malice — out of
efficiency, because seeing does not scale and demand does. There is a method
that takes creatures without ever breaking their composure: a leash rather than
a recognition. It works. It is faster. It is, to most people in the world,
obviously fine, and the player will meet many people who think so and are not
stupid.

That is the antagonist, and it is an institution rather than a villain, which is
what makes it escalate. You cannot defeat a practice by winning a battle. You
can only outpace it, expose it, or become it.

**Escalation** is the practice spreading, in a way the player can see in the
world rather than be told about: a region that produced a creature at every
turning produces fewer; then none; then the place stops being distinct, because
per `creatures.md` a place's creatures *are* what it does when watched, and a
place nobody watches any more does nothing.

**Consequence** is that this does not reverse. A region the practice has been
through stays quieter. The player cannot fix it by going back and winning
harder. What they can do is get somewhere first.

And the escalation has a sting built into it: the player is also collecting. The
difference between the player's practice and the institution's is entirely a
matter of *how*, which is exactly the sort of distinction that is easy to state
and hard to hold. Good NPCs will say so.

## How it gets told without cutscenes

Three carriers, in descending order of how much work they should do:

**1. Places.** The strongest narrative device this game has, and it costs no new
systems. A region's state is legible in what lives there and what does not.
Revisiting is the mechanic: the second visit is the story. This also gives M5's
"three distinct areas with transitions" a reason to exist beyond variety, and
gives pillar 4's "reasons to cross them" a real answer.

**2. People.** `creatures.md` already set the rule: an NPC who describes a
creature by its *tell* rather than its type is a character, and one who says
"that's a Gale-type, weak to Root" is the signpost in human clothing `GAME.md`
names as a failure. Extend it — everyone in this world has a relationship with
attention. The one who watches too much. The one who sells the leashes and is
kind to her customers. The one who used to be able to name every creature on a
ridge and now cannot, and does not connect the two facts.

**3. The battle system.** Creatures taken by the institution never had their
composure broken, and it should be legible in a fight — they do not behave like
things that chose to be there. Exactly what that means mechanically is
deliberately not decided here, because it is a real combat design question and
`combat.md`'s successor should answer it with the solver rather than a paragraph.
Flagged, not designed.

## Act one, concretely

Small enough to build, big enough to establish the engine:

- The player learns the slow practice properly — one creature, understood, taken
  by consent. The tutorial is the thesis.
- A second region where the practice has already been. It is not ruined and
  there is no smoking crater; it is just quieter than the people there remember,
  and they disagree about why.
- The player meets the method and it is *offered to them*, helpfully, by someone
  with no bad intentions. Refusing costs time. Accepting is allowed.
- Act one ends not with a victory but with the player understanding the shape of
  the thing, and it being clearly larger than them.

No boss. The first act of a story about a practice should end with a realisation,
not a fight, and this game already has to earn its battles.

## What this asks of other systems

- **Dialogue** (M5) needs branching that remembers, because the interesting NPC
  reactions are to what the player has *done* — which creatures they carry, and
  whether they took the offered shortcut.
- **Regions** (M5) need a state that persists and is visible in their encounter
  tables, which is a direct requirement on `design/encounters.md`'s format: an
  encounter list must be able to differ between visits.
- **Save/load** (M7) is what makes consequence real. Until it exists, this
  narrative can be prototyped but not felt.

## Rejected

- **An evil team.** Uniforms, a logo, a leader to defeat. Rejected because a
  practice you can defeat is a badge checklist with a better costume, and
  because it makes everyone who is complicit into a henchman rather than a
  neighbour, which throws away the only genuinely uncomfortable thing here.
- **A cataclysm / ancient prophecy.** Escalates beautifully and has nothing to do
  with any mechanic in this game. It would make combat and capture into things
  the player does *between* story beats, which is precisely the badge checklist
  in a different key.
- **The player's creatures as the emotional core** (they get hurt, you feel
  bad). Cheap, effective, and it undermines the thesis: it makes collecting
  sentimental rather than a question about attention, and it invites the
  "creature is sad" beat that every game in this genre has already spent.
- **Making the player's own collecting straightforwardly wrong.** Considered
  seriously, because it is the honest reading of the theme, and rejected because
  pillar 1 says the roster keeps growing. A game that punishes its own core loop
  is a game arguing with itself. The tension stays live and unresolved instead,
  which is more interesting anyway.
