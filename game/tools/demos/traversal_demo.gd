extends Node3D
## M2 capture demo: walks straight east, far past the set dressing, to prove
## the camera (now parented to the traveler) keeps its framing and sharp band
## no matter how far the traveler strays from world (0,0,0). Then it runs the
## traveler through all 8 compass directions so the character controller and
## its walk-cycle animation are visible on camera, then drives it straight
## into CrateA to demonstrate collision against 3D level geometry — held
## input, but the traveler stalls once the box collider stops it.
##
## The far walk leads because farm/capture.sh's Movie Maker path has been
## observed to drop or coalesce frames once a capture runs past roughly ten
## real seconds (worse the longer the requested clip) — a capture-pipeline
## limit, not a game bug: a plain camera-orbit demo with no long static holds
## stays perfectly dense for 12s, and a direct (non-capture) run printing
## _traveler.global_position every frame confirms the sim itself never
## stalls. Front-loading the shot this tick needs to prove means it survives
## that window intact even if the compass loop and crate bump later in the
## same clip do not.
##
## Movie Maker has no real keyboard, so this presses and releases the same
## InputMap actions a player would via Input.action_press/action_release —
## it exercises player.gd's actual input path rather than teleporting the
## traveler around by hand.

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
# Far enough that a fixed, non-following camera would leave the traveler out
# of the tilt-shift's sharp band (tuned around ~24.5 units from camera) or
# out of frame entirely; camera-follow keeps the shot identical regardless.
const FAR_SECONDS := 4.0
# Held well past the walk itself so a QC frame sampled anywhere in this
# window shows the traveler at rest far from the origin, not mid-stride.
const FAR_REST_SECONDS := 4.0

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
var _far_step := -1


func _ready() -> void:
	var packed: PackedScene = load(scene_path)
	var world: Node = packed.instantiate()
	add_child(world)
	_traveler = world.get_node("Traveler")

	# Leads with the new content: walk straight east, far past the set
	# dressing, to show the camera keeps its framing on the traveler at any
	# distance. The traveler already starts at the origin, so no reset is
	# needed before this first step.
	_far_step = _steps.size()
	_steps.append([["move_right"], FAR_SECONDS])
	_steps.append([[], FAR_REST_SECONDS])

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
	if _step == _approach_step or _step == _far_step:
		_traveler.velocity = Vector3.ZERO
		_traveler.global_position = Vector3.ZERO
	_current_duration = _steps[_step][1]
	for action in _steps[_step][0]:
		Input.action_press(action)
		_held.append(action)
	_step += 1
