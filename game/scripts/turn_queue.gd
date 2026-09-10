class_name TurnQueue
extends RefCounted
## The deterministic turn-order queue specified in design/combat.md: no
## randomness, no hidden agility rolls — a combatant's next scheduled time is
## always `1000 / Speed`, so the same roster produces the same order forever.
## This class only tracks *order*; it knows nothing about HP, Guard, or moves,
## because M3's second box is proving the queue and the Front/Back board are
## readable, not resolving a fight.

class Combatant:
	var id: String
	var display_name: String
	var side: String
	var speed: float
	var scheduled_time: float

	func _init(p_id: String, p_name: String, p_side: String, p_speed: float) -> void:
		id = p_id
		display_name = p_name
		side = p_side
		speed = p_speed
		scheduled_time = 1000.0 / speed


var combatants: Array[Combatant] = []


func add_combatant(id: String, display_name: String, side: String, speed: float) -> void:
	combatants.append(Combatant.new(id, display_name, side, speed))


## Commits one turn: the soonest-scheduled combatant acts now and is
## rescheduled `1000 / Speed` past the moment it just acted at (not past
## whatever the caller's wall-clock "now" is), matching combat.md's formula.
func advance() -> Combatant:
	var actor := _soonest_real()
	actor.scheduled_time += 1000.0 / actor.speed
	return actor


## Returns the next `count` turns without mutating real state — this is what
## the on-screen queue strip renders, so a player can plan ahead of the turn
## that's actually about to resolve. Simulated on a scratch time-per-combatant
## map so `advance()` remains the only thing that ever changes real state.
func preview(count: int) -> Array[Combatant]:
	var times: Dictionary = {}
	for c in combatants:
		times[c] = c.scheduled_time

	var result: Array[Combatant] = []
	for _i in range(count):
		var actor: Combatant = null
		for c in combatants:
			if actor == null or times[c] < times[actor]:
				actor = c
		result.append(actor)
		times[actor] += 1000.0 / actor.speed
	return result


func _soonest_real() -> Combatant:
	var best: Combatant = null
	for c in combatants:
		if best == null or c.scheduled_time < best.scheduled_time:
			best = c
	return best
