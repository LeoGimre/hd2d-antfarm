extends Node3D
## Battle scene root — M3's fourth box: the player actually chooses on their
## own creatures' turns (move, target, whether to Swap, whether to spend a
## banked Charge) instead of every combatant picking for itself, and the
## fight now has a real end — one side fully defeated stops the clock and
## announces a result. The enemy side keeps picking its own move/target
## exactly as before; only the player's turns pause for input.
##
## Input is polled (Input.is_action_just_pressed), not delivered through
## _unhandled_input — matching player.gd's own convention, and for the same
## reason: Input.action_press()/action_release(), which is how a demo script
## drives this without a real keyboard, updates the Input singleton's polled
## state directly rather than emitting an InputEvent, so an _input()-style
## callback would never see it fire.

const QUEUE_PREVIEW := 6
# Slow enough to read as discrete turns on a captured clip, not a blur.
const TURN_INTERVAL := 1.35
## Lower than tick 6's 2.2 — at the Back slots' distance the tilt-shift blur
## spreads a bloomed flash into a soft cloud big enough to swallow that
## creature's own InfoLabel (caught in QC, not obvious on paper). A smaller
## peak still reads as "this one just acted" without doing that.
const FLASH_PEAK := 1.1
const FLASH_UP_SECONDS := 0.15
const FLASH_DOWN_SECONDS := 0.55

const CHIP_COLORS := {
	"player": Color(0.30, 0.55, 0.95),
	"enemy": Color(0.85, 0.30, 0.28),
}

## Which creature stands in which slot. build_battle.gd builds the same
## table to place and label the capsules; the two files have to stay in
## agreement on ids and creature choices, same coupling tick 6 already noted
## for node names.
const TEAM := {
	"PlayerFront": {"creature_id": "emberling", "side": "player", "slot": "front"},
	"PlayerBack": {"creature_id": "rootshell", "side": "player", "slot": "back"},
	"EnemyFront": {"creature_id": "tidalpup", "side": "enemy", "slot": "front"},
	"EnemyBack": {"creature_id": "galewing", "side": "enemy", "slot": "back"},
}

@onready var _strip: HBoxContainer = $UI/TurnQueueStrip
@onready var _creatures: Node3D = $Creatures
@onready var _combat_log: Label = $UI/CombatLog
@onready var _prompt_label: Label = $UI/PlayerPrompt
@onready var _player_charge_label: Label = $UI/PlayerCharge
@onready var _enemy_charge_label: Label = $UI/EnemyCharge

var _queue := TurnQueue.new()
var _db := CreatureDB.new()
var _types := TypeChart.new()
var _states: Dictionary = {} # id -> CombatantState
var _charge := {"player": 0, "enemy": 0}
var _timer := 0.0
var _battle_over := false

# Player-turn input state. _pending_move is empty ({}) while the player is
# still choosing a move (or Swap); once set, the next input is a target.
var _awaiting_input := false
var _pending_state: CombatantState
var _pending_move: Dictionary = {}
var _charge_queued := false


func _ready() -> void:
	for id in TEAM:
		var info: Dictionary = TEAM[id]
		var data := _db.get_creature(info["creature_id"])
		var state := CombatantState.new(
			id, data["display_name"], info["side"], info["slot"], data["type"],
			float(data["speed"]), data["max_hp"], data["max_guard"], data["moves"])
		_states[id] = state
		# Speeds come straight from data now, not a hand-picked ratio — the
		# roster itself (11/9/14/7) already spreads enough that the queue
		# visibly reorders instead of ping-ponging.
		_queue.add_combatant(id, state.display_name, state.side, state.speed)

	_refresh_strip()
	_refresh_status_labels()
	_refresh_charge_labels()


func _process(delta: float) -> void:
	if _battle_over:
		return
	if _awaiting_input:
		_poll_player_input()
		return
	_timer += delta
	if _timer < TURN_INTERVAL:
		return
	_timer = 0.0
	_take_turn()


func _take_turn() -> void:
	var actor := _queue.advance()
	var state: CombatantState = _states[actor.id]

	# Guard regenerates at the start of the owner's own scheduled turn, even
	# the turn a Broken creature is about to lose — the loop is "sustained
	# pressure keeps you down," not "one break ends your recovery forever."
	state.guard = mini(state.max_guard, state.guard + 1)

	_refresh_strip()
	_flash(actor.id)

	if state.defeated:
		return

	if state.broken:
		state.broken = false
		_log("%s is Broken and loses this turn." % state.display_name)
		_refresh_status_labels()
		return

	if state.side == "player":
		_begin_player_turn(state)
		return

	var move_id := state.next_move_id()
	var move := _db.get_move(move_id)
	var target := _pick_target(state, move)
	if target == null:
		_log("%s has no target left standing." % state.display_name)
		return
	_resolve_and_apply(state, target, move, _charge[state.side] > 0)


