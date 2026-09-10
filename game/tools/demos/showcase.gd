extends Node3D
## M1 capture demo: a slow orbit across the diorama.
##
## Demo scenes exist so every clip is deterministic. Movie Maker advances time in
## fixed steps, so driving motion from an accumulated delta gives identical
## framing on every run — no capture jitter, no "it looked fine locally".

@export var scene_path: String = "res://scenes/diorama.tscn"
@export var drift_seconds: float = 12.0

## Orbit geometry. The camera always looks at the subject, so framing can never
## slide off the way a hand-tuned path does.
const ORBIT_RADIUS_START := 22.5
const ORBIT_RADIUS_END := 20.0
const ORBIT_HEIGHT := 13.5
const ORBIT_SWING_DEG := 7.0

var _t: float = 0.0
var _camera: Camera3D
# Sprite3D in M1, CharacterBody3D once the traveler grew a controller (M2) —
# either way it's the thing the camera orbits and the thing that idle-bobs.
var _traveler: Node3D
var _target: Vector3 = Vector3(0.0, 0.9, 0.0)
var _traveler_home: Vector3


func _ready() -> void:
	var packed: PackedScene = load(scene_path)
	var world: Node = packed.instantiate()
	add_child(world)

	_camera = world.get_node_or_null("DioramaCamera") as Camera3D
	_traveler = world.get_node_or_null("Traveler") as Node3D
	if _camera == null:
		push_error("showcase: no DioramaCamera in %s" % scene_path)
		return
	if _traveler != null:
		_traveler_home = _traveler.position
		_target = _traveler_home + Vector3(0.0, 0.9, 0.0)

	_place_camera(0.0)


func _process(delta: float) -> void:
	_t += delta
	_place_camera(_t / max(drift_seconds, 0.001))

	# A little idle bob so the traveler doesn't read as a decal.
	if _traveler != null:
		_traveler.position = _traveler_home + Vector3(0.0, sin(_t * 2.2) * 0.035, 0.0)


func _place_camera(phase: float) -> void:
	if _camera == null:
		return
	var swing: float = sin(phase * TAU * 0.5)
	var angle: float = deg_to_rad(swing * ORBIT_SWING_DEG)
	var radius: float = lerp(ORBIT_RADIUS_START, ORBIT_RADIUS_END, clampf(phase, 0.0, 1.0))
	_camera.position = _target + Vector3(sin(angle) * radius, ORBIT_HEIGHT, cos(angle) * radius)
	_camera.look_at(_target, Vector3.UP)
