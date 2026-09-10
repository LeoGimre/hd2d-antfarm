extends Node3D
## M3 capture demo: instances battle.tscn and drives the player's own turns
## with synthesized input.
##
## Before this tick every combatant picked its own move and target, so the
## scene's own timer was enough to carry a capture end to end. Now a
## PlayerFront/PlayerBack turn stops the clock and waits for a real choice —
## left alone, this demo would just sit frozen on the first prompt. Input is
## synthesized with Input.action_press()/action_release(), matching
## battle.gd's own note on why: that updates the polled Input state the same
## way a real key would, which an _unhandled_input-style callback would
## never see.

@export var scene_path: String = "res://scenes/battle.tscn"

# Long enough that a captured clip reads as "choosing," not a blur of input.
const INPUT_DELAY := 0.7

var _battle: Node3D
var _timer := 0.0
var _was_awaiting := false
var _move_toggle := false


func _ready() -> void:
	var packed: PackedScene = load(scene_path)
	_battle = packed.instantiate()
	add_child(_battle)


func _process(delta: float) -> void:
	var awaiting: bool = _battle.get("_awaiting_input")
	if not awaiting:
		_was_awaiting = false
		return
	if not _was_awaiting:
		_was_awaiting = true
		_timer = 0.0
	_timer += delta
	if _timer < INPUT_DELAY:
		return
	_timer = 0.0
	_act()


## Alternates move 1/move 2 turn to turn so a capture shows both a melee
## choice (no target prompt) and a ranged one (front/back target prompt)
## rather than just the simpler of the two.
func _act() -> void:
	var pending_move: Dictionary = _battle.get("_pending_move")
	if pending_move.is_empty():
		_move_toggle = not _move_toggle
		var action := "battle_move_2" if _move_toggle else "battle_move_1"
		Input.action_press(action)
		_battle._process(0.0)
		Input.action_release(action)
	else:
		Input.action_press("battle_target_back")
		_battle._process(0.0)
		Input.action_release("battle_target_back")
