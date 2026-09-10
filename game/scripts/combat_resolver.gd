class_name CombatResolver
extends RefCounted
## Pure move resolution for design/combat.md's Front/Back and Guard/Charge
## rules. `resolve()` takes a snapshot of the fight and returns what would
## happen without touching anything; `apply()` is the only place state
## actually changes. Kept free of Node/scene references on purpose — M3's
## fifth box puts this under unit test, and a pure function is the thing
## that's cheap to test without a running battle scene.

const FRONT_DAMAGE_BONUS := 2.0
const BACK_TARGET_MULTIPLIER := 0.75
const CHARGE_MULTIPLIER := 1.5
const BROKEN_TAKES_MORE_DAMAGE := 1.5
const RESIST_HEAL := 2
const GUARD_DAMAGE_BY_EFFECTIVENESS := {"weak": 2, "neutral": 1, "resist": 0}


class Result:
	var effectiveness: String
	var hp_damage: int
	var guard_damage: int
	var heal: int
	var charge_spent: bool
	var breaks_defender: bool


## attacker_slot/move/effectiveness describe the attack; defender is read but
## never written here (see apply()). charge_available is whether the
## attacker's side has a banked Charge to spend on this hit — design/combat.md
## lets a player declare that at move time; until there is a player turn to
## declare it in, the caller decides on the attacker's behalf.
static func resolve(attacker_slot: String, defender: CombatantState, move: Dictionary,
		effectiveness: String, charge_available: bool) -> Result:
	var result := Result.new()
	result.effectiveness = effectiveness
	result.charge_spent = charge_available

	var damage: float = move["power"]
	if attacker_slot == "front":
		damage += FRONT_DAMAGE_BONUS
	if move["category"] == "ranged" and defender.slot == "back":
		damage *= BACK_TARGET_MULTIPLIER
	if charge_available:
		damage *= CHARGE_MULTIPLIER
	if defender.broken:
		damage *= BROKEN_TAKES_MORE_DAMAGE
	result.hp_damage = int(round(damage))

	result.guard_damage = GUARD_DAMAGE_BY_EFFECTIVENESS[effectiveness]
	result.heal = RESIST_HEAL if effectiveness == "resist" else 0
	result.breaks_defender = not defender.broken and defender.guard > 0 \
		and result.guard_damage >= defender.guard

	return result


## The only place a Result mutates real state. Broken creatures lose their
## next scheduled turn — that is enforced by the caller (battle.gd), which
## owns the turn queue this class knows nothing about.
static func apply(defender: CombatantState, result: Result) -> void:
	defender.guard = max(0, defender.guard - result.guard_damage)
	if result.breaks_defender:
		defender.broken = true
	defender.hp = clampi(defender.hp - result.hp_damage + result.heal, 0, defender.max_hp)
	if defender.hp <= 0:
		defender.defeated = true
