#!/usr/bin/env python3
"""combat_solver — an off-engine model of the M3 battle, for balance questions.

A design artifact, not shipped game code, and it lives in design/ for the same
reason design/proto/creature_forge.py does: it is the *evidence* behind several
design documents rather than part of the build.

It has earned its place four times now. It found that the committed proof battle
was unwinnable by any explainable plan and that the cause was the roster being
paired onto the wrong sides (design/first_blood_balance.md). It killed two
versions of the capture rule — one that made fast creatures uncapturable rather
than hard, one where a capture financed itself (design/capture.md). And it
measured how much stat advantage pillar 2 survives, which turned out to be about
five percent (design/progression.md). Every one of those was a surprise, and
none of them was reachable by reasoning carefully in prose.

WHAT IT IS: a faithful port of TurnQueue.advance(), battle.gd's turn loop and
_pick_target(), and CombatResolver.resolve()/apply(). It is a model of the game,
not the game. `--self-check` proves it still reproduces a committed engine
result; when that fails, this file is wrong until shown otherwise.

    python3 design/proto/combat_solver.py --self-check
    python3 design/proto/combat_solver.py lines
    python3 design/proto/combat_solver.py trace typed
    python3 design/proto/combat_solver.py search
    python3 design/proto/combat_solver.py tolerance
    python3 design/proto/combat_solver.py capture

Add --encounter current to run against the roster as committed in game/data
rather than the re-paired one design/first_blood_balance.md prescribes.
"""
import argparse, copy, json, math, os, random, sys

GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "game")

def _load(name, key):
    with open(os.path.join(GAME, "data", name)) as f:
        return json.load(f)[key]

BASE_CREATURES = {c["id"]: c for c in _load("creatures.json", "creatures")}
MOVES = {m["id"]: m for m in _load("moves.json", "moves")}
TYPES = _load("types.json", "types")
# Stats for creatures that exist in design/roster.md but have not reached
# game/data yet. Merged over the real data so a proposed encounter is
# reproducible; see design/second_encounter.md for how they were arrived at.
PROPOSED_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             "proposed_creatures.json")
if os.path.exists(PROPOSED_PATH):
    with open(PROPOSED_PATH) as _f:
        for _c in json.load(_f)["creatures"]:
            BASE_CREATURES.setdefault(_c["id"], _c)

CREATURES = copy.deepcopy(BASE_CREATURES)

# CombatResolver's constants, mirrored.
# Overridable so combat.md's positional claims can be tested by removing them:
# "Front deals slightly more damage ... so the choice to advance or protect a
# unit is a real trade, not a strictly-better move", and "Back is safer, not
# safe". A constant that changes no outcome when deleted is not load-bearing.
FRONT_DAMAGE_BONUS = float(os.environ.get("FRONT_BONUS", "2.0"))
BACK_TARGET_MULTIPLIER = float(os.environ.get("BACK_MULT", "0.75"))
CHARGE_MULTIPLIER = 1.5
BROKEN_TAKES_MORE_DAMAGE = 1.5
RESIST_HEAL = 2
GUARD_DAMAGE = {"weak": 2, "neutral": 1, "resist": 0}

# design/capture.md: Seen persists for the battle; Offer costs two banked
# Charges. Both are set here so the rejected variants in that document stay
# reproducible rather than being numbers from a scratch file nobody has.
OFFER_COST = int(os.environ.get("OFFER_COST", "2"))
# "window": the offer must land while the target is still Broken, and only on
# its first break. "persist": one break marks it Seen for the rest of the fight.
SEEN_MODE = os.environ.get("SEEN_MODE", "persist")

TALLY = {}

KEYS = ["PlayerFront", "PlayerBack", "EnemyFront", "EnemyBack"]

