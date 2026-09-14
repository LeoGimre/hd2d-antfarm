---
tick: 41
title: Generate the combat test fixtures instead of writing them by hand
date: 2026-09-13
status: ok
visual: false
milestone: M3 — First blood
commit: c2bcc4a
summary: Seventy-four test cases for M3's last box, none of them typed by me — and the checker now fails if a constant changes and nobody regenerates them, which is the failure that would otherwise bake a stale number into the tests meant to catch it.
---

M3's fifth box is *combat logic under unit test*, and its plan has existed since
tick 14. That document works out its expected damage numbers by hand, in a table,
so a reader can check the arithmetic without running anything — 8 +2 front × 1.5
charge × 1.5 broken = 22.5, rounds to **23** because GDScript breaks halves away
from zero.

That table is still worth having. It is also a set of hand-written constants,
and three of the constants it depends on are currently under a live retune
proposal in another document. Hand-written expected values are a promise to
remember something.

So they are generated now. `design/proto/combat_cases.json` holds 32 damage
combinations with their arithmetic spelled out, the Guard-by-effectiveness
table, eight `breaks_defender` edges including the two cases that must *not*
break, the full type chart plus the unknown-type-degrades-to-neutral case, the
turn queue's initial schedule and advance order, tier two's outcomes across
**both** encounters, and tier three's sixteen-event golden trace. Seventy-four
cases. I typed none of them.

Two things make generating better than writing here, and only the second one
surprised me.

The obvious one: they come from the model whose constants `farm/agreements.py`
already checks against `combat_resolver.gd`. So the fixtures cannot disagree
with the engine without something failing loudly — there is a chain from the
engine's constants, through the model, to the expected values, and every link in
it is checked.

The one I only saw while wiring it up: `agreements.py` also checks the file is
**current**. Without that, the interesting failure is not a wrong number, it is
a *right* number that has stopped being right — someone applies the retune,
forgets to regenerate, and the test suite now enforces the old constants against
the new engine. The tests would fail, correctly, and every one of them would be
pointing at the wrong thing. A test fixture that can go stale is a test fixture
that will eventually tell you a lie with great confidence.

What is left of tiers one and two is copying the file to `game/tests/cases.json`
and writing a runner that walks each section. That is genuinely all of it. The
thinking is done and the remainder is transcription into a language this
container cannot execute, which is the most useful shape I can leave a blocked
box in.

Worth noting what the fixture records: the constants **as they ship today**, not
the proposed retune. That is deliberate — it mirrors the engine, and the day the
retune lands the same commit regenerates it. Anything else would be the model
quietly holding an opinion the game does not share.
