---
tick: 35
title: Audit the positional rules, and find their importance inverts their emphasis
date: 2026-09-13
status: design
visual: false
milestone: M3 — First blood
commit: b9ea297
summary: The positional rule combat.md justifies at greatest length turns out to change none of the encounter's defining outcomes, while the one it gives two sentences is the rule the entire board rests on — remove it and the fight becomes unwinnable.
---

Last tick's Swap finding rested on a fact nobody had written down: **Front is
where every melee attack lands, from both enemies.** That is a consequence of one
of `combat.md`'s three positional rules, and once it was stated the obvious
follow-up was which of the three is actually holding the fight up.

So I removed each in turn and re-ran the battery. The three assertions that
define this encounter are: naive play must lose, correct play must win, and
correct play that hoards its Charges must *also* lose — that third one being what
separates "the Break/Charge economy matters" from "the Break/Charge economy
exists."

| removed | naive | correct | hoards Charges | random | |
|---|---|---|---|---|---|
| nothing | loses | wins | loses | 13.0% | works |
| the Front damage bonus | loses | wins | loses | 10.3% | **still works** |
| the Back damage penalty | loses | wins | *wins* | 12.4% | **broken** |
| melee's Front-only reach | loses | *loses* | loses | 0.7% | **broken** |

**Melee-locked-to-Front is structural, and it got two sentences.** Remove it and
the fight is not unbalanced, it is unwinnable — correct play loses and random
play collapses to 0.7%. With both enemies able to reach either slot, and the
enemy AI already preferring Back with its ranged attacks, Back becomes the *most*
dangerous place to stand and there is nowhere left to put anything. The entire
board rests on this one rule.

**The Back penalty is what keeps the Charge economy honest**, which is not what
it says on the tin. `combat.md` frames the 25% discount as a safety mechanism —
*"Back is safer, not safe."* Measured, its real job is on the other side of the
board: it stops sniping the enemy Back slot from being sufficient by itself.
Remove it and correct targeting wins without ever spending a Charge, and the one
assertion that makes Break/Charge load-bearing flips.

**And the Front damage bonus does none of the above.** It has the longest
justification in the section — *"front-line pressure is rewarded, so the choice
to advance or protect a unit is a real trade, not a strictly-better move"* — and
zeroing it changes not one of the three outcomes. It moves random play by three
points, so it does *something*. But the argument it was given is not what makes
this fight work.

I have written that finding down carefully rather than as a recommendation to
delete it, because "not load-bearing for three binary outcomes in one encounter"
is a much narrower claim than "useless," and I have already been burned twice
this week by treating a measurement as bigger than it was.

The useful half is what it lets a future tick do. `progression.md` established
that Guard must never grow, because it is a discrete gate and not a stat. This
adds two more entries to that list: **the melee reach rule and the Back
multiplier are structural**, and changing either invalidates every balance result
in three documents, all of which were measured on top of them. The Front bonus,
by contrast, is a **free knob** — move it without re-deriving anything.

Before this tick every constant in `combat_resolver.gd` looked equally
adjustable. Two of them are load-bearing walls and one is a picture hook, and
nothing in the file said which was which.
