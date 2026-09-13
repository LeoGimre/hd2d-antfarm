#!/usr/bin/env python3
"""agreements.py — check the things this project asserts must agree.

Not a test suite. `farm/verify.sh` proves the build works and
`design/combat_tests.md` plans the combat unit tests. This checks a different
class of failure: two files that must stay consistent with each other, where
neither is wrong on its own and nothing at runtime notices.

It exists because tick 28 evaluated one such assertion for the first time — the
sprite generator's baked light direction against the scenes' key lights — and it
was sixteen degrees out. That prompted checking the rest. Two more were broken:
a devlog entry citing a commit sha whose first seven characters were right and
whose tail was invented, and a missing journal line for tick 0.

Every check is cheap, dependency-free, and reads only files. Run it whenever;
it changes nothing.

    python3 farm/agreements.py
"""
import json, os, re, signal, subprocess, sys

# So `python3 farm/agreements.py | head` exits quietly instead of tracebacking.
try:
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
except (AttributeError, ValueError):
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAILS = []

print("agreements: checking what this project says must stay consistent")
print()


def check(name):
    def deco(fn):
        try:
            problems = fn() or []
        except Exception as exc:                      # a check that cannot run is a failure
            problems = ["check raised %s: %s" % (type(exc).__name__, exc)]
        if problems:
            FAILS.append(name)
            print("  \033[31mFAIL\033[0m %s" % name)
            for p in problems:
                print("         %s" % p)
        else:
            print("  \033[32mok\033[0m   %s" % name)
        return fn
    return deco


def read(*parts):
    with open(os.path.join(ROOT, *parts)) as f:
        return f.read()


def data(name, key):
    return json.loads(read("game", "data", name))[key]


# ---------------------------------------------------------------- game data

@check("every move a creature references exists, and every move is used")
def _():
    creatures = data("creatures.json", "creatures")
    moves = {m["id"] for m in data("moves.json", "moves")}
    used = {i for c in creatures for i in c["moves"]}
    out = []
    for i in sorted(used - moves):
        out.append("creature references missing move %r" % i)
    for i in sorted(moves - used):
        out.append("move %r is defined but no creature has it" % i)
    return out


@check("moves[0] is melee and moves[1] is ranged, as creatures.json claims")
def _():
    moves = {m["id"]: m for m in data("moves.json", "moves")}
    out = []
    for c in data("creatures.json", "creatures"):
        cats = [moves[i]["category"] for i in c["moves"] if i in moves]
        if cats != ["melee", "ranged"]:
            out.append("%s has %s" % (c["id"], cats))
    return out


@check("every type used by a creature or move is in the type chart")
def _():
    types = set(data("types.json", "types"))
    out = []
    for c in data("creatures.json", "creatures"):
        if c["type"] not in types:
            out.append("creature %s has unknown type %r" % (c["id"], c["type"]))
    for m in data("moves.json", "moves"):
        if m["type"] not in types:
            out.append("move %s has unknown type %r" % (m["id"], m["type"]))
    return out


@check("the type chart is a consistent cycle (X resists Y <=> Y is weak_to X)")
def _():
    types = data("types.json", "types")
    out = []
    for name, e in types.items():
        beaten = e.get("resists")
        if beaten and types.get(beaten, {}).get("weak_to") != name:
            out.append("%s resists %s, but %s.weak_to is %r"
                       % (name, beaten, beaten, types.get(beaten, {}).get("weak_to")))
    return out


# ---------------------------------------------------------------- game code

@check("battle.gd's TEAM and build_battle.gd's TEAM name the same creatures")
def _():
    grab = lambda src: dict(re.findall(r'"(\w+)":\s*\{"creature_id":\s*"(\w+)"', src))
    a = grab(read("game", "scripts", "battle.gd"))
    b = grab(read("game", "tools", "build_battle.gd"))
    if not a or not b:
        return ["could not parse a TEAM table (has it moved to data? update this check)"]
    return ["%s: battle.gd says %r, build_battle.gd says %r" % (k, a.get(k), b.get(k))
            for k in sorted(set(a) | set(b)) if a.get(k) != b.get(k)]


