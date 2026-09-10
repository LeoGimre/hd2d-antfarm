extends Node3D
## M2 capture demo: scripted input walks the traveler through all 8
## directions so the character controller and its walk-cycle animation are
## visible on camera, then drives it straight into CrateA to demonstrate
## collision against 3D level geometry — held input, but the traveler stalls
## once the box collider stops it.
##
## Movie Maker has no real keyboard, so this presses and releases the same
## InputMap actions a player would via Input.action_press/action_release —
## it exercises player.gd's actual input path rather than teleporting the
## traveler around by hand. The diorama camera is static (camera-follow is
## the next M2 checkbox, not this one), so the loop is sized small enough to
## stay inside its framing: two full compass loops, then a straight approach
## into CrateA (near the origin, at x=-2.9 z=1.6), then a rest to hold the
## stopped stance for QC frames.

@export var scene_path: String = "res://scenes/diorama.tscn"

const LEG_SECONDS := 0.5
const LOOPS := 2
# CrateA sits at roughly (-2.9, 1.6) in XZ; walking down first lines the
# traveler's Z up with the crate before the leftward approach hits its face.
const APPROACH_SECONDS := 0.6
# Held well past the ~0.6s it actually takes to reach the crate, so a QC
# frame sampled anywhere in the back half of this window shows the traveler
# stalled against it rather than mid-approach.
const BUMP_HOLD_SECONDS := 5.0
const REST_SECONDS := 1.5

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
var _current_duration := 0.0
var _step := 0
var _held: Array[String] = []
var _traveler: CharacterBody3D
var _approach_step := -1


func _ready() -> void:
	var packed: PackedScene = load(scene_path)
	var world: Node = packed.instantiate()
	add_child(world)
	_traveler = world.get_node("Traveler")

	for _i in LOOPS:
		for actions in DIRECTIONS:
			_steps.append([actions, LEG_SECONDS])
	# The compass loop now shares the scene with real colliders, so a leg that
	# clips a crate or the bench can leave the traveler off the octagon's
	# center instead of the net-zero drift the old, collision-free loop had.
	# Re-anchor to a known spot before the deliberate approach so the bump
	# into CrateA is deterministic regardless of where the loop left off.
	_approach_step = _steps.size()
	_steps.append([["move_down"], APPROACH_SECONDS])
	_steps.append([["move_left"], BUMP_HOLD_SECONDS])
	_steps.append([[], REST_SECONDS])

	_advance()


func _process(delta: float) -> void:
	_t += delta
	if _t >= _current_duration:
		_advance()


func _advance() -> void:
	for action in _held:
		Input.action_release(action)
	_held.clear()
	_t = 0.0
	if _step >= _steps.size():
		# Nothing left to hold against; stay idle at wherever the last step left off.
		_current_duration = INF
		return
	if _step == _approach_step:
		_traveler.velocity = Vector3.ZERO
		_traveler.global_position = Vector3.ZERO
	_current_duration = _steps[_step][1]
	for action in _steps[_step][0]:
		Input.action_press(action)
		_held.append(action)
	_step += 1