## Melee can only reach the opposing Front slot (or Back, if Front has
## fallen); ranged can reach either. The enemy AI aims ranged at Back on
## purpose so a capture actually shows the 25%-less-damage rule instead of
## relying on the viewer to trust it exists; the player picks their own
## ranged target instead (see _poll_target_choice()).
func _pick_target(attacker: CombatantState, move: Dictionary) -> CombatantState:
	var enemy_side := "enemy" if attacker.side == "player" else "player"
	var front: CombatantState = _states.get(enemy_side.capitalize() + "Front")
	var back: CombatantState = _states.get(enemy_side.capitalize() + "Back")

	if move["category"] == "melee":
		if front != null and not front.defeated:
			return front
		if back != null and not back.defeated:
			return back
		return null

	if back != null and not back.defeated:
		return back
	if front != null and not front.defeated:
		return front
	return null


## The only place an attack actually resolves, for both the AI and the
## player — keeps Charge bookkeeping, Guard/HP application, the log line and
## the end-of-battle check in one spot instead of duplicated per caller.
func _resolve_and_apply(attacker: CombatantState, target: CombatantState, move: Dictionary,
		charge_available: bool) -> void:
	var effectiveness := _types.effectiveness(attacker.ctype, target.ctype)
	var result := CombatResolver.resolve(attacker.slot, target, move, effectiveness, charge_available)
	if charge_available:
		_charge[attacker.side] -= 1
	CombatResolver.apply(target, result)
	if result.breaks_defender:
		_charge[attacker.side] += 1

	_log(_describe(attacker, target, move, result))
	_refresh_status_labels()
	_refresh_charge_labels()
	_check_battle_over()


func _describe(attacker: CombatantState, defender: CombatantState, move: Dictionary,
		result: CombatResolver.Result) -> String:
	var verbs := {"weak": "Weak hit!", "resist": "Resisted.", "neutral": "Hit."}
	var verb: String = verbs[result.effectiveness]
	var charge_note := " (Charge spent!)" if result.charge_spent else ""
	var break_note := " %s is Broken!" % defender.display_name if result.breaks_defender else ""
	return "%s used %s on %s — %s -%d HP, -%d Guard%s%s" % [
		attacker.display_name, move["display_name"], defender.display_name, verb,
		result.hp_damage, result.guard_damage, charge_note, break_note,
	]


## ---- Player turn: choose a move (or Swap), then a target if the move needs one ----

func _begin_player_turn(state: CombatantState) -> void:
	_awaiting_input = true
	_pending_state = state
	_pending_move = {}
	_charge_queued = false
	_show_move_prompt()


func _show_move_prompt() -> void:
	var state := _pending_state
	var move_a := _db.get_move(state.move_ids[0])
	var move_b := _db.get_move(state.move_ids[1])
	var charge_available: bool = _charge[state.side] > 0
	var charge_note := ""
	if charge_available:
		charge_note = "   [C] Charge: %s" % ("ON" if _charge_queued else "off")
	_prompt_label.text = "%s's turn — [1] %s (%s)   [2] %s (%s)   [3] Swap%s" % [
		state.display_name, move_a["display_name"], move_a["category"],
		move_b["display_name"], move_b["category"], charge_note,
	]


func _show_target_prompt(move: Dictionary) -> void:
	var state := _pending_state
	var enemy_side := "enemy" if state.side == "player" else "player"
	var front: CombatantState = _states.get(enemy_side.capitalize() + "Front")
	var back: CombatantState = _states.get(enemy_side.capitalize() + "Back")
	var options: Array[String] = []
	if front != null and not front.defeated:
		options.append("[F] %s (Front)" % front.display_name)
	if back != null and not back.defeated:
		options.append("[B] %s (Back)" % back.display_name)
	_prompt_label.text = "%s uses %s — choose target: %s" % [
		state.display_name, move["display_name"], "   ".join(options),
	]


func _poll_player_input() -> void:
	if _pending_move.is_empty():
		_poll_move_choice()
	else:
		_poll_target_choice()


func _poll_move_choice() -> void:
	var state := _pending_state

	if Input.is_action_just_pressed("battle_charge") and _charge[state.side] > 0:
		_charge_queued = not _charge_queued
		_show_move_prompt()
		return

	if Input.is_action_just_pressed("battle_swap"):
		_execute_player_swap(state.id)
		return

	var move_id := ""
	if Input.is_action_just_pressed("battle_move_1"):
		move_id = state.move_ids[0]
	elif Input.is_action_just_pressed("battle_move_2"):
		move_id = state.move_ids[1]
	else:
		return

	var move := _db.get_move(move_id)
	if move["category"] == "melee":
		# Melee has no target choice — it hits Front, or Back if Front has
		# already fallen (design/combat.md's "no free pass" rule) — so it
		# resolves immediately instead of asking a question with one answer.
		var target := _pick_target(state, move)
		if target == null:
			_log("%s has no target left standing." % state.display_name)
			_end_player_turn()
			return
		_resolve_and_apply(state, target, move, _charge_queued and _charge[state.side] > 0)
		_end_player_turn()
	else:
		_pending_move = move
		_show_target_prompt(move)


