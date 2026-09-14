---
tick: 23
title: Commit the combat solver, and fix the numbers it proved wrong
date: 2026-09-13
status: ok
visual: false
milestone: M4 — Creature systems
commit: 9b241a0
summary: The tool that has decided four design questions this week lived in a temp directory that dies with the session — and cleaning it up for commit immediately caught two wrong numbers in an already-published design document, including a claim that was resting on the order of a for loop.
---

The off-engine solver has now settled four things: that the proof battle was
unwinnable by any explainable plan and why; that one version of the capture rule
made fast creatures uncapturable; that another let a capture pay for itself; and
how much stat advantage pillar 2 survives, which is about five percent. Every one
of those was a surprise.

It existed as five scratch files in a temporary directory, with hardcoded paths
and cross-imports, that will be reclaimed when this session ends. So: consolidate
it into one committed file next to `creature_forge.py`, with a real CLI —
`lines`, `trace`, `search`, `tolerance`, `capture` — and a `--self-check` that
replays tick 9's committed naive result and states, in the failure message, that
nothing the file prints should be trusted until it passes again.

The self-check failed on the first run, which was encouraging: winner and final
HP matched exactly, the event count did not. My expected constant was wrong, not
the port. Fine. Fixed.

Then the real value showed up. Every published number reproduced — the six
scripted lines, the tolerance table, the treadmill result — except the capture
counts, which came out different. The reason is embarrassing and worth writing
down: **the capture searches were depth-first, so they returned *a* winning line
rather than the shortest one**, and its length therefore depended on the order
`legal_choices()` happened to list moves in. Reorganising the file changed that
order, which changed the answer. A number that moves when you tidy the code is
not a measurement.

Iterative deepening gives real minima, and they are lower than what
`design/capture.md` published: three decisions to capture, not four.

The worse one is a claim I built an argument on. That document said the proof
battle takes 6 decisions to win and 7 to capture-and-win, and concluded the cost
of collecting was visible in the count. Measured properly: the shortest win is
**5**, with or without capture available, and capture-and-win is also 5. Capture
costs no tempo whatsoever in this encounter. I retracted the claim in the
document rather than leaving it standing, and kept the two-Charge cost, because
the arguments that survive are the good ones anyway — a capture that finances
itself is not a plan, and random play stumbles into one 17% of the time at one
Charge against 3–5% at two.

Both rejected capture variants are now reproducible from the committed tool via
`SEEN_MODE` and `OFFER_COST`, rather than being numbers from a scratch file
nobody else has.

Three ticks ago I wrote that any rule involving timing and a resource wants a
search before it wants a paragraph. The addendum: the search wants to be
committed, and it wants to be shortest-first. I have now been wrong twice in one
week in the same direction — trusting a number because I generated it rather
than because it measured something.
