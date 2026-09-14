class_name BattleCore
extends RefCounted
## The fight itself, with no scene attached: states, turn queue, Charge bank,
## and the rules for taking one turn. battle.gd used to own all of this inline
## and interleave it with tweens and Label3D updates, which meant the only way
## to ask "does this line win?" was to boot a window and watch. Tick 9 tried
## that and spent the whole tick hand-scripting lines one at a time.
##
## Everything here is deliberately callable from a --headless --script tool
## (see tools/battle_sim.gd). battle.gd now drives this and renders the
## results; it is the only file that knows what a tween is.
##
## Resolution itself still lives in CombatResolver — this class owns sequence
## (who acts, what they may target, who banks a Charge), not arithmetic.


## What start_turn() hands back: who is acting, whether the caller has to stop
## and ask a player, and anything worth printing before the action resolves.
class TurnStart:
	var actor_id: String
	var state: CombatantState
	var needs_player_input := false
	var log_line := ""


var states: Dictionary = {} # TEAM key -> CombatantState
var queue := TurnQueue.new()
var charge := {"player": 0, "enemy": 0}
var battle_over := false
var result_text := ""

var _db: CreatureDB
var _types: TypeChart


## db/types are injectable so a tool can point the same rules at a scratch
## data set without writing to game/data — a retune sweep should not have to
## mutate the files the real battle scene loads.
func _init(team: Dictionary, db: CreatureDB = null, types: TypeChart = null) -> void:
	_db = db if db != null else CreatureDB.new()
	_types = types if types != null else TypeChart.new()
	for id in team:
		var info: Dictionary = team[id]
		var data := _db.get_creature(info["creature_id"])
		var state := CombatantState.new(
			id, data["display_name"], info["side"], info["slot"], data["type"],
			float(data["speed"]), data["max_hp"], data["max_guard"], data["moves"])
		states[id] = state
		queue.add_combatant(id, state.display_name, state.side, state.speed)


## Advances the queue and settles everything that happens *to* the actor
## before it gets to choose: Guard regenerates at the start of its own turn
## (even the turn a Broken creature is about to lose — the loop is "sustained
## pressure keeps you down," not "one break ends recovery forever"), and a
## Broken or defeated creature never reaches a decision at all.
func start_turn() -> TurnStart:
	var turn := TurnStart.new()
	var actor := queue.advance()
	var state: CombatantState = states[actor.id]
	state.guard = mini(state.max_guard, state.guard + 1)
	turn.actor_id = actor.id
	turn.state = state

	if state.defeated:
		return turn
	if state.broken:
		state.broken = false
		turn.log_line = "%s is Broken and loses this turn." % state.display_name
		return turn

	turn.needs_player_input = state.side == "player"
	return turn


## The enemy side's policy, unchanged from when it lived in battle.gd: it
## alternates its melee and ranged move and aims ranged at Back on purpose, so
## a capture actually shows the 25%-less-damage rule rather than asking the
## viewer to trust it exists.
func enemy_act(state: CombatantState) -> String:
	var move := _db.get_move(state.next_move_id())
	var target := pick_target(state, move)
	if target == null:
		return "%s has no target left standing." % state.display_name
	return resolve_and_apply(state, target, move, charge[state.side] > 0)


## Melee can only reach the opposing Front slot (or Back, if Front has
## fallen); ranged reaches either. `preferred_slot` is how a player names a
## ranged target — melee ignores it, since there is only ever one answer.
func pick_target(attacker: CombatantState, move: Dictionary,
		preferred_slot: String = "") -> CombatantState:
	var enemy_side := "enemy" if attacker.side == "player" else "player"
	var front: CombatantState = states.get(enemy_side.capitalize() + "Front")
	var back: CombatantState = states.get(enemy_side.capitalize() + "Back")

	if move["category"] == "melee":
		if front != null and not front.defeated:
			return front
		if back != null and not back.defeated:
			return back
		return null

	if preferred_slot == "front" and front != null and not front.defeated:
		return front
	if preferred_slot == "back" and back != null and not back.defeated:
		return back
	if preferred_slot != "":
		return null

	if back != null and not back.defeated:
		return back
	if front != null and not front.defeated:
		return front
	return null


## The only place an attack resolves, for the AI and the player alike — Charge
## bookkeeping, Guard/HP application, the log line and the end check in one
## spot instead of duplicated per caller.
func resolve_and_apply(attacker: CombatantState, target: CombatantState, move: Dictionary,
		charge_available: bool) -> String:
	var effectiveness := _types.effectiveness(attacker.ctype, target.ctype)
	var result := CombatResolver.resolve(attacker.slot, target, move, effectiveness, charge_available)
	if charge_available:
		charge[attacker.side] -= 1
	CombatResolver.apply(target, result)
	if result.breaks_defender:
		charge[attacker.side] += 1

	var line := describe(attacker, target, move, result)
	_check_battle_over()
	return line


## Swap trades which creature occupies Front and Back on one side. The id keys
## stay slot-shaped (every lookup in here assumes that), so the swap moves the
## CombatantState objects between dictionary entries and hands the queue the
## swapped-in creature's own speed — turn order follows the creature, not the
## slot it used to stand in.
func swap(actor_id: String) -> String:
	var side_prefix := actor_id.trim_suffix("Front").trim_suffix("Back")
	var partner_id := side_prefix + ("Back" if actor_id.ends_with("Front") else "Front")
	var a: CombatantState = states[actor_id]
	var b: CombatantState = states[partner_id]
	var a_slot := a.slot
	a.slot = b.slot
	b.slot = a_slot
	states[actor_id] = b
	states[partner_id] = a
	queue.rename(actor_id, b.display_name, b.speed)
	queue.rename(partner_id, a.display_name, a.speed)
	return "%s swaps to %s, %s steps up to %s." % [
		a.display_name, a.slot.capitalize(), b.display_name, b.slot.capitalize(),
	]


func describe(attacker: CombatantState, defender: CombatantState, move: Dictionary,
		result: CombatResolver.Result) -> String:
	var verbs := {"weak": "Weak hit!", "resist": "Resisted.", "neutral": "Hit."}
	var verb: String = verbs[result.effectiveness]
	var charge_note := " (Charge spent!)" if result.charge_spent else ""
	var break_note := " %s is Broken!" % defender.display_name if result.breaks_defender else ""
	return "%s used %s on %s — %s -%d HP, -%d Guard%s%s" % [
		attacker.display_name, move["display_name"], defender.display_name, verb,
		result.hp_damage, result.guard_damage, charge_note, break_note,
	]


func is_side_defeated(side: String) -> bool:
	for id in states:
		var s: CombatantState = states[id]
		if s.side == side and not s.defeated:
			return false
	return true


## A deep copy, so a search can try a line and back out of it. Everything that
## can differ between two positions has to travel: HP, Guard, Broken, which of
## its two moves each creature serves next, who stands where, the queue's
## scheduled times, and both Charge banks.
func clone() -> BattleCore:
	var copy := BattleCore.new({}, _db, _types)
	for id in states:
		copy.states[id] = (states[id] as CombatantState).clone()
	copy.queue = queue.clone()
	copy.charge = charge.duplicate()
	copy.battle_over = battle_over
	copy.result_text = result_text
	return copy


func _check_battle_over() -> void:
	if is_side_defeated("enemy"):
		battle_over = true
		result_text = "Player wins!"
	elif is_side_defeated("player"):
		battle_over = true
		result_text = "Enemy wins!"