@check("every input action battle.gd polls is declared in input_setup.gd")
def _():
    polled = set(re.findall(r'is_action_just_pressed\("(\w+)"\)', read("game", "scripts", "battle.gd")))
    declared = set(re.findall(r'"(battle_\w+)"', read("game", "scripts", "input_setup.gd")))
    return ["battle.gd polls %r, which no autoload declares" % a
            for a in sorted(polled - declared)]


@check("the off-engine solver's constants match combat_resolver.gd")
def _():
    sys.path.insert(0, os.path.join(ROOT, "design", "proto"))
    import combat_solver as cs
    gd = read("game", "scripts", "combat_resolver.gd")
    out = []
    for name in ("FRONT_DAMAGE_BONUS", "BACK_TARGET_MULTIPLIER", "CHARGE_MULTIPLIER",
                 "BROKEN_TAKES_MORE_DAMAGE", "RESIST_HEAL"):
        m = re.search(r"^const %s\s*:=\s*([0-9.]+)" % name, gd, re.M)
        if not m:
            out.append("%s not found in combat_resolver.gd" % name)
        elif abs(float(m.group(1)) - float(getattr(cs, name))) > 1e-9:
            out.append("%s: engine %s, solver %s" % (name, m.group(1), getattr(cs, name)))
    m = re.search(r"GUARD_DAMAGE_BY_EFFECTIVENESS\s*:=\s*\{([^}]*)\}", gd)
    if m:
        gdmap = {k: int(v) for k, v in re.findall(r'"(\w+)":\s*(\d+)', m.group(1))}
        if gdmap != cs.GUARD_DAMAGE:
            out.append("guard damage: engine %s, solver %s" % (gdmap, cs.GUARD_DAMAGE))
    return out


@check("the solver still reproduces the engine result it was validated against")
def _():
    r = subprocess.run([sys.executable, os.path.join(ROOT, "design", "proto", "combat_solver.py"),
                        "--self-check"], capture_output=True, text=True)
    return [] if r.returncode == 0 else [r.stdout.strip() or "self-check failed"]


# ---------------------------------------------------------------- the record

@check("every devlog entry's commit sha resolves in this repository")
def _():
    out = []
    for f in sorted(os.listdir(os.path.join(ROOT, "devlog"))):
        if not f.endswith(".md"):
            continue
        m = re.search(r"^commit:\s*(\S+)", read("devlog", f), re.M)
        if not m:
            continue                                   # design/stuck entries may have none
        sha = m.group(1)
        if subprocess.run(["git", "-C", ROOT, "cat-file", "-e", sha + "^{commit}"],
                          capture_output=True).returncode != 0:
            out.append("%s cites %s, which is not in history" % (f, sha))
    return out


@check("devlog entries and JOURNAL.jsonl agree on ticks and slugs")
def _():
    journal = [json.loads(l) for l in read("state", "JOURNAL.jsonl").splitlines() if l.strip()]
    by_slug = {e["slug"]: e for e in journal}
    files = sorted(f[:-3] for f in os.listdir(os.path.join(ROOT, "devlog")) if f.endswith(".md"))
    out = []
    for e in journal:
        if e["slug"] not in files:
            out.append("journal tick %s names slug %r with no devlog file" % (e["tick"], e["slug"]))
    for f in files:
        tick = int(re.search(r"^tick:\s*(\d+)", read("devlog", f + ".md"), re.M).group(1))
        if f not in by_slug:
            out.append("devlog %s (tick %d) has no journal line" % (f, tick))
        elif by_slug[f]["tick"] != tick:
            out.append("%s: frontmatter tick %d, journal tick %s" % (f, tick, by_slug[f]["tick"]))
    return out


@check("design/README.md mentions every design document")
def _():
    d = os.path.join(ROOT, "design")
    readme = os.path.join(d, "README.md")
    if not os.path.exists(readme):
        return []
    guide = read("design", "README.md")
    out = []
    for f in sorted(os.listdir(d)):
        if not f.endswith(".md") or f == "README.md":
            continue
        if f not in guide:
            out.append("%s is not in the reading guide — a design index that silently "
                       "omits documents is worse than an alphabetical one" % f)
    return out


