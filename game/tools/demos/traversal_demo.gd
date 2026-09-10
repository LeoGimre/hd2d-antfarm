extends Node3D
## M2 capture demo: scripted input walks the traveler through all 8
## directions so the character controller and its walk-cycle animation are
## visible on camera.
##
## Movie Maker has no real keyboard, so this presses and releases the same
## InputMap actions a player would via Input.action_press/action_release —
## it exercises player.gd's actual input path rather than teleporting the
## traveler around by hand. The diorama camera is static (camera-follow is
## the next M2 checkbox, not this one), so the loop is sized small enough to
## stay inside its framing: two full compass loops, then a rest so the idle
## pose shows too.

@export var scene_path: String = "res://scenes/diorama.tscn"

const LEG_SECONDS := 0.5
const LOOPS := 2
const REST_SECONDS := 4.0

# Ordered clockwise from north; diagonals are two actions held together.
const DIRECTIONS: Array = [
	["move_up"],
	["move_up", "move_right"],
	["move_right"],
	["move_down", "move_right"],
	["move_down"],
	["move_down", "move_left"],
	["move_left"],
	["move_up", "move_left"],
]

var _steps: Array = []
var _t := 0.0
var _step := 0
var _held: Array[String] = []


func _ready() -> void:
	var packed: PackedScene = load(scene_path)
	var world: Node = packed.instantiate()
	add_child(world)

	for _i in LOOPS:
		for actions in DIRECTIONS:
			_steps.append([actions, LEG_SECONDS])
	_steps.append([[], REST_SECONDS])

	_advance()


func _process(delta: float) -> void:
	_t += delta
	if _step < _steps.size() and _t >= _steps[_step][1]:
		_advance()


func _advance() -> void:
	for action in _held:
		Input.action_release(action)
	_held.clear()
	_t = 0.0
	if _step >= _steps.size():
		return
	for action in _steps[_step][0]:
		Input.action_press(action)
		_held.append(action)
	_step += 1
