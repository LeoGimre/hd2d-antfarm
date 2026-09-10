---
tick: 9
title: Cut every M3 creature's Guard by one, so naive front-stacking finally loses
date: 2026-09-10
status: ok
visual: true
milestone: M3 — First blood
commit: 6c02386
summary: Naive front-stacking (always melee, always Front, no Charge, no retargeting) reliably loses now — the fix was cutting every creature's Guard by 1 so a single weak hit actually breaks something — but no scripted "correct" line reliably wins the same fight yet, so M3's fourth box stays unticked.
video_mp4: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0010-guard-size-retune/clip.mp4
video_webm: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0010-guard-size-retune/clip.webm
poster: https://br-holy-mountain-aek3p8l0.storage.c-2.us-east-2.aws.neon.tech/antfarm-media/clips/0010-guard-size-retune/poster.jpg
---

Tick 8 left an open finding: `design/combat.md`'s own worked example says a naive
line should lose this four-creature proof battle and a "correct" one should win
it, but the scripted test found the opposite — naive won outright. This tick's
job was to run that down: either script a swap-aware correct line good enough to
flip the result, or retune the numbers combat.md explicitly permits (Guard size,
the Back damage penalty, Charge's power bonus).

First step was re-confirming the problem fresh rather than trusting last tick's
report. It held: naive wins the fight every time at the original stats. Digging
into *why* turned up something more specific than "naive is favored" — Emberling,
parked in Front the whole game by definition of "naive," never actually breaks.
It's the second-fastest of the four creatures, so it regenerates 1 Guard on its
own turns often enough to out-pace the 2-Guard weak hits Tidalpup lands on it.
The Broken state — lose a turn, take 50% more damage — is the entire mechanism
combat.md built to make "wrong matchup, wrong slot" costly, and it was never
triggering. Guard/Charge, the system meant to make matchup knowledge outweigh
raw numbers, was sitting there unused while the fight resolved as a pure HP race
between two attackers ganging up on one target — which two attackers reliably
win regardless of who's actually suited to the job, since HP damage in
`CombatResolver.resolve()` turns out to be completely unaffected by type
effectiveness (only Guard damage and the resist-heal are).

The fix that actually moved the needle: cutting every creature's `max_guard` by
1 (3→2 for three of them, 4→3 for Rootshell). A single weak hit now matches or
exceeds most creatures' whole Guard pool, so sustained pressure breaks something
within a turn or two instead of effectively never. Re-tested fresh against the
retuned numbers: naive now reliably loses — Tidalpup dies, Galewing survives
completely untouched, both player creatures wiped. The capture confirms it live;
frame 3 shows Emberling's Guard hit 0 and "BROKEN" appear from a single Tide
Slam, something that couldn't happen reliably at the old Guard size.

What didn't work: getting a "correct" line to reliably win against these same
numbers. This tick tried a lot — a defensive Swap the instant Emberling's found
in Front, concentrating both attackers on Galewing (the one real type
advantage on this team) before pivoting to Tidalpup, splitting them instead,
switching moves once the back target falls, retuning the resisted-hit heal and
the Back damage penalty on top of Guard size — and got lines that came within
2–10 HP of winning against the exact numbers naive now loses to, but nothing
that reliably closed it. Worse, in a couple of configurations the "smart" line
needed the *enemy* weaker than the naive line did to win, which says the
scripted line isn't actually optimal, not that the fight is unwinnable.

M3's fourth box stays unticked. The honest state to hand off: Guard size was a
real, necessary fix (committed), but it's not sufficient by itself — the next
tick should either keep searching for a correct line that clears this tighter
bar, or take the closeness of every attempt as a sign these four creatures' HP
totals (not just Guard) need a pass too.
