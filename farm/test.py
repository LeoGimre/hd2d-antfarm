#!/usr/bin/env python3
"""test.py — everything this project can check, in one command.

    python3 farm/test.py

design/combat_tests.md establishes why this exists: farm/verify.sh is on the
loop's deny list, so the loop can write checks but cannot add them to the thing
that blocks a commit. This is the loop-owned runner it specifies. It is a
discipline rather than a gate — run it alongside verify.sh — and only Leo can
promote it, with one line in verify.sh.

It is Python rather than the shell script that document names, for a dull
reason worth writing down: the loop cannot chmod, so a new .sh file it creates
is not executable and it has no allowlisted way to run one. `python3 x.py` works
where `./x.sh` does not. A runner nobody can run is worse than no runner.

Stages skip loudly rather than silently. A skipped stage is a check that is not
happening, and the output says so every time.
"""
import glob, os, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GREEN, RED, DIM, OFF = "\033[32m", "\033[31m", "\033[2m", "\033[0m"

failed, skipped = [], []


def stage(name, argv, cwd=ROOT):
    print("%s· %s%s" % (DIM, name, OFF))
    r = subprocess.run(argv, cwd=cwd, capture_output=True, text=True)
    body = (r.stdout or "") + (r.stderr or "")
    for line in body.rstrip().splitlines():
        print("    " + line)
    if r.returncode != 0:
        failed.append(name)
    print("  %s%s%s %s" % (GREEN if r.returncode == 0 else RED,
                           "pass" if r.returncode == 0 else "FAIL", OFF, name))
    print()
    return r.returncode == 0


def skip(name, why):
    skipped.append(name)
    print("%s· %s%s" % (DIM, name, OFF))
    print("  %s—%s %s %s(%s)%s" % (DIM, OFF, "skipped", DIM, why, OFF))
    print()


def godot_binary():
    """verify.sh's convention, plus the cloud container's, plus PATH.

    .claude/hooks/session-start.sh installs into /opt/godot/<version>/ and
    exports GODOT_BIN into the session environment — but only at session start,
    so a session that predates the hook (or runs this script from somewhere the
    export did not reach) has the engine on disk and no variable pointing at it.
    Looking is cheaper than skipping a whole stage, and a skipped stage is a
    check that is not happening."""
    for cand in _candidates():
        if cand and os.path.exists(cand) and os.access(cand, os.X_OK):
            return cand
    return shutil.which("godot")


def _candidates():
    yield os.environ.get("GODOT_BIN")
    yield "/Applications/Godot.app/Contents/MacOS/Godot"
    for d in sorted(glob.glob("/opt/godot/*"), reverse=True):
        yield from sorted(glob.glob(os.path.join(d, "Godot_v*_linux.x86_64")))


def main():
    print()
    print("test.py — the checks the loop owns. verify.sh is the gate; this is not.")
    print()

    solver = os.path.join(ROOT, "design", "proto", "combat_solver.py")
    if os.path.exists(solver):
        stage("combat model still matches the engine result it was validated against",
              [sys.executable, solver, "--self-check"])
    else:
        skip("combat model self-check", "design/proto/combat_solver.py is missing")

    agreements = os.path.join(ROOT, "farm", "agreements.py")
    if os.path.exists(agreements):
        stage("cross-file agreements", [sys.executable, agreements])
    else:
        skip("cross-file agreements", "farm/agreements.py is missing")

    # The GDScript suite design/combat_tests.md plans. Two things have to exist:
    # the tests, and an engine to run them in. Both do as of tick 57 — but the
    # skips stay, because a Mac with no cloud hook and a container whose hook
    # has not run are both real, and the message has to say which is missing
    # rather than report a pass.
    runner = os.path.join(ROOT, "game", "tests", "run_tests.gd")
    godot = godot_binary()
    if not os.path.exists(runner):
        skip("combat logic under unit test (M3's fifth box)",
             "game/tests/run_tests.gd does not exist yet — "
             "design/proto/combat_cases.json holds the cases it should walk")
    elif not godot:
        skip("combat logic under unit test (M3's fifth box)",
             "no Godot binary; set GODOT_BIN")
    else:
        stage("combat logic under unit test",
              [godot, "--headless", "--path", os.path.join(ROOT, "game"),
               "--script", "res://tests/run_tests.gd"])

    print("-" * 68)
    if failed:
        print("%sFAILED%s: %s" % (RED, OFF, ", ".join(failed)))
    else:
        print("%sall runnable checks pass%s" % (GREEN, OFF))
    if skipped:
        print("%sskipped (these are not passing, they are not happening):%s" % (DIM, OFF))
        for s in skipped:
            print("   - %s" % s)
    print()
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
