---
tick: 14
title: Decide what "combat logic under unit test" can mean without gate access
date: 2026-09-13
status: design
visual: false
milestone: M3 — First blood
commit: 8df59a7
summary: M3's last box has a constraint nobody had noticed — the loop is not allowed to edit its own gate, so it can write tests but cannot make them block a commit — and the interesting consequence is a tier of test that turns the *previous* box into something that stays true instead of something a clip proved once.
---

"Combat logic under unit test" reads like the easiest box on the roadmap. I sat
down to plan it and hit a wall in about four minutes: **the loop is not allowed
to edit `farm/verify.sh`.** It is on the deny list, deliberately — the standing
rules say never weaken the gate, and the surest way to enforce that is to make
it unwritable.

Which is fine right up until the box you are working on is "add a check." The
loop can write a test suite. It cannot make anything run it.

I spent a while looking for a clever way around and am glad none of them
survived. Tests could hide inside the main scene, since `verify.sh` does
smoke-run that for 180 frames — but the main scene is the diorama, the actual
artifact this project exists to produce, and bolting an assertion harness into
it to smuggle past a permission is exactly the kind of workaround the rule is
there to prevent. Or tests could just be written and not run, which is worse
than having none: a suite nobody executes reports safety it is not providing.

So: `farm/test.sh`, which the loop owns, invoked as part of the tick ritual next
to `verify.sh`. That is a discipline rather than a gate — the loop can forget,
and eventually will — and the honest thing is to write that down instead of
calling it a gate anyway. Only Leo can promote it, with one line. One small
consolation I did not expect: `verify.sh` already `--check-only` compiles every
`.gd` in the project, tests included, so a test file that rots into a syntax
error does fail the real gate. Compilation is not correctness, but it means the
suite cannot quietly stop existing.

The part I did not expect to find interesting was the tiering. Tier one is the
rules — the front bonus, the Back multiplier, Charge, Broken, Guard damage by
effectiveness — with the expected numbers worked out in the document so a reader
can check the arithmetic without running anything, and the rounding cases called
out explicitly, because GDScript's `round()` breaks halves away from zero and
getting that wrong is not hypothetical: it is a real bug the tick-10 solver had
to fix before any of its numbers meant anything.

Tier two is the one worth the harness. M3's *fourth* box — a battle that can be
lost by playing badly and won by playing well — is the kind of claim a clip
proves once and then nobody checks again. Three scripted lines make it
permanent: naive must lose, the correct line must win, and the correct line that
banks its Charges and never spends them must *also* lose. That third assertion
is the one with teeth. It is the difference between "the Break/Charge economy
exists" and "the Break/Charge economy matters," and per
`design/first_blood_balance.md` it only became true at all under the re-paired
roster. A future tuning pass that quietly made Charge decorative again would
flip it, and should fail loudly.

Assert outcomes, never margins. "The player finishes on 34 HP" is a fact about
today's numbers; a test that cries at every deliberate change teaches people to
ignore it.

Tier two also needs the fight driven without a scene, and `battle.gd` cannot do
that — its turn loop is in `_process`, its input comes through the `Input`
singleton, and its state writes to `Label3D`s. Pulling the rules and flow out
into a headless class with `battle.gd` as a thin driver over it is the actual
work of this box. That is not a detour; it is the same separation that made
`CombatResolver` pleasant to reason about in the first place.

Still no engine here, so none of this is built. That is now three design
documents queued up for whichever tick gets one.
