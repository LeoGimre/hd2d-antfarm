extends Node3D
## M3 capture demo: instances battle.tscn and plays the winning line.
##
## Until this tick the demo alternated move 1 and move 2 turn to turn — enough
## to prove input worked, but it played no particular line and the fight it
## produced was a loss. The box this milestone is actually on is "a battle that
## can be lost by playing badly and won by playing well," so the demo now plays
## the well half: the exact sequence tools/battle_sim.gd found by exhausting
## every line the player could take. Nothing shorter than five decisions wins
## this fight, and the naive line (every creature swinging melee at whatever is
## in Front) loses it — the sim prints both.
##
## Both numbers move when the encounter does, and they did: this scene fielded
## first_blood_unpaired until tick 56, where the shortest win was seven. Re-run
## `battle_sim.gd --search` after changing battle.gd's encounter and paste what
## it finds, rather than assuming the old line still applies.
##
## Input is synthesized with Input.action_press()/action_release(), matching
## battle.gd's own note on why: that updates the polled Input state the same way
## a real key would, which an _unhandled_input-style callback would never see.

@export var scene_path: String = "res://scenes/battle.tscn"

## Long enough that a captured clip reads as "choosing," not a blur of input.
## Lower than the 0.7 this demo used when it only had to show a few turns —
## the whole fight has to fit inside a capture short enough not to coalesce
## frames.
const INPUT_DELAY := 0.4
const DEMO_TURN_INTERVAL := 0.7

## The line battle_sim.gd found, in order. `move` is 1 or 2 into the creature's
## own move list (1 is always its melee move, 2 its ranged one, by
## game/data/creatures.json convention), `target` is the slot a ranged move
## aims at, and `charge` spends a banked Charge on that hit.
##
## Read as tactics: every creature on this board has exactly one correct target
## and every one of them is diagonal — Tidalpup answers the enemy Front,
## Rootshell answers the enemy Back — so the fight cannot be played correctly
## without going through the Front/Back reach rule. Rootshell's ranged move is
## the only thing that reaches Galewing while it hides in Back, and both Charges
## are spent on hits that a Break paid for.
##
## Five decisions. The unpaired roster this scene used to field needed seven and
## admitted no explainable plan at all; see design/first_blood_balance.md.
const LINE := [
	{"move": 1},
	{"move": 1},
	{"move": 2, "target": "back", "charge": true},
	{"move": 1},
	{"move": 1, "charge": true},
]

var _battle: Node3D
var _timer := 0.0
var _was_awaiting := false
var _index := 0
var _charge_pressed := false
var _held_action := ""
var _last_logged := ""

@onready var _headless: bool = DisplayServer.get_name() == "headless"


func _ready() -> void:
	var packed: PackedScene = load(scene_path)
	_battle = packed.instantiate()
	_battle.turn_interval = DEMO_TURN_INTERVAL
	add_child(_battle)


func _process(delta: float) -> void:
	# Release last frame's key before anything else — see _press().
	if _held_action != "":
		Input.action_release(_held_action)
		_held_action = ""
	_echo_log()

	var awaiting: bool = _battle.get("_awaiting_input")
	if not awaiting:
		_was_awaiting = false
		return
	if not _was_awaiting:
		_was_awaiting = true
		_timer = 0.0
	_timer += delta
	if _timer < INPUT_DELAY:
		return
	_timer = 0.0
	_act()


func _act() -> void:
	if _index >= LINE.size():
		return
	var step: Dictionary = LINE[_index]
	var pending_move: Dictionary = _battle.get("_pending_move")

	if not pending_move.is_empty():
		# battle.gd is mid-decision: it took the move and wants a target.
		_press("battle_target_" + str(step.get("target", "back")))
		_advance()
		return

	# Spending a Charge is declared before the move, so it costs this demo an
	# extra beat — which is the right shape anyway: on a clip you see the
	# prompt flip to "Charge: ON" before the hit that uses it lands.
	if step.get("charge", false) and not _charge_pressed:
		_charge_pressed = true
		_press("battle_charge")
		return

	_press("battle_move_" + str(step["move"]))
	# A melee move resolves the instant it is chosen (there is only one thing
	# it can hit); a ranged one comes back here for a target first.
	if int(step["move"]) == 1:
		_advance()


func _advance() -> void:
	_index += 1
	_charge_pressed = false


## Mirrors the on-screen combat log to stdout when there is no screen, so
## checking what the scene actually did is
##
##   godot --headless --path game --fixed-fps 30 --quit-after 900 \
##     res://tools/demos/battle_demo.tscn
##
## instead of a six-minute render and a squint at the frames. This tick needed
## exactly that: battle_sim.gd said the scripted line wins, the capture showed
## it not winning, and nothing in between could tell you why.
##
## It samples the label once a frame, so the killing blow's own line is the one
## thing it never prints: battle.gd writes that line and the "Player wins!"
## that replaces it inside a single _process call, and only the second survives
## to be read. Use battle_sim.gd --demo when you need the full sequence.
func _echo_log() -> void:
	if not _headless:
		return
	var label: Label = _battle.get("_combat_log")
	if label == null or label.text == _last_logged:
		return
	_last_logged = label.text
	print(label.text)


## Press now, release at the top of the next frame, and let the engine deliver
## the key to battle.gd's own _process — which runs after this one, because a
## child is processed after its parent and _battle is a child of this node.
##
## The obvious version of this — press, call _battle._process(0.0) by hand,
## release, all inline — is what the demo did before, and it was quietly wrong.
## Input.is_action_just_pressed() only asks "was this action pressed during the
## current frame"; it does not consult whether the key is still down. So
## releasing in the same frame does not un-arm it, and battle.gd's own _process,
## running later in that same frame, saw the press a second time. For a move
## that did not matter, because resolving a move clears _awaiting_input and
## battle.gd stops polling. For the Charge key it mattered completely: the
## toggle fired twice and landed back off, so the line's final Charge-empowered
## Root Slam went out as a plain one and the fight did not end. That cost a
## capture to find, and the sim could not have caught it — the line is correct;
## it was the typing that was wrong.
func _press(action: String) -> void:
	Input.action_press(action)
	_held_action = action
