class_name EncounterDB
extends RefCounted
## Loads game/data/encounters.json: who fights whom, as content.
##
## Shaped like CreatureDB on purpose — a RefCounted that parses one file in
## _init() and answers lookups, with no Node reference anywhere, which is what
## makes it cheap to put under test. Adding a fifth encounter is a data edit.
##
## Node names are derived here and never listed in the data: "PlayerFront" is
## side.capitalize() + slot.capitalize(), the convention battle.gd already
## relies on. Putting them in the file would reintroduce exactly the hand-synced
## mapping this class exists to delete.

const SLOTS := ["front", "back"]
const SIDES := ["player", "enemy"]

var _encounters: Dictionary = {}


func _init(path: String = "res://data/encounters.json") -> void:
	var raw := FileAccess.get_file_as_string(path)
	assert(raw != "", "encounters: could not read %s" % path)
	var data: Dictionary = JSON.parse_string(raw)
	assert(data != null and data.has("encounters"),
		"encounters: %s is not an object with an \"encounters\" array" % path)
	for entry in data["encounters"]:
		_encounters[entry["id"]] = entry


func has(id: String) -> bool:
	return _encounters.has(id)


func get_encounter(id: String) -> Dictionary:
	assert(_encounters.has(id),
		"encounters: no encounter \"%s\" — the file has %s" % [id, ", ".join(ids())])
	return _encounters[id]


func ids() -> Array:
	return _encounters.keys()


## The table BattleCore._init() wants: node name -> {creature_id, side, slot}.
##
## db is optional and used only to validate creature ids up front. It is worth
## the argument: a creature id typo'd in an encounter is going to be one of the
## most common mistakes this project makes, and without this the failure is a
## bare missing-key error from somewhere inside CreatureDB with neither the
## encounter nor the creature named. design/encounters.md: it should cost ten
## seconds, not ten minutes.
func team(id: String, db: CreatureDB = null) -> Dictionary:
	var entry := get_encounter(id)
	var out := {}
	for side in SIDES:
		assert(entry.has(side), "encounters: %s has no \"%s\" array" % [id, side])
		var seen := {}
		for member in entry[side]:
			var slot: String = member["slot"]
			assert(slot in SLOTS,
				"encounters: %s/%s stands in \"%s\", which is not a slot" % [id, side, slot])
			assert(not seen.has(slot),
				"encounters: %s has two creatures in %s %s" % [id, side, slot])
			seen[slot] = true
			var creature_id: String = member["creature"]
			if db != null:
				# One message naming both halves. Without it the failure is a bare
				# missing-key error from inside CreatureDB, with neither the
				# encounter nor the creature named.
				var missing := "encounters: %s puts \"%s\" in %s %s, and no such creature is in creatures.json" % [id, creature_id, side, slot]
				assert(db.has_creature(creature_id), missing)
			out[node_name(side, slot)] = {
				"creature_id": creature_id, "side": side, "slot": slot,
			}
	assert(not out.is_empty(), "encounters: %s fields nobody" % id)
	return out


static func node_name(side: String, slot: String) -> String:
	return side.capitalize() + slot.capitalize()