func _poll_target_choice() -> void:
	var state := _pending_state
	var enemy_side := "enemy" if state.side == "player" else "player"
	var target: CombatantState = null
	if Input.is_action_just_pressed("battle_target_front"):
		target = _states.get(enemy_side.capitalize() + "Front")
	elif Input.is_action_just_pressed("battle_target_back"):
		target = _states.get(enemy_side.capitalize() + "Back")
	else:
		return

	if target == null or target.defeated:
		return

	_resolve_and_apply(state, target, _pending_move, _charge_queued and _charge[state.side] > 0)
	_end_player_turn()


## Swap trades which creature occupies PlayerFront/PlayerBack — id keys stay
## slot-shaped (that's what every other lookup in this file assumes), so the
## swap moves the CombatantState objects between the two dictionary entries
## and hands the turn queue the swapped-in creature's own speed, so turn
## order follows the creature rather than staying pinned to the slot it
## used to stand in.
func _execute_player_swap(actor_id: String) -> void:
	var partner_id := "PlayerBack" if actor_id == "PlayerFront" else "PlayerFront"
	var a: CombatantState = _states[actor_id]
	var b: CombatantState = _states[partner_id]
	var a_slot := a.slot
	a.slot = b.slot
	b.slot = a_slot
	_states[actor_id] = b
	_states[partner_id] = a
	_queue.rename(actor_id, b.display_name, b.speed)
	_queue.rename(partner_id, a.display_name, a.speed)

	_log("%s swaps to %s, %s steps up to %s." % [
		a.display_name, a.slot.capitalize(), b.display_name, b.slot.capitalize(),
	])
	_refresh_status_labels()
	_end_player_turn()


func _end_player_turn() -> void:
	_awaiting_input = false
	_pending_state = null
	_pending_move = {}
	_charge_queued = false
	_prompt_label.text = ""
	_refresh_strip()
	_timer = 0.0


func _is_side_defeated(side: String) -> bool:
	for id in _states:
		var s: CombatantState = _states[id]
		if s.side == side and not s.defeated:
			return false
	return true


## A battle that can be lost or won needs an actual end — before this tick
## nothing ever checked, so a fully-defeated side just sat there feeding
## "no target left standing" log lines forever. Checked after every attack;
## stops the turn clock and freezes input the instant one side is wiped.
func _check_battle_over() -> void:
	if _is_side_defeated("enemy"):
		_battle_over = true
		_announce_result("Player wins!")
	elif _is_side_defeated("player"):
		_battle_over = true
		_announce_result("Enemy wins!")


func _announce_result(text: String) -> void:
	_prompt_label.text = text
	_log(text)


func _log(text: String) -> void:
	_combat_log.text = text


func _refresh_strip() -> void:
	for child in _strip.get_children():
		child.queue_free()
	var upcoming := _queue.preview(QUEUE_PREVIEW)
	for i in upcoming.size():
		_strip.add_child(_make_chip(upcoming[i], i == 0))


## The head chip (soonest scheduled) gets a bright border — that's the
## queue's answer to "who acts next," checkable against whichever capsule
## flashes on the following turn.
func _make_chip(actor: TurnQueue.Combatant, is_next: bool) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CHIP_COLORS.get(actor.side, Color.WHITE)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	var border := 4 if is_next else 0
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = actor.display_name
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 20 if is_next else 16)
	panel.add_child(label)
	return panel


## The queue strip shows the future; this is the present — the acting
## creature's capsule pulses its emission so a viewer can match "who the
## strip predicted" against "who just moved" without any combat log text.
func _flash(id: String) -> void:
	var holder := _creatures.get_node_or_null(id)
	if holder == null:
		return
	var body: MeshInstance3D = holder.get_node_or_null("Body")
	if body == null:
		return
	var mat: StandardMaterial3D = body.material_override
	if mat == null:
		return
	var tween := create_tween()
	tween.tween_property(mat, "emission_energy_multiplier", FLASH_PEAK, FLASH_UP_SECONDS)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, FLASH_DOWN_SECONDS)


## Each creature's InfoLabel (a Label3D under its capsule) reads its name,
## type, HP and Guard directly, plus a Broken/Down callout — the thing a
## viewer needs to check the combat log's claims against without reading
## combat_resolver.gd.
func _refresh_status_labels() -> void:
	for id in _states:
		var state: CombatantState = _states[id]
		var holder := _creatures.get_node_or_null(id)
		if holder == null:
			continue
		var label: Label3D = holder.get_node_or_null("InfoLabel")
		if label == null:
			continue
		var status := ""
		if state.defeated:
			status = "  DOWN"
		elif state.broken:
			status = "  BROKEN"
		label.text = "%s (%s)\nHP %d/%d   Guard %d/%d%s" % [
			state.display_name, state.ctype, state.hp, state.max_hp, state.guard, state.max_guard,
			status,
		]


func _refresh_charge_labels() -> void:
	_player_charge_label.text = "Player Charge: %d" % _charge["player"]
	_enemy_charge_label.text = "Enemy Charge: %d" % _charge["enemy"]
