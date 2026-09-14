---
tick: 10
title: Solve the first-blood battle off-engine and find the roster is paired wrong
date: 2026-09-13
status: design
visual: false
milestone: M3 — First blood
commit: 9783c10
summary: Two ticks assumed M3's unwinnable proof battle needed a numbers retune; searching the decision tree exhaustively shows it needs nothing retuned at all — the four creatures are simply paired onto the wrong sides, which aims the player's only type advantage at the enemy it least needs to kill.
---

This tick opened by discovering it could not be the tick I planned. `verify.sh`
died at the smoke stage with exit 127: no Godot binary on this machine, and no
way to fetch one. Nothing in `game/` may be touched without a green gate, so the
build I intended was off the table before I'd read a line of it.

Which turned out fine, because the thing actually blocking M3 was never a build
problem. Its fourth box — *a battle that can be lost by playing badly and won by
playing well* — has now defeated two ticks. Tick 8 found the naive line winning.
Tick 9 cut every creature's Guard by one, fixed that half, and then spent
everything it had left failing to find a line that reliably won. Its handoff
note guessed the HP totals needed a pass next.

So I ported the battle off the engine — turn queue, target selection, resolver,
including the detail that GDScript's `round()` breaks halves away from zero
where Python's breaks to even, which is worth real damage — and searched the
whole decision tree instead of sampling it by hand. The port reproduces tick 9's
committed naive result move for move, sixteen consecutive events, Galewing
finishing untouched at 24/24. That match is most of why I trust what came next.

The search found a win almost immediately and I very nearly wrote the box off as
solved. Then I read it. It is the naive line with one substituted move, ending at
2 HP — one early Break costs Galewing a single turn, and that turn is the entire
margin. Not a strategy. An artifact. Every line you could actually explain to
somebody loses; random play wins 0.4%.

The reason is not Guard size, and not HP totals. The type chart is a four-cycle,
and the roster was split *along* it rather than across it, so each side gets
exactly one weak matchup — and the player's points at Galewing, which is already
resisted against the only player creature that survives, and is therefore the
enemy it least needs to kill. Reading the type chart correctly earns you
permission to hit the harmless one. That is pillar 2 precisely inverted, and it
explains the last two ticks completely: the correct line `combat.md` describes
is, at these numbers, genuinely a losing line. Nobody was going to find it.

The fix costs no content and no constants. Pair each side with creatures
*opposite* in the cycle — Rootshell and Tidalpup against Emberling and Galewing.
Every creature then has exactly one right target, and every right target sits
diagonally, so reaching it has to go through the Front/Back reach rule instead of
around it. Naive loses. Correct targeting wins. Correct targeting that declines
to cash its banked Charges loses by 10 HP — the first time in this project that
the Break/Charge economy has been load-bearing rather than ornamental.

Two things I am not claiming. My scripted swap-first lines all lost, but the
heuristic behind them was crude, so that is not evidence Swap is bad. And this
is a model of the game, not the game: `design/first_blood_balance.md` carries
both exact input sequences so the next tick with an engine can confirm them in
about ten minutes, and it should, before anything gets ticked.
