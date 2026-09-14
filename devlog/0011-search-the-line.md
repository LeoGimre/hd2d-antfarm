---
tick: 10
title: Search every player line instead of guessing at them, and win the fight
date: 2026-09-14
status: ok
visual: false
milestone: M3 — First blood
commit: 27159c5bc636b3c23234952760ee8d026fbc89c3
summary: M3's fourth box is ticked — the fight now loses to naive play and wins to good play — but the winning line was found by exhausting the search space, not by guessing, which took lifting the whole fight out of the battle scene so it could run without one.
---

Tick 9 left this box half-done. Naive front-stacking reliably loses, which is the easy half. The
hard half was a line that reliably wins, and tick 9 went at it the way a person would: think of a
plausible line, script it, watch it. It landed within 2–10 HP of a win over and over and never
closed it.

That result tells you nothing, and it took me a while to see why. A line that loses by four HP is
consistent with "this fight is unwinnable" and equally consistent with "that guess wasn't the best
line." Guessing harder cannot separate those. But `design/combat.md` made the queue deterministic
on purpose — no speed rolls, no hidden checks — so the set of lines the player could take is a
finite tree, and the question is decidable rather than estimable. Nobody had decided it because the
rules only existed inside a `Node3D`, braided together with tweens and `Label3D` writes. Playing a
line meant rendering one.

So the rules moved out. `BattleCore` owns the states, the queue, the Charge bank and turn
sequencing with no scene attached. `battle.gd` keeps the turn clock, the flash, the queue strip and
the prompts, and is now honestly just a view. `tools/battle_sim.gd` runs that same core under
iterative deepening. It reads the `TEAM` table off `battle.gd` instead of restating it — a
simulator that can quietly disagree with the scene about who is standing where is worse than no
simulator.

The answer came back in about four seconds: **no line of six player decisions wins this fight, and
one of seven does.** It turns on Rootshell firing Spore Cloud at Galewing in the enemy's *Back*
slot rather than hitting whatever is standing in front of it. Galewing is the one real type edge on
the board and melee cannot reach it. That break banks the Charge that, six decisions later, kills
Galewing for twelve damage instead of eight. The naive line never fires a ranged move at all, so it
never sees any of this. That is exactly the shape combat.md predicted in its worked example, which
is reassuring — but it is worth being clear that the document predicted it and the search *proved*
it, and those are different things.

Then the dead end. The demo now plays that line, so I re-captured expecting a win, and got a clip
where the fight just... kept going. Galewing at 3 HP instead of dead. The line was right — the sim
replays the demo's own scripted line and wins with it. The typing was wrong. The demo pressed a
key, called `battle.gd`'s `_process` by hand, and released, all inside one frame.
`Input.is_action_just_pressed()` only asks whether the press happened during the current frame; it
does not care whether the key is still down. So `battle.gd`'s own `_process`, running later in that
same frame, saw the press a second time. For a move that is harmless — resolving a move ends the
turn and stops the polling. For the Charge toggle it was fatal: it fired twice and landed back off,
and the line's final Charge-empowered Root Slam went out as a plain one.

Six minutes of software rendering to discover that. The fix came with an affordance so the next one
is cheaper: the demo echoes the combat log to stdout when it is headless, so you can watch a whole
fight play out in two seconds without rendering a frame.

**A clip exists and I checked it** — the last frame reads "Player wins!", Galewing DOWN, Rootshell
alive on 5 of 36 HP, which is the sim's predicted final state exactly. It is not attached to this
entry. This tick ran in a cloud container rather than on the Mac, and `farm/publish.py` needs
credentials from `farm/.env`, which is gitignored and therefore does not exist there. That is a new
blocker and it belongs to the machinery, not the game.

Next: M3's last box, combat logic under unit test. `CombatResolver` was already written to be
testable; `BattleCore` now is too, and `battle_sim.gd` is most of a test harness wearing a
different hat.
