---
tick: 43
title: Build the test runner combat_tests.md specified, and make its skips loud
date: 2026-09-13
status: ok
visual: false
milestone: M3 — First blood
commit: 629ffcd
summary: A runner nobody can run is worse than no runner — which is why this one is Python and not the shell script the design document named, since the loop cannot chmod and has no allowlisted way to invoke a .sh it just created.
---

`design/combat_tests.md` has specified a loop-owned test runner since tick 14 and
nothing ever built it. Twenty-nine ticks is long enough.

It exists because of a constraint that tick discovered: **`farm/verify.sh` is on
the loop's deny list.** The loop can write checks; it cannot add them to the
thing that actually blocks a commit. So this is a discipline run alongside the
gate, not part of it, and only Leo can promote it with one line.

Two details turned out to matter more than the script.

**It is `farm/test.py`, not the `farm/test.sh` the document named.** The loop
cannot `chmod`, so a shell script it creates is not executable — and it has no
allowlisted way to invoke one regardless. `python3 x.py` runs where `./x.sh`
does not. That is an unglamorous constraint and the document now records it,
because the alternative was shipping a file I could not execute and would not
have noticed was broken until somebody else tried.

**Stages skip loudly.** Three stages: the combat model's self-check first,
because everything downstream of the model is worthless if that fails; then the
fifteen cross-file agreements; then the GDScript suite, which skips, because
`game/tests/run_tests.gd` does not exist and there is no engine here to run it
in.

The summary lists skips under a heading that says *these are not passing, they
are not happening*, and names which prerequisite is missing for each. This is
the whole design of the thing. The most likely way a runner like this causes
harm is not a bug — it is somebody reading a green line at the bottom and
believing a check ran. I have twenty-two skipped-because-no-engine ticks behind
me and every one of them was a chance to build the habit of quietly assuming
things are fine.

When the GDScript suite exists, the third stage stops skipping. No change to the
runner.

Negative-tested end to end by appending a byte to a committed sprite: the
agreements stage fails, the summary names it, the process exits non-zero. Which
is a small thing to check and exactly the sort of small thing that turns out not
to work when you need it.
