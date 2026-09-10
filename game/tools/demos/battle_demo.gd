extends Node3D
## M3 capture demo: instances battle.tscn and lets it run.
##
## The scene's own timer auto-advances the turn queue and flashes whoever
## acts, so there is nothing left for a demo script to drive — this exists
## only so capture.sh has a scene under tools/demos/ to point at, matching
## the project's convention of demos wrapping the real scene rather than the
## real scene carrying capture-only logic itself.

@export var scene_path: String = "res://scenes/battle.tscn"


func _ready() -> void:
	var packed: PackedScene = load(scene_path)
	add_child(packed.instantiate())