# design/hd2d_look.md: a region may vary its sky, ambient energy, key colour and
# energy, and fog. Everything else — tonemap, glow, SSAO, FOV and above all the
# key light ANGLE — is house style. The angle is baked into every creature
# sprite, so a region that moved it would light the whole roster wrong.
PERMITTED_LOOK_KEYS = {"sky", "ambient_energy", "key_color", "key_energy", "fog"}


@check("proposed regions are well formed, reciprocal, and inside the house style")
def _():
    path = os.path.join(ROOT, "design", "proto", "regions.json")
    if not os.path.exists(path):
        return []
    regions = json.load(open(path))["regions"]
    by_id = {}
    out = []
    for r in regions:
        if r["id"] in by_id:
            out.append("duplicate region id %r" % r["id"])
        by_id[r["id"]] = r

    enc_path = os.path.join(ROOT, "design", "proto", "encounters.json")
    known_encounters = set()
    if os.path.exists(enc_path):
        known_encounters = {e["id"] for e in json.load(open(enc_path))["encounters"]}

    for r in regions:
        rid = r["id"]
        for k in sorted(set(r.get("look", {})) - PERMITTED_LOOK_KEYS):
            out.append("%s: look sets %r, which is house style and not per-region "
                       "(design/hd2d_look.md)" % (rid, k))
        for state, ids in r.get("encounters", {}).items():
            for e in ids:
                if e not in known_encounters:
                    out.append("%s: %s state names unknown encounter %r" % (rid, state, e))
        for x in r.get("exits", []):
            dest = x.get("to")
            if dest not in by_id:
                out.append("%s: exit leads to unknown region %r" % (rid, dest))
                continue
            # design/regions.md: reciprocity is the thing that rots, so a
            # one-way door has to be written down rather than left as a typo.
            if x.get("one_way"):
                continue
            if not any(b.get("to") == rid for b in by_id[dest].get("exits", [])):
                out.append("%s -> %s has no way back; if that is deliberate, mark the exit "
                           "\"one_way\": true" % (rid, dest))
    return out


@check("proposed encounters are well formed and can produce a tactical fight")
def _():
    path = os.path.join(ROOT, "design", "proto", "encounters.json")
    if not os.path.exists(path):
        return []
    encounters = json.load(open(path))["encounters"]
    creatures = {c["id"]: c for c in json.loads(read("game", "data", "creatures.json"))["creatures"]}
    proposed = os.path.join(ROOT, "design", "proto", "proposed_creatures.json")
    if os.path.exists(proposed):
        for c in json.load(open(proposed))["creatures"]:
            creatures.setdefault(c["id"], c)
    types = json.loads(read("game", "data", "types.json"))["types"]

    def guard_damage(att, dfn):
        e = types.get(creatures[dfn]["type"], {})
        at = creatures[att]["type"]
        return 2 if e.get("weak_to") == at else (0 if e.get("resists") == at else 1)

    out, seen_ids = [], set()
    for e in encounters:
        eid = e.get("id", "<no id>")
        if eid in seen_ids:
            out.append("duplicate encounter id %r" % eid)
        seen_ids.add(eid)
        for side in ("player", "enemy"):
            members = e.get(side, [])
            slots = sorted(m.get("slot") for m in members)
            if slots != ["back", "front"]:
                out.append("%s: %s side has slots %s, expected exactly one front and one back"
                           % (eid, side, slots))
            for m in members:
                if m.get("creature") not in creatures:
                    out.append("%s: %s names unknown creature %r" % (eid, side, m.get("creature")))
        if e.get("counter_example"):
            continue                                   # deliberately not a valid fight
        if any(m.get("creature") not in creatures
               for side in ("player", "enemy") for m in e.get(side, [])):
            continue                                   # already reported above
        # design/second_encounter.md: a creature whose attacks are resisted by
        # everything opposite it does zero Guard damage, so it can never break,
        # never bank a Charge, and is absent from the economy the fight is about.
        for side, other in (("player", "enemy"), ("enemy", "player")):
            for m in e[side]:
                if not any(guard_damage(m["creature"], o["creature"]) > 0 for o in e[other]):
                    out.append("%s: %s cannot do Guard damage to anything on the other side — "
                               "it is absent from the Charge economy and the fight cannot "
                               "discriminate skill (see design/second_encounter.md)"
                               % (eid, m["creature"]))
    return out


