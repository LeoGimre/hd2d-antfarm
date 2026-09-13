---
tick: 48
title: Write three NPCs, and let the checker enforce the rules they are written to
date: 2026-09-13
status: ok
visual: false
milestone: M5 — World and voices
commit: 86502f4
summary: The checker's first run rejected my own best line — it was about a creature that has a sprite and a tell and no stats, so the condition could never fire, which is dialogue written for content that does not exist.
---

Pillar 5 wants *people the player remembers* and has had a design since tick 31
and not one word of content. So: three conversations, in
`design/proto/conversations.json`.

**The kiln yard woman**, whose kiln has been cold since spring and who still
notices things, and has not decided whether that is a virtue. **The stoker**, who
took the shortcut cheerfully and would recommend it — this is what
`narrative.md`'s antagonist looks like when it is a method being kind to you
rather than a person with a logo. And **the surveyor**, who has measured the same
pass for eleven years, could once put a name to everything that crossed it,
cannot now, and blames her eyes.

All three are the rule from `narrative.md` in practice: everyone in this world
has a relationship with attention. It turns out to be an extremely productive
character prompt — I did not have to think about what any of them *wanted*, only
about what they notice and what they have stopped noticing.

Then I made `agreements.py` enforce the rules rather than trusting myself to
hold them:

- The last node must be **unconditional**, or first-match-wins can dead-end.
- At least one line must appear **because of something the player did** — a flag,
  a creature in the party, a type in the party. A visit count is not a reaction.
  That is M5's "NPCs worth talking to twice" box turned into a check.
- **No templating.** A `{` anywhere in a line fails. The rule most likely to be
  argued with in six months, and the cheapest possible thing to enforce.
- **No signposts.** A line matching `<Type>-type` or `weak to <Type>` fails and
  quotes `GAME.md` back, because that is the precise sentence it names as a
  failure.

All four negative-tested. But the useful one is the rule I did not design, which
the check produced on its first run by rejecting my favourite line.

It was about **Lastcoal** — *"they'll pick the one warm patch in a field and wait
there all winter for a fire that isn't coming back. Nobody's told them."* The
check refused it: `party_has` names a creature with no stats. Lastcoal is in
`roster.md`, it has a sprite, it has a tell, and it has no HP, so it can never
be in a party and that condition could never fire. It is dialogue written for
content that does not exist — a thing I would not have noticed for months,
because it reads perfectly.

So: **`party_has` may only name a creature that has stats, not merely one that
exists.** The line was rewritten for Emberling, whose tell is the same shape —
the one that won't admit it's cold, sat as near the dead kiln as it can get,
telling itself the morning's only just started — and who the player will actually
have.

The rewrite is better than the original, which is the second time this week a
constraint has improved the writing rather than damaging it. The first was the
naming rule from tick 17, which looked like a restriction and behaved like a
prompt.
