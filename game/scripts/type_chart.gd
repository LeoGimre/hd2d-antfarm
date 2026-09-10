class_name TypeChart
extends RefCounted
## Loads game/data/types.json and answers the one question design/combat.md
## needs of it: how much Guard damage does an attack of one type do to a
## defender of another. The chart's actual shape (which types exist, what
## beats what) is data, per the pillar that content growth must never require
## a code change — this class only knows how to look a chart up.

var _types: Dictionary = {}


func _init(path: String = "res://data/types.json") -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_types = parsed["types"]


## "weak" (attacker's type is the defender's listed weak_to — 2 Guard damage),
## "resist" (attacker's type is the defender's listed resists — 0 Guard damage,
## defender heals), or "neutral" (1 Guard damage) otherwise.
func effectiveness(attacker_type: String, defender_type: String) -> String:
	var entry: Dictionary = _types.get(defender_type, {})
	if entry.get("weak_to", "") == attacker_type:
		return "weak"
	if entry.get("resists", "") == attacker_type:
		return "resist"
	return "neutral"
