extends Node3D
## Battle scene root — M3's third box: a real four-creature roster, loaded
## from game/data/, fighting with design/combat.md's Guard/Break/Charge and
## Front/Back rules actually operating instead of just rendering. There is
## still no player input (that's the next box, "a battle that can be lost by
## playing badly and won by playing well") — each combatant's turn picks its
## own move and target so the systems are visibly live on a captured clip.

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
@onready var _player_charge_label: Label = $UI/PlayerCharge
@onready var _enemy_charge_label: Label = $UI/EnemyCharge

var _queue := TurnQueue.new()
var _db := CreatureDB.new()
var _types := TypeChart.new()
var _states: Dictionary = {} # id -> CombatantState
var _charge := {"player": 0, "enemy": 0}
var _timer := 0.0


func _ready() -> void:
	for id in TEAM:
		var info: Dictionary = TEAM[id]
		var data := _db.get_creature(info["creature_id"])
		var state := CombatantState.new(
			id, data["display_name"], info["side"], info["slot"], data["type"],
			data["max_hp"], data["max_guard"], data["moves"])
		_states[id] = state
		# Speeds come straight from data now, not a hand-picked ratio — the
		# roster itself (11/9/14/7) already spreads enough that the queue
		# visibly reorders instead of ping-ponging.
		_queue.add_combatant(id, state.display_name, state.side, float(data["speed"]))

	_refresh_strip()
	_refresh_status_labels()
	_refresh_charge_labels()


func _process(delta: float) -> void:
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

	var move_id := state.next_move_id()
	var move := _db.get_move(move_id)
	var target := _pick_target(state, move)
	if target == null:
		_log("%s has no target left standing." % state.display_name)
		return

	var charge_available: bool = _charge[state.side] > 0
	var effectiveness := _types.effectiveness(state.ctype, target.ctype)
	var result := CombatResolver.resolve(state.slot, target, move, effectiveness, charge_available)
	if charge_available:
		_charge[state.side] -= 1
	CombatResolver.apply(target, result)
	if result.breaks_defender:
		_charge[state.side] += 1

	_log(_describe(state, target, move, result))
	_refresh_status_labels()
	_refresh_charge_labels()


## Melee can only reach the opposing Front slot (or Back, if Front has
## fallen); ranged can reach either, and is aimed at Back on purpose so a
## capture actually shows the 25%-less-damage rule instead of relying on the
## viewer to trust it exists.
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
