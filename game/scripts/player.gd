extends CharacterBody3D
## The traveler's ground-plane controller.
##
## Movement is flat (XZ only, no gravity) — this is a diorama walker, not a
## platformer, and the ground has no collision shape to fall onto anyway.
## Input actions come from the InputSetup autoload (scripts/input_setup.gd),
## so both real keyboard play and a scripted demo driving Input.action_press
## exercise this exact same path.

const SPEED := 3.2
const STOPPED_EPSILON := 0.05

@onready var _sprite: AnimatedSprite3D = get_node_or_null("Sprite")


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector3(input_dir.x, 0.0, input_dir.y) * SPEED
	move_and_slide()

	if _sprite == null:
		return
	var wanted := "walk" if velocity.length() > STOPPED_EPSILON else "idle"
	if _sprite.animation != wanted:
		_sprite.animation = wanted
		_sprite.play()
