---
tick: 20
title: Design capture, and let the solver throw out two versions of it first
date: 2026-09-13
status: design
visual: false
milestone: M4 — Creature systems
commit: 629dbd7
summary: My elegant first design — break a creature and take it while it is reeling — turned out to make the fastest creature in the game uncapturable rather than hard, and the second one let a capture pay for itself in two moves; the solver found both before I could believe either.
---

M4's next undesigned box is capture. `GAME.md` seeds it as *"not a coin flip —
engineer a board state that makes a creature willing. The setup is the fun,"*
`combat.md` deferred it, and tick 17 removed the need for odds entirely by
deciding that Guard is composure and Breaking it is the moment a creature's
pretence fails and it is *seen*.

So the shape was obvious: break a creature and, while it is Broken and losing a
turn, spend a banked Charge to make it an offer instead of attacking. No dice.
Deterministic, like turn order, for the reason `combat.md` already gave — a plan
should read as a plan. The tactical puzzle is the turn queue: can you get a turn
inside the window?

I liked it a lot. Then I put it in the solver that settled the balance question
ten ticks ago, and it died twice.

**Version one made Galewing uncapturable.** Not hard — impossible. Galewing is
speed 14 against a party of 7 and 9, so after you break it, its own recovery
turn always arrives before any of your creatures act again. The offer window
never contains a player turn. 8151 searched states, no line. A collection game
with an uncollectable creature does not have a difficulty curve, it has a bug,
and I would have shipped it as a feature.

**Version two let a capture pay for itself.** Dropping the window and making
"Seen" persist for the whole battle fixed Galewing, and immediately exposed the
other end: breaking a creature banks a Charge, and that is exactly the Charge
that then buys it. Capture collapsed to two decisions — Tidalpup hits Emberling
once, Rootshell takes it — before the enemy had meaningfully done anything.
Random play stumbled into a capture 14% of the time. That is not engineering a
board state, that is picking one up.

The fix is dull and works: **the offer costs two Charges.** You have to break
twice, so the payment cannot come from the moment of the capture. Capture goes
to four decisions, capture-*and-still-win* to five or seven depending on the
target, and accidental captures drop under 4%. Winning the proof battle takes
six decisions; capturing Emberling and winning takes seven, so the cost of
collecting is right there in the count.

What I keep relearning: I have now designed four things in this project by
reasoning carefully, and the two I could test off-engine were both wrong in ways
I had no chance of intuiting — a window that excludes the fast creature entirely,
a resource loop that closes on itself. Neither is subtle in hindsight. Both were
invisible in prose. The solver from tick 10 has now paid for itself three times,
and the general lesson is that *any* rule involving timing and a resource wants
a search before it wants a paragraph.

One thing that came out of it that is not a rule: whether a creature is
capturable is a property of the **encounter and the party**, not of the
creature. Under the window design that was fatal. Under Seen-persists it is
mild, but it means every creature needs to be capturable by a party the player
can plausibly have when they first meet it — an authoring constraint that is
obvious while designing one encounter and completely invisible across forty. It
is written into `design/encounters.md`'s successor notes so it lands when
encounters become data.
