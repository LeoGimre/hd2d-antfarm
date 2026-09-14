class_name PolicyBattery
extends RefCounted
## The seven scripted lines design/encounters.md's checklist is written in
## terms of, played against BattleCore.
##
## These are ports of design/proto/combat_solver.py's POLICIES, and they exist
## so tier 2 of design/combat_tests.md can assert whole-fight outcomes in the
## engine instead of only off-engine. The point is not that the policies are
## good play — naive and anti_typed are deliberately bad — it is that the
## engine and the model must agree about what each of them produces. Three
## times now that agreement has been checked by hand; this makes it a test.
##
## A policy returns one action dictionary:
##   {"kind": "move", "melee": bool, "slot": "front"|"back", "charge": bool}
##   {"kind": "swap"}

const PLAYER := "player"


static func names() -> Array[String]:
	return ["naive", "melee_charge", "snipe_back", "anti_typed",
			"typed", "typed_hoard", "typed_swap"]


static func choose(name: String, core: BattleCore, actor: CombatantState,
		decision_index: int) -> Dictionary:
	match name:
		"naive":
			return _attack(true, "front", false)
		"melee_charge":
			return _attack(true, "front", core.charge[PLAYER] > 0)
		"snipe_back":
			var back := _enemy(core, "back")
			if back != null:
				return _attack(false, "back", core.charge[PLAYER] > 0)
			return _attack(true, "front", core.charge[PLAYER] > 0)
		"anti_typed":
			return _by_effectiveness(core, actor, "resist", false)
		"typed":
			return _by_effectiveness(core, actor, "weak", core.charge[PLAYER] > 0)
		"typed_hoard":
			var c := _by_effectiveness(core, actor, "weak", false)
			c["charge"] = false
			return c
		"typed_swap":
			# Not "is Swap on the shortest winning line" — the search minimises
			# decisions and will never pay a turn for durability it does not
			# strictly need. This asks the other question: does Swap buy margin?
			# Spend the turn up front, then play correctly.
			if decision_index == 0 and _partner(core, actor) != null:
				return {"kind": "swap"}
			return _by_effectiveness(core, actor, "weak", core.charge[PLAYER] > 0)
	return _attack(true, "front", false)


static func _attack(melee: bool, slot: String, charge: bool) -> Dictionary:
	return {"kind": "move", "melee": melee, "slot": slot, "charge": charge}


## Front first, then Back: whichever living enemy the actor's type has the named
## relationship to. Falling back to the Front slot — or to Back when Front has
## fallen — matches what the model does and what melee reach allows.
static func _by_effectiveness(core: BattleCore, actor: CombatantState,
		want: String, charge: bool) -> Dictionary:
	var types := TypeChart.new()
	for slot in ["front", "back"]:
		var target := _enemy(core, slot)
		if target == null:
			continue
		if types.effectiveness(actor.ctype, target.ctype) == want:
			return _attack(slot == "front", slot, charge)
	if _enemy(core, "front") != null:
		return _attack(true, "front", charge)
	return _attack(false, "back", charge)


static func _enemy(core: BattleCore, slot: String) -> CombatantState:
	for id in core.states:
		var s: CombatantState = core.states[id]
		if s.side != PLAYER and s.slot == slot and not s.defeated:
			return s
	return null


static func _partner(core: BattleCore, actor: CombatantState) -> CombatantState:
	for id in core.states:
		var s: CombatantState = core.states[id]
		if s.side == actor.side and s != actor:
			return s
	return null