ENCOUNTERS = {
    # What game/data + battle.gd's TEAM currently ship. Unwinnable by any
    # explainable plan -- see design/first_blood_balance.md.
    "current": [("emberling", "player", "front"), ("rootshell", "player", "back"),
                ("tidalpup", "enemy", "front"), ("galewing", "enemy", "back")],
    # The re-pairing that document prescribes. Every correct target is diagonal.
    "repaired": [("rootshell", "player", "front"), ("tidalpup", "player", "back"),
                 ("emberling", "enemy", "front"), ("galewing", "enemy", "back")],
    # The Ridge, proposed in design/second_encounter.md. Diagonal like the one
    # above, and deliberately built from different creatures at different stats
    # to test whether that requirement is structural or a quirk of the first four.
    "ridge": [("rootshell", "player", "front"), ("tidalpup", "player", "back"),
              ("ashmoth", "enemy", "front"), ("ridgewalk", "enemy", "back")],
}
TEAM = ENCOUNTERS["repaired"]


def gd_round(x):
    """GDScript round() breaks halves away from zero; Python's breaks to even.
    int(round(4.5)) is 5 in the engine and 4 here. That single difference moves
    real damage numbers, and getting it wrong invalidated an early version of
    this file."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def effectiveness(atype, dtype):
    e = TYPES.get(dtype, {})
    if e.get("weak_to") == atype:
        return "weak"
    if e.get("resists") == atype:
        return "resist"
    return "neutral"


def side_of(i):
    return "player" if i < 2 else "enemy"


# ---------------------------------------------------------------- state
# combatant: (cid, slot, hp, guard, broken, defeated, next_is_melee)
# queue:     (speed, scheduled_time)
# state:     (c0..c3, player_charge, enemy_charge, q0..q3, seen0..3, taken0..3)

def initial():
    cs, qs = [], []
    for cid, _side, slot in TEAM:
        d = CREATURES[cid]
        cs.append((cid, slot, d["max_hp"], d["max_guard"], False, False, True))
        qs.append((float(d["speed"]), 1000.0 / d["speed"]))
    return tuple(cs) + (0, 0) + tuple(qs) + (0, 0, 0, 0) + (0, 0, 0, 0)


def unpack(s):
    return list(s[0:4]), s[4], s[5], list(s[6:10]), list(s[10:14]), list(s[14:18])


def pack(cs, pc, ec, qs, seen, taken):
    return tuple(cs) + (pc, ec) + tuple(qs) + tuple(seen) + tuple(taken)


def normalize(s):
    """Schedule times drift upward forever; only their offsets matter."""
    cs, pc, ec, qs, seen, taken = unpack(s)
    base = min(q[1] for q in qs)
    return pack(cs, pc, ec, [(q[0], round(q[1] - base, 6)) for q in qs], seen, taken)


def winner(s):
    cs, _pc, _ec, _qs, _seen, taken = unpack(s)
    gone = lambda side: all(cs[i][5] or taken[i] for i in range(4) if side_of(i) == side)
    if gone("enemy"):
        return "player"
    if gone("player"):
        return "enemy"
    return None


def hp_left(s):
    cs = s[0:4]
    return sum(c[2] for c in cs[0:2]), sum(c[2] for c in cs[2:4])


# ---------------------------------------------------------------- rules

def advance(qs):
    """TurnQueue.advance(): strict < means ties go to the earliest array index."""
    best = 0
    for i in range(1, 4):
        if qs[i][1] < qs[best][1]:
            best = i
    speed, sched = qs[best]
    qs[best] = (speed, sched + 1000.0 / speed)
    return best


# MELEE_REACH=any removes combat.md's central reach rule, so its contribution
# can be measured rather than assumed.
MELEE_REACH = os.environ.get("MELEE_REACH", "front")
# Guard regenerates by this much at the start of its owner's own turn.
GUARD_REGEN = int(os.environ.get("GUARD_REGEN", "1"))


def pick_target(cs, taken, ai, move):
    """battle.gd._pick_target. Melee reaches Front, or Back once Front falls;
    the enemy AI aims ranged at Back on purpose."""
    front, back = (2, 3) if side_of(ai) == "player" else (0, 1)
    live = lambda i: not cs[i][5] and not taken[i]
    if move["category"] == "melee":
        if MELEE_REACH == "any":
            return back if live(back) else (front if live(front) else None)
        return front if live(front) else (back if live(back) else None)
    return back if live(back) else (front if live(front) else None)


def resolve_and_apply(cs, pc, ec, seen, ai, di, move, charge):
    attacker, defender = cs[ai], cs[di]
    eff = effectiveness(CREATURES[attacker[0]]["type"], CREATURES[defender[0]]["type"])

    dmg = float(move["power"])
    if attacker[1] == "front":
        dmg += FRONT_DAMAGE_BONUS
    if move["category"] == "ranged" and defender[1] == "back":
        dmg *= BACK_TARGET_MULTIPLIER
    if charge:
        dmg *= CHARGE_MULTIPLIER
    if defender[4]:
        dmg *= BROKEN_TAKES_MORE_DAMAGE
    hp_damage = gd_round(dmg)

    gdmg = GUARD_DAMAGE[eff]
    heal = RESIST_HEAL if eff == "resist" else 0
    breaks = (not defender[4]) and defender[3] > 0 and gdmg >= defender[3]

    if charge:
        if side_of(ai) == "player":
            pc -= 1
        else:
            ec -= 1

    cid, slot, hp, guard, broken, dead, nm = defender
    guard = max(0, guard - gdmg)
    if breaks:
        broken = True
        seen[di] += 1
    hp = max(0, min(CREATURES[cid]["max_hp"], hp - hp_damage + heal))
    if hp <= 0:
        dead = True
    cs[di] = (cid, slot, hp, guard, broken, dead, nm)

    if breaks:
        if side_of(ai) == "player":
            pc += 1
        else:
            ec += 1
    # Where damage lands, for the positional audit. Keyed by the *defender's*
    # side and slot at the moment of the hit.
    TALLY[(side_of(di), defender[1])] = TALLY.get((side_of(di), defender[1]), 0) + hp_damage
    return pc, ec, (eff, hp_damage, gdmg, breaks, charge)


def next_move(cs, i):
    cid, slot, hp, guard, broken, dead, nm = cs[i]
    cs[i] = (cid, slot, hp, guard, broken, dead, not nm)
    return MOVES[CREATURES[cid]["moves"][0 if nm else 1]]


def describe(cs, ai, di, move, info):
    eff, hp_damage, gdmg, breaks, charged = info
    return "%-10s %-12s -> %-10s %-8s -%2d HP -%d Guard%s%s  [%s hp=%d guard=%d]" % (
        CREATURES[cs[ai][0]]["display_name"], move["display_name"],
        CREATURES[cs[di][0]]["display_name"], eff, hp_damage, gdmg,
        " CHARGE" if charged else "", " BREAK" if breaks else "",
        CREATURES[cs[di][0]]["display_name"], cs[di][2], cs[di][3])


def run_to_player_choice(s, log=None, limit=400):
    """battle.gd._take_turn: Guard regen -> defeated -> Broken -> act. Returns
    (state, actor_index) or (state, None) when the battle is over."""
    cs, pc, ec, qs, seen, taken = unpack(s)
    for _ in range(limit):
        if winner(pack(cs, pc, ec, qs, seen, taken)):
            break
        i = advance(qs)
        cid, slot, hp, guard, broken, dead, nm = cs[i]
        guard = min(CREATURES[cid]["max_guard"], guard + GUARD_REGEN)
        cs[i] = (cid, slot, hp, guard, broken, dead, nm)
        if dead or taken[i]:
            continue
        if broken:
            cs[i] = (cid, slot, hp, guard, False, dead, nm)
            if log is not None:
                log.append("%s is Broken and loses this turn." % CREATURES[cid]["display_name"])
            continue
        if side_of(i) == "player":
            return pack(cs, pc, ec, qs, seen, taken), i
        move = next_move(cs, i)
        di = pick_target(cs, taken, i, move)
        if di is None:
            continue
        pc, ec, info = resolve_and_apply(cs, pc, ec, seen, i, di, move, ec > 0)
        if log is not None:
            log.append(describe(cs, i, di, move, info))
    return pack(cs, pc, ec, qs, seen, taken), None


def offer_ok(s, ti):
    cs, pc, _ec, _qs, seen, taken = unpack(s)
    if pc < OFFER_COST or cs[ti][5] or taken[ti]:
        return False
    if SEEN_MODE == "window":
        return cs[ti][4] and seen[ti] == 1
    return seen[ti] >= 1


def apply_choice(s, i, choice, log=None):
    """choice: ("melee", charge) | ("ranged", "front"|"back", charge)
               | ("swap",) | ("offer", target_index)"""
    cs, pc, ec, qs, seen, taken = unpack(s)

    if choice[0] == "offer":
        ti = choice[1]
        if not offer_ok(s, ti):
            return None
        pc -= OFFER_COST
        taken[ti] = 1
        if log is not None:
            log.append("%s accepts the offer and joins. (%d Charge spent)"
                       % (CREATURES[cs[ti][0]]["display_name"], OFFER_COST))
        return pack(cs, pc, ec, qs, seen, taken)

    if choice[0] == "swap":
        partner = 1 if i == 0 else 0
        a, b = cs[i], cs[partner]
        a2 = (a[0], b[1], a[2], a[3], a[4], a[5], a[6])
        b2 = (b[0], a[1], b[2], b[3], b[4], b[5], b[6])
        cs[i], cs[partner] = b2, a2
        seen[i], seen[partner] = seen[partner], seen[i]
        taken[i], taken[partner] = taken[partner], taken[i]
        # TurnQueue.rename: the slot keeps its schedule, inherits the new speed.
        qs[i] = (float(CREATURES[b2[0]]["speed"]), qs[i][1])
        qs[partner] = (float(CREATURES[a2[0]]["speed"]), qs[partner][1])
        if SWAP_MODE == "guard":
            # The swapped-in creature arrives composed.
            cid, slot, hp, guard, broken, dead, nm = cs[i]
            cs[i] = (cid, slot, hp, CREATURES[cid]["max_guard"], broken, dead, nm)
        if log is not None:
            log.append("%s swaps to %s, %s steps up to %s." % (
                CREATURES[a2[0]]["display_name"], a2[1],
                CREATURES[b2[0]]["display_name"], b2[1]))
        return pack(cs, pc, ec, qs, seen, taken)

    cid = cs[i][0]
    if choice[0] == "melee":
        move = MOVES[CREATURES[cid]["moves"][0]]
        charge = choice[1] and pc > 0
        di = pick_target(cs, taken, i, move)
        if di is None:
            return pack(cs, pc, ec, qs, seen, taken)
    else:
        move = MOVES[CREATURES[cid]["moves"][1]]
        charge = choice[2] and pc > 0
        di = 2 if choice[1] == "front" else 3
        if cs[di][5] or taken[di]:
            return None  # battle.gd would simply keep waiting; not a legal line
    pc, ec, info = resolve_and_apply(cs, pc, ec, seen, i, di, move, charge)
    if log is not None:
        log.append(describe(cs, i, di, move, info))
    return pack(cs, pc, ec, qs, seen, taken)


# Capture arrived (design/capture.md) after the balance work in
# design/first_blood_balance.md was measured, and an available Offer changes
# what random play can stumble into. --no-capture reproduces the earlier rule
# set so the two sets of numbers can be compared honestly.
NO_OFFERS = os.environ.get("NO_OFFERS") == "1"
# design/combat.md prices Swap at a full turn, and no search has ever used one.
# NO_SWAP removes the action so its contribution can be measured; SWAP_MODE
# tries the repricings that document says are the ones to retune.
#   "full"   -- a whole action, as specified
#   "guard"  -- a whole action that also restores the swapped-in creature's Guard
#   "free"   -- costs no turn: the creature swaps and still acts
NO_SWAP = os.environ.get("NO_SWAP") == "1"
SWAP_MODE = os.environ.get("SWAP_MODE", "full")


def legal_choices(s, i):
    cs, pc, _ec, _qs, _seen, taken = unpack(s)
    out = []
    for ti in (2, 3):
        if not NO_OFFERS and offer_ok(s, ti):
            out.append(("offer", ti))
    for ch in ([False, True] if pc > 0 else [False]):
        out.append(("melee", ch))
        for tag, ti in (("front", 2), ("back", 3)):
            if not cs[ti][5] and not taken[ti]:
                out.append(("ranged", tag, ch))
    if not NO_SWAP:
        out.append(("swap",))
    return out


# ---------------------------------------------------------------- policies

def _eff_between(att_cid, def_cid):
    return effectiveness(CREATURES[att_cid]["type"], CREATURES[def_cid]["type"])


def naive(s, i, n):
    """Melee every turn, never Charge, never retarget. Must lose."""
    return ("melee", False)


def melee_charge(s, i, n):
    return ("melee", s[4] > 0)


def snipe_back(s, i, n):
    cs, _pc, _ec, _qs, _seen, taken = unpack(s)
    if not cs[3][5] and not taken[3]:
        return ("ranged", "back", s[4] > 0)
    return ("melee", s[4] > 0)


def anti_typed(s, i, n):
    """Attack whoever resists you -- the wrong read, deliberately."""
    cs, _pc, _ec, _qs, _seen, taken = unpack(s)
    me = cs[i][0]
    for ti, tag in ((2, "front"), (3, "back")):
        if cs[ti][5] or taken[ti]:
            continue
        if _eff_between(me, cs[ti][0]) == "resist":
            return ("melee", False) if tag == "front" else ("ranged", "back", False)
    return ("melee", False)


def typed(s, i, n):
    """Hit whoever your type beats, reaching the Back slot with your ranged
    move when that is where it stands. Spend a Charge whenever there is one."""
    cs, pc, _ec, _qs, _seen, taken = unpack(s)
    me = cs[i][0]
    ch = pc > 0
    for ti, tag in ((2, "front"), (3, "back")):
        if cs[ti][5] or taken[ti]:
            continue
        if _eff_between(me, cs[ti][0]) == "weak":
            return ("melee", ch) if tag == "front" else ("ranged", "back", ch)
    if not cs[2][5] and not taken[2]:
        return ("melee", ch)
    return ("ranged", "back", ch)


def typed_hoard(s, i, n):
    """Correct targeting that never spends a Charge. Isolates whether the
    Break/Charge economy is load-bearing or ornamental."""
    c = typed(s, i, n)
    return (c[0], False) if len(c) == 2 else (c[0], c[1], False)


def typed_swap(s, i, n):
    """typed, but open by swapping the player's pair.

    Exists because "is Swap on the shortest winning line" is the wrong question:
    the search minimises decisions, so it will never pay a turn for durability
    it does not strictly need. This measures the other thing — whether Swap buys
    margin — by spending the turn up front and then playing correctly."""
    if n == 0:
        return ("swap",)
    return typed(s, i, n - 1)


POLICIES = {
    "naive": (naive, "always melee, never Charge"),
    "melee_charge": (melee_charge, "always melee, always spend Charge"),
    "snipe_back": (snipe_back, "always attack the Back slot"),
    "anti_typed": (anti_typed, "attack whoever resists you"),
    "typed": (typed, "attack whoever you are strong against, spend Charge"),
    "typed_hoard": (typed_hoard, "correct targeting, never spends a Charge"),
    "typed_swap": (typed_swap, "open with a Swap, then correct targeting"),
}


def play(policy, log=None, limit=300):
    s = initial()
    n = 0
    while n < limit:
        s, i = run_to_player_choice(s, log)
        if i is None:
            break
        ns = apply_choice(s, i, policy(s, i, n), log)
        if ns is None:
            ns = apply_choice(s, i, ("melee", False), log)
        if ns is None:
            break
        s = ns
        n += 1
    return winner(s), s, n


def random_rate(trials=2000, seed=7):
    rnd = random.Random(seed)
    wins = 0
    for _ in range(trials):
        w, _s, _n = play(lambda s, i, n: rnd.choice(legal_choices(s, i)))
        wins += (w == "player")
    return wins / trials


# ---------------------------------------------------------------- searches

def search_win(maxdepth=20):
    """Shortest forcing win, by iterative deepening. Plain depth-first search
    returns *a* line rather than the shortest, and its length then depends on
    the order legal_choices() happens to list moves in — which is not a fact
    about the game. Any decision count this file prints is a minimum."""
    memo = {}

    def rec(s, depth):
        s, i = run_to_player_choice(s)
        w = winner(s)
        if w is not None:
            return [] if w == "player" else None
        if i is None or depth >= maxdepth:
            return None
        key = (normalize(s), i, maxdepth - depth)
        if key in memo:
            return memo[key]
        best = None
        for c in legal_choices(s, i):
            ns = apply_choice(s, i, c)
            if ns is None:
                continue
            r = rec(ns, depth + 1)
            if r is not None:
                best = [(CREATURES[s[i][0]]["display_name"], c)] + r
                break
        memo[key] = best
        return best

    return rec(initial(), 0), len(memo)


def _deepen(searcher, maxdepth):
    """Shortest-first: ask for depth 1, then 2, ... so the first hit is minimal."""
    total = 0
    for d in range(1, maxdepth + 1):
        line, nodes = searcher(d)
        total += nodes
        if line is not None:
            return line, total
    return None, total


def search_capture(target_index, require_win=False, maxdepth=18):
    memo = {}

    def rec(s, depth):
        s, i = run_to_player_choice(s)
        _cs, _pc, _ec, _qs, _seen, taken = unpack(s)
        w = winner(s)
        if taken[target_index] and (w == "player" if require_win else True):
            return []
        if w is not None or i is None or depth >= maxdepth:
            return None
        key = (normalize(s), i, maxdepth - depth)
        if key in memo:
            return memo[key]
        best = None
        for c in legal_choices(s, i):
            ns = apply_choice(s, i, c)
            if ns is None:
                continue
            r = rec(ns, depth + 1)
            if r is not None:
                best = [(CREATURES[s[i][0]]["display_name"], c)] + r
                break
        memo[key] = best
        return best

    return rec(initial(), 0), len(memo)


def tolerance():
    """The number design/progression.md says actually measures an encounter's
    balance: how far each side can be moved before the outcome flips. HP
    remaining is not that number and has misled two ticks."""
    global CREATURES
    base = copy.deepcopy(CREATURES)
    player_ids = [cid for cid, side, _slot in TEAM if side == "player"]
    enemy_ids = [cid for cid, side, _slot in TEAM if side == "enemy"]
    rows = []

    def scaled(ids, **kw):
        global CREATURES
        CREATURES = copy.deepcopy(base)
        for cid in ids:
            c = CREATURES[cid]
            c["max_hp"] = int(round(c["max_hp"] * kw.get("hp", 1.0)))
            c["speed"] = c["speed"] * kw.get("speed", 1.0)
            c["max_guard"] = c["max_guard"] + kw.get("guard", 0)

    for m in (1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.50, 2.00):
        scaled(player_ids, hp=m)
        rows.append(("player HP x%.2f" % m, play(naive)[0], play(typed)[0]))
    for g in (1, 2):
        scaled(player_ids, guard=g)
        rows.append(("player Guard +%d" % g, play(naive)[0], play(typed)[0]))
    for m in (1.10, 1.15, 1.20, 1.25):
        scaled(enemy_ids, hp=m)
        rows.append(("enemy HP x%.2f" % m, play(naive)[0], play(typed)[0]))
    for m in (1.5, 2.0, 3.0):
        scaled(player_ids + enemy_ids, hp=m)
        rows.append(("both sides HP x%.1f" % m, play(naive)[0], play(typed)[0]))
    CREATURES = base
    return rows


def discriminates():
    """The three assertions that define a pillar-2 encounter, per
    design/encounters.md's checklist: naive must lose, correct play must win,
    and correct play that hoards its Charges must lose — that last one being
    what separates "the Break/Charge economy matters" from "it exists"."""
    return (play(naive)[0] == "enemy"
            and play(typed)[0] == "player"
            and play(typed_hoard)[0] == "enemy")


# Every constant the resolver and turn loop read, with values to try. The
# question each row answers is: if this number were different, would the
# encounter still discriminate skill? A constant that survives every value in
# its row is a free knob; one that breaks is a load-bearing wall, and changing
# it invalidates the balance numbers in first_blood_balance.md, capture.md and
# progression.md, all of which were measured on top of it.
SWEEP = [
    ("FRONT_DAMAGE_BONUS",       [0.0, 1.0, 2.0, 4.0]),
    ("BACK_TARGET_MULTIPLIER",   [0.5, 0.75, 1.0]),
    ("CHARGE_MULTIPLIER",        [1.0, 1.25, 1.5, 2.0]),
    ("BROKEN_TAKES_MORE_DAMAGE", [1.0, 1.25, 1.5, 2.0]),
    ("RESIST_HEAL",              [0, 2, 4]),
    ("GUARD_REGEN",              [0, 1, 2]),
    ("MELEE_REACH",              ["front", "any"]),
    ("SWAP_MODE",                ["full", "guard"]),
]


BAND_STEPS = [1.02, 1.05, 1.10, 1.15, 1.20, 1.30, 1.40, 1.50, 1.75, 2.00]


def band():
    """How far each side can be moved before the encounter stops discriminating.

    design/progression.md calls this the number that actually describes an
    encounter's balance, as against HP margin. Returns (player_headroom,
    enemy_headroom) as fractions, or None if the encounter does not
    discriminate at parity. Censored at +100%.

    This is a strictly finer measure than discriminates(), and the difference
    matters: BROKEN_TAKES_MORE_DAMAGE passes the binary test at every value and
    moves the band from +20% to +75%. A constant can be "free" and still be the
    most important dial in the file.
    """
    global CREATURES
    base = copy.deepcopy(CREATURES)
    player_ids = [c for c, side, _ in TEAM if side == "player"]
    enemy_ids = [c for c, side, _ in TEAM if side == "enemy"]

    def scale(ids, m):
        global CREATURES
        CREATURES = copy.deepcopy(base)
        for cid in ids:
            CREATURES[cid]["max_hp"] = int(round(CREATURES[cid]["max_hp"] * m))

    try:
        if not discriminates():
            return None
        up = 1.0
        for m in BAND_STEPS:
            scale(player_ids, m)
            if play(naive)[0] == "player":
                break
            up = m
        low = 1.0
        for m in BAND_STEPS:
            scale(enemy_ids, m)
            if play(typed)[0] != "player":
                break
            low = m
        return up - 1.0, low - 1.0
    finally:
        CREATURES = base


def sweep_constants(with_band=False):
    g = globals()
    rows = []
    for name, values in SWEEP:
        original = g[name]
        results = []
        for v in values:
            g[name] = v
            try:
                ok = discriminates()
                results.append((v, ok, band() if (ok and with_band) else None))
            except Exception:
                results.append((v, False, None))
        g[name] = original
        rows.append((name, original, results))
    return rows


# ---------------------------------------------------------------- self-check

# Tick 9 committed this outcome, and a capture of it was published. If the port
# still reproduces it move for move, the port is very probably faithful; if it
# stops, this file is wrong until proven otherwise.
SELF_CHECK = {
    "encounter": "current",
    "policy": "naive",
    "winner": "enemy",
    "events": 16,
    "final": [("emberling", 0), ("rootshell", 0), ("tidalpup", 0), ("galewing", 24)],
}


def self_check():
    set_encounter(SELF_CHECK["encounter"])
    log = []
    w, s, _n = play(POLICIES[SELF_CHECK["policy"]][0], log)
    got = [(c[0], c[2]) for c in s[0:4]]
    ok = (w == SELF_CHECK["winner"] and len(log) == SELF_CHECK["events"]
          and got == SELF_CHECK["final"])
    print("self-check: %s" % ("PASS" if ok else "FAIL"))
    if not ok:
        print("  expected winner=%s events=%d final=%s" % (
            SELF_CHECK["winner"], SELF_CHECK["events"], SELF_CHECK["final"]))
        print("  got      winner=%s events=%d final=%s" % (w, len(log), got))
        print("  This file no longer matches the engine result it was validated")
        print("  against. Do not trust any number it prints until that is fixed.")
    return ok


def set_encounter(name):
    global TEAM
    TEAM = ENCOUNTERS[name]


# ---------------------------------------------------------------- cli

def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("command", nargs="?", default="lines",
                    choices=["lines", "trace", "search", "tolerance", "capture",
                             "constants"])
    ap.add_argument("policy", nargs="?", default="typed")
    ap.add_argument("--encounter", default="repaired", choices=sorted(ENCOUNTERS))
    ap.add_argument("--self-check", action="store_true")
    ap.add_argument("--no-capture", action="store_true",
                    help="disable the Offer action (the rule set before capture existed)")
    ap.add_argument("--depth", type=int, default=18)
    ap.add_argument("--band", action="store_true",
                    help="constants: also report each value's tolerance band, which is a "
                         "strictly finer measure than the pass/fail classification")
    args = ap.parse_args()

    if args.no_capture:
        globals()["NO_OFFERS"] = True

    if args.self_check:
        sys.exit(0 if self_check() else 1)

    set_encounter(args.encounter)
    print("encounter: %s  —  %s" % (args.encounter, ", ".join(
        "%s %s/%s" % (CREATURES[c]["display_name"], side, slot)
        for c, side, slot in TEAM)))
    print()

    if args.command == "lines":
        for name, (fn, desc) in POLICIES.items():
            w, s, n = play(fn)
            php, ehp = hp_left(s)
            print("  %-13s %-6s  player %3d / enemy %3d HP   %2d decisions   %s"
                  % (name, w, php, ehp, n, desc))
        print()
        print("  random play wins %.1f%% of battles" % (100 * random_rate()))
        print()
        print("  Outcomes are the signal; HP margin is not — see")
        print("  design/progression.md on why a 24-HP margin flips at +5% HP.")

    elif args.command == "trace":
        log = []
        w, s, n = play(POLICIES[args.policy][0], log)
        for line in log:
            print("  " + line)
        print("  ---")
        for key, c in zip(KEYS, s[0:4]):
            print("  %-12s %-10s %-6s hp=%3d guard=%d %s" % (
                key, CREATURES[c[0]]["display_name"], c[1], c[2], c[3],
                "DOWN" if c[5] else ""))
        print("  charge player=%d enemy=%d   winner=%s   %d player decisions"
              % (s[4], s[5], w, n))

    elif args.command == "search":
        line, nodes = _deepen(search_win, args.depth)
        if line is None:
            print("  NO WINNING LINE within %d player decisions (%d states)"
                  % (args.depth, nodes))
        else:
            print("  winning line, %d player decisions (%d states):" % (len(line), nodes))
            for who, c in line:
                print("     %-10s %s" % (who, c))

    elif args.command == "tolerance":
        print("  %-22s %-8s %-8s" % ("advantage", "naive", "typed"))
        for label, wn, wt in tolerance():
            flag = "" if (wn == "enemy" and wt == "player") else "   <-- no longer discriminates"
            print("  %-22s %-8s %-8s%s" % (label, wn, wt, flag))

    elif args.command == "constants":
        print("  Does the encounter still discriminate skill at each value?")
        print("  (naive loses AND correct play wins AND hoarding Charges loses)")
        print()
        buckets = {"free": [], "bounded": [], "fixed": []}
        for name, current, results in sweep_constants(with_band=args.band):
            cells = "  ".join("%s%s\033[0m%s" % (
                "\033[32m" if ok else "\033[31m",
                "%s=%s" % ("ok" if ok else "NO", v),
                "" if b is None else "(%+.0f/%+.0f)" % (b[0] * 100, b[1] * 100))
                for v, ok, b in results)
            good = [v for v, ok, _b in results if ok]
            # A binary "load-bearing" verdict lumps a constant with a working
            # range together with one that cannot move at all, which is how the
            # first version of this table misread FRONT_DAMAGE_BONUS.
            kind = "free" if len(good) == len(results) else ("fixed" if len(good) <= 1 else "bounded")
            buckets[kind].append((name, good))
            print("  %-26s now %-6s  %s" % (name, current, cells))
        print()
        for kind, blurb in (("fixed", "FIXED — only one tested value works; treat as structural"),
                            ("bounded", "BOUNDED — works over a range; staying inside it is safe"),
                            ("free", "FREE — every tested value works; reach for these first")):
            if buckets[kind]:
                print("  %s" % blurb)
                for name, good in buckets[kind]:
                    print("     %-26s %s" % (name, ", ".join(str(v) for v in good)))
        print()
        print("  Leaving a bounded range or changing a fixed value invalidates the numbers")
        print("  in first_blood_balance.md, capture.md and progression.md, all of which")
        print("  were measured on top of them.")

    elif args.command == "capture":
        for ti in (2, 3):
            name = CREATURES[TEAM[ti][0]]["display_name"]
            for req, tag in ((False, "capture"), (True, "capture and still win")):
                line, nodes = _deepen(
                    lambda d, t=ti, r=req: search_capture(t, r, d), args.depth)
                if line is None:
                    print("  %-10s %-22s NOT POSSIBLE (%d states)" % (name, tag, nodes))
                else:
                    print("  %-10s %-22s %d decisions" % (name, tag, len(line)))


if __name__ == "__main__":
    main()
