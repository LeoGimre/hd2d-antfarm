extends SceneTree
## Plays the M3 proof battle without a window, and searches every line the
## player could take.
##
##   godot --headless --path game --script res://tools/battle_sim.gd
##   ... -- --naive     just play the naive line and report
##   ... -- --search    just search for a winning line
##
## Why this exists: M3's fourth box is "a battle that can be lost by playing
## badly and won by playing well." Proving the first half is easy — script the
## naive line, watch it lose. Proving the second half means finding a line that
## wins, and tick 9 tried to do that by hand, one guess at a time, through a
## scratch script that drove the real scene. It got within 2-10 HP repeatedly
## and never closed it, which tells you nothing: a line that loses by 4 HP
## could mean the fight is unwinnable or that the guess was simply not the best
## line. Only exhausting the space separates those.
##
## The fight is fully deterministic (design/combat.md's turn queue has no
## randomness), so "the space" is a finite tree and the answer is decidable,
## not estimable. This runs the same BattleCore the battle scene runs, off the
## same encounter data and the same game/data JSON, so a win found here is a win
## a player can actually type in.

const BATTLE_SCRIPT := "res://scripts/battle.gd"
const DEMO_SCRIPT := "res://tools/demos/battle_demo.gd"

## Iterative deepening: search lines of 1 player decision, then 2, and so on,
## so the first win found is also the shortest one to script into a demo.
const MAX_DECISIONS := 14
## A stuck fight (both sides swapping forever) has no natural end; this is the
## "nobody is winning" cutoff.
const MAX_TURNS := 80
## GDScript is not fast. This caps a single deepening pass so a pathological
## branch cannot hang a tick; it is reported when hit, never swallowed.
const NODE_BUDGET := 400000

var _nodes := 0
var _budget_hit := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var want_naive := args.is_empty() or args.has("--naive")
	var want_search := args.is_empty() or args.has("--search")
	var want_demo := args.is_empty() or args.has("--demo")

	if want_naive:
		_report_naive()
	if want_search:
		if want_naive:
			print("")
		_report_search()
	if want_demo:
		if want_naive or want_search:
			print("")
		_report_demo()

	quit()


## ---- The two questions the box asks ----

func _report_naive() -> void:
	print("=== naive line: always melee, never swap, never spend Charge ===")
	var core := _new_core()
	var log_lines: Array[String] = []
	var turns := 0
	while not core.battle_over and turns < MAX_TURNS:
		turns += 1
		var turn: BattleCore.TurnStart = core.start_turn()
		if turn.log_line != "":
			log_lines.append(turn.log_line)
			continue
		if turn.state.defeated:
			continue
		if turn.needs_player_input:
			# "Naive" per design/combat.md's worked example: swing the melee
			# move at whatever is in Front, every turn, forever.
			var move := _move(turn.state.move_ids[0])
			var target := core.pick_target(turn.state, move)
			if target == null:
				continue
			log_lines.append(core.resolve_and_apply(turn.state, target, move, false))
		else:
			log_lines.append(core.enemy_act(turn.state))

	for line in log_lines:
		print("  " + line)
	print("  -> %s" % (core.result_text if core.battle_over else "no result in %d turns" % MAX_TURNS))
	print("  " + _score(core))


func _report_search() -> void:
	print("=== searching every player line for a win ===")
	for limit in range(1, MAX_DECISIONS + 1):
		_nodes = 0
		_budget_hit = false
		var line := _search(_new_core(), [], limit)
		var note := " (node budget hit — this depth is not exhaustive)" if _budget_hit else ""
		if line.is_empty():
			print("  depth %2d: no win in %d nodes%s" % [limit, _nodes, note])
			continue
		print("  depth %2d: WIN in %d nodes" % [limit, _nodes])
		print("")
		print("=== the winning line, replayed ===")
		_replay(line)
		return
	print("  no winning line up to %d player decisions." % MAX_DECISIONS)


## Replays the line battle_demo.gd actually scripts, read off that script so
## the two cannot drift. The demo synthesizes keystrokes into a live scene and
## this replays action records through BattleCore, so agreement here is not
## proof the capture will match — but disagreement is proof it will not, and it
## costs a second to check instead of a six-minute render.
func _report_demo() -> void:
	print("=== battle_demo.gd's scripted line, replayed ===")
	var line: Array = []
	for step in load(DEMO_SCRIPT).get_script_constant_map()["LINE"]:
		line.append({
			"kind": "move",
			"move_id": "", # filled per-actor at replay time
			"demo_move": int(step["move"]),
			"slot": str(step.get("target", "")),
			"charge": bool(step.get("charge", false)),
		})
	_replay(line)


## ---- Search ----

