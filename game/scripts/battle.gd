extends Node3D
## Battle scene root — the view. Turn order, Guard/Charge bookkeeping and move
## resolution used to live in here, tangled up with tweens and Label3D writes,
## which meant the only way to ask "does this line win?" was to boot a window
## and watch one line at a time. All of that moved to BattleCore
## (scripts/battle_core.gd), which runs headless; this file now drives it and
## draws the result. The rules a player sees are the same rules
## tools/battle_sim.gd searches, by construction rather than by discipline.
##
## What stays here: the turn clock, the flash tween, the queue strip, the
## status labels, and the player's input prompts.
##
## Input is polled (Input.is_action_just_pressed), not delivered through
## _unhandled_input — matching player.gd's own convention, and for the same
## reason: Input.action_press()/action_release(), which is how a demo script
## drives this without a real keyboard, updates the Input singleton's polled
## state directly rather than emitting an InputEvent, so an _input()-style
## callback would never see it fire.

const QUEUE_PREVIEW := 6

## Slow enough to read as discrete turns on a captured clip, not a blur.
## Exported rather than const because the demo now plays a whole fight to its
## end instead of a slice of one: at 1.35 the winning line runs past 30
## seconds, and captures that long coalesce frames (see STATE.md). The demo
## turns this down; nothing else should.
@export var turn_interval := 1.35
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

## Which encounter this scene is. build_battle.gd sets it explicitly on the
## root before packing — Godot only serialises an exported property whose value
## differs from the declared default, so the default here is deliberately empty
## and never a real id. A scene built for a defaulted id would store nothing and
## silently follow any later change to that default.
##
## Who stands where comes out of game/data/encounters.json via EncounterDB, and
## is no longer a table in this file that build_battle.gd has to keep a matching
## copy of. tools/battle_sim.gd reads this property off this script, so a
## searched fight is still this fight.
@export var encounter_id: String = ""

const DEFAULT_ENCOUNTER := "first_blood_unpaired"

@onready var _strip: HBoxContainer = $UI/TurnQueueStrip
@onready var _creatures: Node3D = $Creatures
@onready var _combat_log: Label = $UI/CombatLog
@onready var _prompt_label: Label = $UI/PlayerPrompt
@onready var _player_charge_label: Label = $UI/PlayerCharge
@onready var _enemy_charge_label: Label = $UI/EnemyCharge

var _db := CreatureDB.new()
var _core: BattleCore
var _timer := 0.0

# Player-turn input state. _pending_move is empty ({}) while the player is
# still choosing a move (or Swap); once set, the next input is a target.
var _awaiting_input := false
var _pending_state: CombatantState
var _pending_move: Dictionary = {}
var _charge_queued := false


func _ready() -> void:
	var id := encounter_id if encounter_id != "" else DEFAULT_ENCOUNTER
	_core = BattleCore.new(EncounterDB.new().team(id, _db), _db)
	_refresh_strip()
	_refresh_status_labels()
	_refresh_charge_labels()


func _process(delta: float) -> void:
	if _core.battle_over:
		return
	if _awaiting_input:
		_poll_player_input()
		return
	_timer += delta
	if _timer < turn_interval:
		return
	_timer = 0.0
	_take_turn()


func _take_turn() -> void:
	var turn := _core.start_turn()

	_refresh_strip()
	_flash(turn.actor_id)

	if turn.log_line != "":
		_log(turn.log_line)
		_refresh_status_labels()
	if turn.state.defeated or turn.log_line != "":
		return

	if turn.needs_player_input:
		_begin_player_turn(turn.state)
		return

	_log(_core.enemy_act(turn.state))
	_after_action()


## Everything the view owes the screen after any resolved action, player's or
## enemy's. Kept in one place because forgetting one of these three is how a
## fight ends up looking wrong while being right.
func _after_action() -> void:
	_refresh_status_labels()
	_refresh_charge_labels()
	if _core.battle_over:
		_announce_result(_core.result_text)


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
	var charge_available: bool = _core.charge[state.side] > 0
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
	var front: CombatantState = _core.states.get(enemy_side.capitalize() + "Front")
	var back: CombatantState = _core.states.get(enemy_side.capitalize() + "Back")
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

	if Input.is_action_just_pressed("battle_charge") and _core.charge[state.side] > 0:
		_charge_queued = not _charge_queued
		_show_move_prompt()
		return

	if Input.is_action_just_pressed("battle_swap"):
		_log(_core.swap(state.id))
		_refresh_status_labels()
		_end_player_turn()
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
		var target := _core.pick_target(state, move)
		if target == null:
			_log("%s has no target left standing." % state.display_name)
			_end_player_turn()
			return
		_log(_core.resolve_and_apply(state, target, move,
			_charge_queued and _core.charge[state.side] > 0))
		_after_action()
		_end_player_turn()
	else:
		_pending_move = move
		_show_target_prompt(move)


func _poll_target_choice() -> void:
	var state := _pending_state
	var slot := ""
	if Input.is_action_just_pressed("battle_target_front"):
		slot = "front"
	elif Input.is_action_just_pressed("battle_target_back"):
		slot = "back"
	else:
		return

	var target := _core.pick_target(state, _pending_move, slot)
	if target == null:
		return

	_log(_core.resolve_and_apply(state, target, _pending_move,
		_charge_queued and _core.charge[state.side] > 0))
	_after_action()
	_end_player_turn()


func _end_player_turn() -> void:
	_awaiting_input = false
	_pending_state = null
	_pending_move = {}
	_charge_queued = false
	_prompt_label.text = ""
	_refresh_strip()
	_timer = 0.0


func _announce_result(text: String) -> void:
	_prompt_label.text = text
	_log(text)


func _log(text: String) -> void:
	_combat_log.text = text


func _refresh_strip() -> void:
	for child in _strip.get_children():
		child.queue_free()
	var upcoming := _core.queue.preview(QUEUE_PREVIEW)
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
	for id in _core.states:
		var state: CombatantState = _core.states[id]
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
	_player_charge_label.text = "Player Charge: %d" % _core.charge["player"]
	_enemy_charge_label.text = "Enemy Charge: %d" % _core.charge["enemy"]
