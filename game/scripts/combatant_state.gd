class_name CombatantState
extends RefCounted
## One creature's runtime battle state: HP, Guard, Broken/Defeated, and which
## of its two moves comes next. Deliberately separate from
## TurnQueue.Combatant (order-only, see turn_queue.gd) — the queue still
## knows nothing about HP or moves; this is the thing that knows nothing
## about turn order.

var id: String
var display_name: String
var side: String
var slot: String # "front" | "back"
var ctype: String
var max_hp: int
var hp: int
var max_guard: int
var guard: int
var move_ids: Array
var broken := false
var defeated := false

var _next_is_melee := true


func _init(p_id: String, p_display_name: String, p_side: String, p_slot: String, p_ctype: String,
		p_max_hp: int, p_max_guard: int, p_move_ids: Array) -> void:
	id = p_id
	display_name = p_display_name
	side = p_side
	slot = p_slot
	ctype = p_ctype
	max_hp = p_max_hp
	hp = p_max_hp
	max_guard = p_max_guard
	guard = p_max_guard
	move_ids = p_move_ids


## Alternates melee/ranged on every call — move_ids[0] is always the melee
## move and move_ids[1] the ranged one, by game/data/creatures.json
## convention. There is no player input yet (that is M3's next box), so this
## stands in for a choice; a short capture still shows both halves of the
## Front/Back rule instead of one move on repeat.
func next_move_id() -> String:
	var chosen: String = move_ids[0] if _next_is_melee else move_ids[1]
	_next_is_melee = not _next_is_melee
	return chosen