## Returns the first winning line found within `decisions_left` player
## decisions, as an array of action dictionaries, or [] if there is none.
## Depth-first, but called under iterative deepening, so the first line
## returned is the shortest that exists.
func _search(core: BattleCore, line: Array, decisions_left: int) -> Array:
	var turn: BattleCore.TurnStart = null
	var turns := 0

	# Run the fight forward until it either ends or reaches a player decision.
	# Nothing in here branches, so it costs nothing to do it on the live core.
	while true:
		if core.battle_over:
			return line if core.result_text == "Player wins!" else []
		turns += 1
		if turns > MAX_TURNS:
			return []
		turn = core.start_turn()
		if turn.state.defeated or turn.log_line != "":
			continue
		if turn.needs_player_input:
			break
		core.enemy_act(turn.state)

	if decisions_left <= 0:
		return []

	for action in _actions(core, turn.state):
		if _nodes >= NODE_BUDGET:
			_budget_hit = true
			return []
		_nodes += 1
		var branch := core.clone()
		_apply(branch, turn.actor_id, action)
		var found := _search(branch, line + [action], decisions_left - 1)
		if not found.is_empty():
			return found
	return []


## Every legal thing the player can do on this turn. Melee has no target
## choice (it hits Front, or Back if Front has fallen), ranged has two, Swap
## has none — and each attack doubles while a Charge is banked, since spending
## it is declared at move time.
func _actions(core: BattleCore, state: CombatantState) -> Array:
	var attacks: Array = []
	var melee := _move(state.move_ids[0])
	if core.pick_target(state, melee) != null:
		attacks.append({"kind": "move", "move_id": state.move_ids[0], "slot": ""})
	for slot in ["front", "back"]:
		if core.pick_target(state, _move(state.move_ids[1]), slot) != null:
			attacks.append({"kind": "move", "move_id": state.move_ids[1], "slot": slot})

	var out: Array = []
	for attack in attacks:
		out.append(attack)
		if core.charge[state.side] > 0:
			var empowered: Dictionary = attack.duplicate()
			empowered["charge"] = true
			out.append(empowered)
	out.append({"kind": "swap"})
	return out


func _apply(core: BattleCore, actor_id: String, action: Dictionary) -> String:
	var state: CombatantState = core.states[actor_id]
	if action["kind"] == "swap":
		return core.swap(actor_id)
	var move := _move(action["move_id"])
	var target := core.pick_target(state, move, action["slot"])
	if target == null:
		return ""
	return core.resolve_and_apply(state, target, move, action.get("charge", false))


## Plays a found line back on a fresh fight and prints every log line, so the
## devlog and a future demo script have the actual sequence rather than a
## summary of it.
func _replay(line: Array) -> void:
	var core := _new_core()
	var index := 0
	var turns := 0
	while not core.battle_over and turns < MAX_TURNS:
		turns += 1
		var turn: BattleCore.TurnStart = core.start_turn()
		if turn.log_line != "":
			print("  " + turn.log_line)
			continue
		if turn.state.defeated:
			continue
		if not turn.needs_player_input:
			print("  " + core.enemy_act(turn.state))
			continue
		if index >= line.size():
			print("  (line exhausted before the fight ended)")
			return
		# The demo names moves by slot in the acting creature's own list (1 or
		# 2); the search names them by id. Resolve to an id here so both kinds
		# of line replay through the same path.
		var action: Dictionary = (line[index] as Dictionary).duplicate()
		index += 1
		if action.has("demo_move"):
			action["move_id"] = turn.state.move_ids[int(action["demo_move"]) - 1]
		print("  [%s] %s" % [_describe_action(action), _apply(core, turn.actor_id, action)])
	print("  -> %s" % core.result_text)
	print("  " + _score(core))


func _describe_action(action: Dictionary) -> String:
	if action["kind"] == "swap":
		return "Swap"
	var move := _move(action["move_id"])
	var target: String = (" @" + action["slot"].capitalize()) if action["slot"] != "" else ""
	var charged := " +Charge" if action.get("charge", false) else ""
	return "%s%s%s" % [move["display_name"], target, charged]


## ---- Plumbing ----

func _new_core() -> BattleCore:
	# The encounter id is read off battle.gd rather than restated here: a
	# simulator that can disagree with the scene about who is standing where is
	# worse than no simulator at all. The table itself now comes from
	# game/data/encounters.json, so both of them read the same bytes.
	var id: String = load(BATTLE_SCRIPT).get_script_constant_map()["DEFAULT_ENCOUNTER"]
	return BattleCore.new(EncounterDB.new().team(id, _db()), _db(), _types())


func _score(core: BattleCore) -> String:
	var parts: Array[String] = []
	for id in core.states:
		var s: CombatantState = core.states[id]
		parts.append("%s %d/%d HP" % [s.display_name, s.hp, s.max_hp])
	return "final: " + ", ".join(parts)


func _move(id: String) -> Dictionary:
	return _db().get_move(id)


var _db_cache: CreatureDB
var _types_cache: TypeChart


func _db() -> CreatureDB:
	if _db_cache == null:
		_db_cache = CreatureDB.new()
	return _db_cache


func _types() -> TypeChart:
	if _types_cache == null:
		_types_cache = TypeChart.new()
	return _types_cache