@check("the generated combat test fixtures are current")
def _():
    gen = os.path.join(ROOT, "design", "proto", "gen_test_cases.py")
    if not os.path.exists(gen):
        return []
    r = subprocess.run([sys.executable, gen, "--check"], capture_output=True, text=True)
    return [] if r.returncode == 0 else [r.stdout.strip() or "fixtures are stale"]


@check("proposed creature stats name creatures that exist in the roster")
def _():
    path = os.path.join(ROOT, "design", "proto", "proposed_creatures.json")
    if not os.path.exists(path):
        return []
    proposed = json.load(open(path))["creatures"]
    roster = read("design", "roster.md")
    types = set(json.loads(read("game", "data", "types.json"))["types"])
    moves = {m["id"] for m in json.loads(read("game", "data", "moves.json"))["moves"]}
    live = {c["id"] for c in json.loads(read("game", "data", "creatures.json"))["creatures"]}
    out = []
    for c in proposed:
        if ("**%s**" % c["display_name"]) not in roster:
            out.append("%r is statted but not in design/roster.md" % c["id"])
        if c["id"] in live:
            out.append("%r is in game/data now — remove it from the proposal" % c["id"])
        if c["type"] not in types:
            out.append("%r has unknown type %r" % (c["id"], c["type"]))
        for m in c["moves"]:
            if m not in moves:
                out.append("%r references missing move %r" % (c["id"], m))
    return out


@check("the committed sprite PNGs still match what the generator produces")
def _():
    import shutil, tempfile
    src = os.path.join(ROOT, "design", "proto", "sprites")
    if not os.path.isdir(src):
        return []                                      # nothing committed yet
    tmp = tempfile.mkdtemp(prefix="agreements-sprites-")
    try:
        env = dict(os.environ, FORGE_OUT=tmp)
        r = subprocess.run([sys.executable,
                            os.path.join(ROOT, "design", "proto", "creature_forge.py")],
                           capture_output=True, text=True, env=env)
        if r.returncode != 0:
            return ["the generator failed: %s" % (r.stderr.strip().splitlines() or [""])[-1]]
        out = []
        # "_" files (the contact sheet) are produced only with --sheet; ignore them.
        committed = {f for f in os.listdir(src) if f.endswith(".png") and not f.startswith("_")}
        produced = {f for f in os.listdir(tmp) if f.endswith(".png") and not f.startswith("_")}
        for f in sorted(committed - produced):
            out.append("%s is committed but the generator no longer produces it" % f)
        for f in sorted(produced - committed):
            out.append("%s is produced but not committed (site/ will 404 on it)" % f)
        for f in sorted(committed & produced):
            if open(os.path.join(src, f), "rb").read() != open(os.path.join(tmp, f), "rb").read():
                out.append("%s differs from the generator's output — regenerate with "
                           "FORGE_OUT=design/proto/sprites" % f)
        return out
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


@check("design/roster.md and the sprite generator list the same creatures")
def _():
    sys.path.insert(0, os.path.join(ROOT, "design", "proto"))
    import creature_forge as cf
    ids = {c[0] for c in cf.ROSTER}
    named = {m.lower() for m in re.findall(r"\*\*([A-Z][a-z]+)\*\*", read("design", "roster.md"))}
    return (["%r is in the generator but not roster.md" % i for i in sorted(ids - named)]
            + ["%r is in roster.md but not the generator" % i for i in sorted(named - ids)])


if __name__ == "__main__":
    # Every check runs at import time, via its decorator, so by the time this
    # executes the results are already on screen and FAILS is populated.
    print()
    if FAILS:
        print("agreements: %d FAILED — %s" % (len(FAILS), ", ".join(FAILS)))
        sys.exit(1)
    print("agreements: all consistent")
