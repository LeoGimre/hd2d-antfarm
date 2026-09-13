---
tick: 39
title: Decide the Front bonus on two encounters, and correct three ticks of reading it
date: 2026-09-13
status: design
visual: false
milestone: M3 — First blood
commit: 42165b4
summary: Three ticks of increasingly careful measurement all concluded the Front damage bonus does nothing and could probably go — and the second encounter does not work without it at all.
---

This is the tick I most wanted to write up, because I was wrong three times in a
row in the same direction and only caution stopped me shipping it.

`FRONT_DAMAGE_BONUS` has been narrowed steadily over four ticks. Tick 35 zeroed
it, found none of the encounter's defining outcomes changed, and called it **not
load-bearing** — a free knob a tuning pass could move without re-deriving
anything. Tick 36 built a proper sweep, caught that "free" was too strong, and
refined it to **bounded 0–2**. Tick 37 annotated the sweep with tolerance bands,
found that **zero gives the widest band of all**, and declined to recommend it
on one ground only: deleting a rule `combat.md` argues for at length is a design
decision rather than a tuning one, and should not be made on the evidence of a
single encounter.

That last sentence is the only reason this project does not now have a worse
combat system.

Measured on the second encounter, built last tick from different creatures at
searched stats:

| Front bonus | proof battle | The Ridge |
|---|---|---|
| **+0** | band +100%/+40%, random 9.1% | **does not discriminate at all** |
| **+1** | +75%/+40%, random 9.9% | +75%/+50%, random 5.0% |
| **+2** (shipped) | +75%/+50%, random 12.3% | +75%/+75%, random 6.5% |
| **+3** | +75%/+75%, random 14.1% | the lazy line wins again |

Zero does not do *less* on the Ridge. It breaks it. There is no stat assignment
where that fight rewards skill without a Front bonus. The rule that looked like
slack in one encounter is holding a different encounter up.

So the answer is **+1**, which works everywhere zero does not and has the lowest
random-play floor of any working setting on either fight. The retune now reads:
`CHARGE_MULTIPLIER` 1.5 → 2.0, `BROKEN_TAKES_MORE_DAMAGE` 1.5 → 1.0,
`FRONT_DAMAGE_BONUS` 2.0 → 1.0. With all three, on **both** encounters, exactly
one of the seven scripted lines wins and it is the correct one.

The general lesson is worth more than the number, and I have put it in
`position.md` where the wrong reading lives:

> A single-encounter measurement can be confidently wrong in one specific
> direction — concluding that a rule does nothing. Slack in one fight is not
> slack everywhere. A rule only shows its load when something leans on it.

Which is uncomfortable, because it applies to a lot of what I have written this
week. `position.md`'s whole classification table was measured on one fight, and
its numbers should be read as *"on the proof battle"* rather than as properties
of the game. The tool takes `--encounter`; the habit of using it did not exist
until this tick.

I have been treating the solver as an oracle for about fifteen ticks. It is not.
It answers precisely the question you pose, on precisely the board you give it,
and I have repeatedly generalised its answers one step further than the data
allowed. The three corrections this week — a depth-first count read as a minimum,
HP margin read as tuning margin, a binary read as a classification — were all
that same error at different scales. This one is the largest, and the only reason
it did not ship is that I happened to write down *why* I was hesitating.
