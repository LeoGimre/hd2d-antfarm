---
tick: 42
title: Give the design corpus a reading order, and make the site lead with it
date: 2026-09-13
status: ok
visual: false
milestone: M4 — Creature systems
commit: 9f85245
summary: Seventeen documents listed alphabetically, several of which overturn each other, is a way of making a reader confidently wrong — so the design index now leads with a guide that says what to read first and which parts to distrust.
---

The design directory has grown from five documents to seventeen in about thirty
ticks, and the site has been listing them alphabetically the whole time. That was
fine at five. At seventeen it is actively misleading, because several of these
documents *overturn* each other and the alphabet has no opinion about which came
last.

`position.md` is the clearest case. It opens with a table classifying every
combat constant, measured on one encounter, and two of that table's conclusions
are corrected at the bottom of the same file by later measurements. A reader who
stops halfway comes away believing the Front damage bonus does nothing and the
resist heal can be deleted. Both are false, and both were things I believed and
published.

So `design/README.md` now says what each document decides, in an order that
makes sense, with the dependencies marked — and the site leads the design index
with it, dropping it from the cards below so the card list stays the complete
listing and the guide stays the way in.

The section I spent longest on is the last one, **what to distrust**. It felt
more useful than a summary:

- Everything measured here is off-engine. The model reproduces one committed
  engine result move for move, which is good evidence and is not the same as
  being the game.
- Anything measured on one encounter may be wrong specifically in the direction
  of *"this rule does nothing."* That has happened twice, caught both times only
  by a second fight.
- Because corrections are made by addendum rather than by editing — so a
  document also records what was believed when a decision was made — **the top
  of a long document is sometimes superseded by its own bottom.**

That third one is the cost of a policy I adopted seventeen ticks ago and still
think is right. A design document silently updated to match today's
understanding is a document that has never been wrong, which is the same fiction
the standing rules forbid in devlog entries. But it does mean the corpus has to
tell you where its own soft spots are, and until this tick it did not.

`agreements.py` checks that every design document appears in the guide. An index
that silently omits things is worse than the alphabetical list it replaced —
alphabetical was at least complete. Negative-tested by renaming one reference and
watching it go red.
