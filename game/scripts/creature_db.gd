class_name CreatureDB
extends RefCounted
## Loads game/data/creatures.json and game/data/moves.json. Adding a fifth
## creature or a ninth move is a data edit to those files, never a change
## here — the pillar that the roster must stay cheap to grow applies to
## moves and types exactly as much as it applies to creatures.

var _creatures: Dictionary = {}
var _moves: Dictionary = {}


func _init(creatures_path: String = "res://data/creatures.json",
		moves_path: String = "res://data/moves.json") -> void:
	var creatures_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(creatures_path))
	for entry in creatures_data["creatures"]:
		_creatures[entry["id"]] = entry

	var moves_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(moves_path))
	for entry in moves_data["moves"]:
		_moves[entry["id"]] = entry


func get_creature(id: String) -> Dictionary:
	return _creatures[id]


func get_move(id: String) -> Dictionary:
	return _moves[id]
