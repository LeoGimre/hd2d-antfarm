extends Node3D
## Battle scene root — M3's second box: renders design/combat.md's turn-order
## queue and Front/Back board against a placeholder pair of creatures. There
## is no move resolution or Guard yet (those are the next two boxes, in
## order); this only has to prove the state is readable — a viewer should be
## able to predict who acts next from the strip, and see whose turn just
## resolved from the capsule that flashes.

const QUEUE_PREVIEW := 6
# Slow enough to read as discrete turns on a captured clip, not a blur.
const TURN_INTERVAL := 1.35
const FLASH_PEAK := 2.2
const FLASH_UP_SECONDS := 0.15
const FLASH_DOWN_SECONDS := 0.55

const CHIP_COLORS := {
	"player": Color(0.30, 0.55, 0.95),
	"enemy": Color(0.85, 0.30, 0.28),
}

@onready var _strip: HBoxContainer = $UI/TurnQueueStrip
@onready var _creatures: Node3D = $Creatures

var _queue := TurnQueue.new()
var _timer := 0.0


func _ready() -> void:
	# Speeds deliberately not a clean ratio (12:8 = 3:2) so the queue visibly
	# reorders instead of just alternating turn-for-turn — the point of a
	# captured clip here is proving order is speed-driven, not a coin flip.
	_queue.add_combatant("PlayerFront", "Emberfin", "player", 12.0)
	_queue.add_combatant("EnemyFront", "Grimshell", "enemy", 8.0)
	_refresh_strip()


func _process(delta: float) -> void:
	_timer += delta
	if _timer < TURN_INTERVAL:
		return
	_timer = 0.0
	var actor := _queue.advance()
	_refresh_strip()
	_flash(actor.id)


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
