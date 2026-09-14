#!/usr/bin/env python3
"""Generate the combat test fixtures design/combat_tests.md plans.

That document works out its expected damage numbers by hand, in a table, so a
reader can check the arithmetic. Hand-written expected values go stale the
moment a constant moves, and the constants are under active proposal. These are
generated from the same model farm/agreements.py already checks against
combat_resolver.gd, so they cannot disagree with the engine without something
failing loudly.

    python3 design/proto/gen_test_cases.py           # writes combat_cases.json
    python3 design/proto/gen_test_cases.py --check   # exit 1 if it would change

The engine tick copies the result to game/tests/cases.json and writes a runner
that walks it. That is the whole of M3's fifth box's tier 1 and tier 2, minus
the GDScript.
"""
import json, os, sys, itertools

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import combat_solver as cs

OUT = os.path.join(HERE, "combat_cases.json")


def resolver_cases():
    """Tier 1: every interesting combination of the damage rules, with the
    arithmetic spelled out so a failing test says why."""
    out = []
    for cat, power in (("melee", 8), ("ranged", 6)):
        for aslot, dslot, charge, broken in itertools.product(
                ("front", "back"), ("front", "back"), (False, True), (False, True)):
            dmg = float(power)
            steps = [str(power)]
            if aslot == "front":
                dmg += cs.FRONT_DAMAGE_BONUS
                steps.append("+%g front" % cs.FRONT_DAMAGE_BONUS)
            if cat == "ranged" and dslot == "back":
                dmg *= cs.BACK_TARGET_MULTIPLIER
                steps.append("x%g back-target" % cs.BACK_TARGET_MULTIPLIER)
            if charge:
                dmg *= cs.CHARGE_MULTIPLIER
                steps.append("x%g charge" % cs.CHARGE_MULTIPLIER)
            if broken:
                dmg *= cs.BROKEN_TAKES_MORE_DAMAGE
                steps.append("x%g broken" % cs.BROKEN_TAKES_MORE_DAMAGE)
            out.append({
                "move_power": power, "move_category": cat,
                "attacker_slot": aslot, "defender_slot": dslot,
                "charge_spent": charge, "defender_broken": broken,
                "expect_hp_damage": cs.gd_round(dmg),
                "arithmetic": " ".join(steps) + " = %g" % dmg,
            })
    return out


def guard_cases():
    """Tier 1: Guard damage, the resist heal, and every edge of breaks_defender."""
    out = []
    for eff, gd in sorted(cs.GUARD_DAMAGE.items()):
        out.append({"effectiveness": eff, "expect_guard_damage": gd,
                    "expect_heal": cs.RESIST_HEAL if eff == "resist" else 0})
    breaks = []
    # Every guard_damage here must be one the type chart can actually produce.
    # This list used to carry (3, 3) — an "exactly equal breaks" case at a value
    # no hit in the game does, since GUARD_DAMAGE is {weak: 2, neutral: 1,
    # resist: 0}. The off-engine model never noticed because it took the number
    # directly; the GDScript suite drives resolve() through an effectiveness and
    # could not express the case at all. A case the game cannot reach is not
    # coverage, so it is gone and (2, 1) — overkill, which breaks — is in its
    # place. The assert keeps the next one from being added by hand.
    for gd, guard, broken in [(1, 1, False), (1, 2, False), (2, 2, False), (2, 3, False),
                              (0, 1, False), (1, 0, False), (2, 1, True), (2, 1, False)]:
        assert gd in cs.GUARD_DAMAGE.values(), (
            "breaks_defender case does %d Guard damage, which no effectiveness "
            "produces: %s" % (gd, cs.GUARD_DAMAGE))
        breaks.append({"guard_damage": gd, "defender_guard": guard,
                       "defender_broken": broken,
                       "expect_breaks": (not broken) and guard > 0 and gd >= guard})
    return out, breaks


def type_cases():
    types = sorted(cs.TYPES)
    out = [{"attacker": a, "defender": d, "expect": cs.effectiveness(a, d)}
           for a in types for d in types]
    out.append({"attacker": "Steam", "defender": types[0], "expect": "neutral",
                "note": "an unknown type must degrade to neutral, not throw — "
                        "adding a fifth type is a data edit"})
    return out


def queue_cases():
    speeds = [float(cs.CREATURES[c]["speed"]) for c, _s, _l in cs.ENCOUNTERS[cs.DEFAULT_ENCOUNTER]]
    q = [(s, 1000.0 / s) for s in speeds]
    order = []
    for _ in range(8):
        order.append(cs.advance(q))
    return {"speeds": speeds,
            "expect_initial_scheduled": [round(1000.0 / s, 6) for s in speeds],
            "expect_advance_order": order,
            "note": "preview(n) must return the same sequence advance() would, "
                    "and must not mutate state"}


def outcome_cases():
    """Tier 2: the assertions that keep M3's fourth box true once it is ticked."""
    out = []
    for enc in cs.balanced_encounters():
        cs.set_encounter(enc)
        for name, (fn, desc) in cs.POLICIES.items():
            w, s, n = cs.play(fn)
            out.append({"encounter": enc, "line": name, "description": desc,
                        "expect_winner": w, "expect_player_decisions": n})
    return out


def golden_trace(encounter=None, policy="typed"):
    """Tier 3: the full event log, event for event. Expected to be regenerated
    on any deliberate tuning change — read the diff, confirm every changed line
    was meant, commit. A golden trace nobody reads the diff of is worthless."""
    cs.set_encounter(encounter or cs.DEFAULT_ENCOUNTER)
    log = []
    w, s, n = cs.play(cs.POLICIES[policy][0], log)
    return {"encounter": encounter or cs.DEFAULT_ENCOUNTER, "policy": policy, "winner": w,
            "player_decisions": n, "events": [l.strip() for l in log]}


def build():
    eff_cases, break_cases = guard_cases()
    return {
        "_comment": "Generated by design/proto/gen_test_cases.py. Do not hand-edit — "
                    "regenerate. Expected values come from the off-engine model, whose "
                    "constants farm/agreements.py checks against combat_resolver.gd.",
        "constants": {k: getattr(cs, k) for k in
                      ("FRONT_DAMAGE_BONUS", "BACK_TARGET_MULTIPLIER", "CHARGE_MULTIPLIER",
                       "BROKEN_TAKES_MORE_DAMAGE", "RESIST_HEAL", "GUARD_REGEN")},
        "resolver_damage": resolver_cases(),
        "guard_effectiveness": eff_cases,
        "breaks_defender": break_cases,
        "type_chart": type_cases(),
        "turn_queue": queue_cases(),
        "outcomes": outcome_cases(),
        "golden_trace": golden_trace(),
    }


if __name__ == "__main__":
    data = build()
    text = json.dumps(data, indent=2) + "\n"
    if "--check" in sys.argv:
        current = open(OUT).read() if os.path.exists(OUT) else ""
        if current != text:
            print("combat_cases.json is stale — regenerate with "
                  "python3 design/proto/gen_test_cases.py")
            sys.exit(1)
        print("combat_cases.json is current")
    else:
        with open(OUT, "w") as f:
            f.write(text)
        counts = {k: len(v) for k, v in data.items() if isinstance(v, list)}
        print("wrote %s" % os.path.relpath(OUT))
        for k, v in counts.items():
            print("   %-22s %d cases" % (k, v))
        print("   %-22s %d events" % ("golden_trace", len(data["golden_trace"]["events"])))
