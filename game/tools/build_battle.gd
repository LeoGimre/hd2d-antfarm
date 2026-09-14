extends SceneTree
## Builds scenes/battle.tscn from code and saves it as a real scene file, same
## approach as build_diorama.gd. Run with:
##   godot --headless --path game --script res://tools/build_battle.gd
##
## M3's third box: real creatures from game/data/, in Front and Back slots.
##
## This file used to keep its own copy of battle.gd's TEAM table, and the two
## had to be hand-synced. They no longer exist: who stands where comes from
## game/data/encounters.json (design/encounters.md), and what stays here is the
## *board* — four slot positions and their per-slot label tuning, every value
## of which was arrived at by staring at QC frames and none of which has
## anything to do with which creature is standing there.
##
## Build a scene for a different encounter by passing its id:
##   godot --headless --path game --script res://tools/build_battle.gd -- <id>

const ARENA_SIZE := Vector2(11.0, 11.0)
const ARENA_TILE_UNITS := 2.0
const MARKER_RADIUS := 0.7
const MARKER_HEIGHT := 0.05
const CREATURE_HEIGHT := 1.5

## The encounter the scene is built for when the command line does not name one.
## battle.gd carries the same value for the same reason; keeping both is
## deliberate, since either file can be run without the other.
const DEFAULT_ENCOUNTER := "first_blood_unpaired"

var _encounter_id := DEFAULT_ENCOUNTER

## Back sits well to the *side* of Front, not mostly behind it. The original
## near-diagonal offset (Back = Front + (1.6, 1.8)) put Front and Back close
## enough together on screen, from this camera's angle, that Back's own
## InfoLabel fell inside Front's silhouette — the nearer, larger capsule won
## the depth test and hid it completely (only found by opening the QC
## frames: a floating blob with no readable text, immovable by any of the
## light/material/DOF tuning that would fix an actual overexposure). Widening
## the lateral offset and flattening the depth offset keeps Back farther from
## the board's center line without stacking it almost directly over Front.
const PLAYER_FRONT_POS := Vector3(1.1, 0.0, 1.8)
const PLAYER_BACK_POS := Vector3(3.6, 0.0, 2.6)
const ENEMY_FRONT_POS := Vector3(-1.1, 0.0, -1.3)
const ENEMY_BACK_POS := Vector3(-3.6, 0.0, -1.7)

const PLAYER_COLOR := Color(0.30, 0.55, 0.95)
const ENEMY_COLOR := Color(0.85, 0.30, 0.28)
const FRONT_MARKER_TINT := Color(1.0, 1.0, 1.0, 0.55)
const BACK_MARKER_TINT := Color(1.0, 1.0, 1.0, 0.28)




func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var encounter_id: String = args[0] if not args.is_empty() else DEFAULT_ENCOUNTER

	var root := Node3D.new()
	root.name = "Battle"
	root.set_script(load("res://scripts/battle.gd"))
	# Always set explicitly: an exported property equal to the script's default
	# is not serialised, so a scene built for a defaulted id would store nothing
	# and follow any later change to that default. See battle.gd.
	root.set("encounter_id", encounter_id)
	_encounter_id = encounter_id

	_add_environment(root)
	_add_lights(root)
	_add_arena(root)
	_add_slot_markers(root)
	_add_creatures(root)
	_add_camera(root)
	_add_ui(root)

	for child in root.get_children():
		_own_recursive(child, root)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("pack failed: %d" % err)
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute("res://scenes")
	err = ResourceSaver.save(packed, "res://scenes/battle.tscn")
	if err != OK:
		push_error("save failed: %d" % err)
		quit(1)
		return

	print("wrote res://scenes/battle.tscn")
	quit(0)


func _own_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_own_recursive(child, owner_node)


## Same HD-2D recipe as the diorama (bloom, ACES tonemap, tilt-shift) but
## darker and cooler — this is a battle cut away from the town, not the town
## itself, and pillar 6 still applies: it has to read as a lit diorama, not a
## flat UI screen with 3D props glued on.
func _add_environment(root: Node3D) -> void:
	var env := Environment.new()

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.06, 0.07, 0.14)
	sky_mat.sky_horizon_color = Color(0.22, 0.20, 0.28)
	sky_mat.ground_bottom_color = Color(0.05, 0.05, 0.07)
	sky_mat.ground_horizon_color = Color(0.18, 0.16, 0.20)
	sky_mat.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.85
	env.ambient_light_energy = 0.95

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0

	env.glow_enabled = true
	env.glow_intensity = 1.25
	env.glow_strength = 1.3
	env.glow_bloom = 0.4
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.65
	env.glow_hdr_scale = 2.2

	env.ssao_enabled = true
	env.ssao_intensity = 0.9
	env.ssao_radius = 1.0
	env.ssao_power = 1.4

	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)


func _add_lights(root: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.name = "Key"
	key.rotation_degrees = Vector3(-50.0, -140.0, 0.0)
	key.light_color = Color(0.86, 0.80, 1.0)
	key.light_energy = 1.1
	key.shadow_enabled = true
	key.shadow_blur = 2.6
	key.shadow_normal_bias = 1.4
	root.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.rotation_degrees = Vector3(-24.0, 60.0, 0.0)
	fill.light_color = Color(0.55, 0.62, 0.95)
	fill.light_energy = 0.25
	fill.shadow_enabled = false
	root.add_child(fill)

	# Two rim lights, one warm over the player line and one cold over the
	# enemy line, so the two sides read apart even before a viewer clocks the
	# creature colors — a cheap trick that pays for itself on a static shot.
	var player_rim := OmniLight3D.new()
	player_rim.name = "PlayerRim"
	player_rim.position = PLAYER_FRONT_POS + Vector3(0.0, 2.6, 1.5)
	player_rim.light_color = Color(0.55, 0.75, 1.0)
	player_rim.light_energy = 1.6
	player_rim.omni_range = 5.5
	root.add_child(player_rim)

	var enemy_rim := OmniLight3D.new()
	enemy_rim.name = "EnemyRim"
	enemy_rim.position = ENEMY_FRONT_POS + Vector3(0.0, 2.6, -1.5)
	enemy_rim.light_color = Color(1.0, 0.55, 0.45)
	# Both rims tuned down from tick 6's 3.2/8.0 — the Back slots are now
	# occupied by real, labeled creatures a few units from the Front rim
	# light, and that intensity/range blew Back out into an unreadable white
	# bloom (caught in QC, not on paper) instead of just kissing Front's edge.
	enemy_rim.light_energy = 1.6
	enemy_rim.omni_range = 5.5
	root.add_child(enemy_rim)


func _pixel_material(tex_path: String, uv: Vector2, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(tex_path)
	mat.albedo_color = tint
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.uv1_scale = Vector3(uv.x, uv.y, 1.0)
	mat.roughness = 0.95
	mat.metallic_specular = 0.05
	return mat


func _add_arena(root: Node3D) -> void:
	var plane := PlaneMesh.new()
	plane.size = ARENA_SIZE
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "ArenaFloor"
	floor_mi.mesh = plane
	floor_mi.material_override = _pixel_material(
		"res://assets/textures/stone.png", ARENA_SIZE / ARENA_TILE_UNITS, Color(0.42, 0.42, 0.50))
	root.add_child(floor_mi)


## Four flat discs, always present regardless of who's standing on them —
## design/combat.md's board is "two slots per side," and that's a claim about
## the board shape, not about who currently occupies it, so the Back slots
## have to be visible even while empty.
func _add_slot_markers(root: Node3D) -> void:
	var markers := Node3D.new()
	markers.name = "SlotMarkers"
	root.add_child(markers)

	markers.add_child(_marker("PlayerFrontMarker", PLAYER_FRONT_POS, FRONT_MARKER_TINT))
	markers.add_child(_marker("PlayerBackMarker", PLAYER_BACK_POS, BACK_MARKER_TINT))
	markers.add_child(_marker("EnemyFrontMarker", ENEMY_FRONT_POS, FRONT_MARKER_TINT))
	markers.add_child(_marker("EnemyBackMarker", ENEMY_BACK_POS, BACK_MARKER_TINT))


func _marker(node_name: String, pos: Vector3, tint: Color) -> Node3D:
	var cyl := CylinderMesh.new()
	cyl.top_radius = MARKER_RADIUS
	cyl.bottom_radius = MARKER_RADIUS
	cyl.height = MARKER_HEIGHT
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos + Vector3(0.0, MARKER_HEIGHT * 0.5, 0.0)
	return mi


## Real creatures — no sprites yet (M4's composable creature system), so
## each is still a capsule body plus floating text, but now loaded from
## game/data/ rather than hardcoded: a name, a type, and a live HP/Guard
## readout that battle.gd rewrites every turn.
func _add_creatures(root: Node3D) -> void:
	var creatures := Node3D.new()
	creatures.name = "Creatures"
	root.add_child(creatures)

	var positions := {
		"player_front": PLAYER_FRONT_POS,
		"player_back": PLAYER_BACK_POS,
		"enemy_front": ENEMY_FRONT_POS,
		"enemy_back": ENEMY_BACK_POS,
	}
	var db := CreatureDB.new()
	var team := EncounterDB.new().team(_encounter_id, db)
	for node_name in team:
		var info: Dictionary = team[node_name]
		var data := db.get_creature(info["creature_id"])
		var pos_key: String = "%s_%s" % [info["side"], info["slot"]]
		var pos: Vector3 = positions[pos_key]
		var color := PLAYER_COLOR if info["side"] == "player" else ENEMY_COLOR
		var is_back: bool = info["slot"] == "back"
		# Lifted clear of Front's own label so the two don't share screen
		# space at this camera angle. Enemy Back needed much less of this
		# once it got its own wide lateral offset from Enemy Front (below) —
		# the two no longer compete for the same screen space, and Enemy
		# Back sits close enough to the frame's top edge already that
		# lifting it as far as Player Back would crop it.
		var label_lift := 0.35
		if pos_key == "player_back":
			label_lift = 1.15
		elif pos_key == "enemy_back":
			label_lift = 0.5
		# Enemy Back moves *away* from camera as it moves off Front (Player
		# Back moves *toward* camera instead), so only it ends up small
		# enough on screen for a Front-sized label's glyphs to anti-alias
		# into a solid blob instead of legible letterforms — invisible on
		# paper, only caught by opening the QC frames, and immune to every
		# lighting/DOF knob tried first because it was never a lighting
		# problem. Scaling just that one label up compensates directly.
		var label_font_scale := 1.3 if pos_key == "enemy_back" else 1.0
		creatures.add_child(_creature(node_name, pos, color, data, label_lift, label_font_scale))


func _creature(node_name: String, pos: Vector3, color: Color, data: Dictionary,
		label_lift: float, label_font_scale: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	holder.position = pos

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = CREATURE_HEIGHT
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mat.metallic_specular = 0.05
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.0
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = capsule
	body.material_override = mat
	body.position = Vector3(0.0, CREATURE_HEIGHT * 0.5, 0.0)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	holder.add_child(body)

	# One label, two lines, rather than two stacked Label3Ds — the Back slots
	# are far enough from camera that every extra world-unit of label height
	# risks poking above the frame (see the crop this replaced). A single
	# label's own line spacing is tighter than any manual gap between two.
	var info := Label3D.new()
	info.name = "InfoLabel"
	info.text = "%s (%s)\nHP %d/%d   Guard %d/%d" % [
		data["display_name"], data["type"], data["max_hp"], data["max_hp"],
		data["max_guard"], data["max_guard"],
	]
	info.font_size = int(40 * label_font_scale)
	info.outline_size = int(9 * label_font_scale)
	info.position = Vector3(0.0, CREATURE_HEIGHT + label_lift, 0.0)
	info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info.no_depth_test = false
	holder.add_child(info)

	return holder


## A static, wide diorama camera — nothing to follow yet, so it just has to
## frame both lanes and both slot depths at once. Narrow-ish FOV keeps the
## flattened HD-2D look; the tilt-shift band is centered between the two
## Front slots, where the visible action (the flashing capsule) happens.
func _add_camera(root: Node3D) -> void:
	var cam := Camera3D.new()
	cam.name = "BattleCamera"
	cam.fov = 28.0
	cam.position = Vector3(0.0, 15.0, 19.0)
	cam.rotation_degrees = Vector3(-38.0, 0.0, 0.0)
	cam.current = true
	cam.far = 100.0

	var attrs := CameraAttributesPractical.new()
	# Far distance sits past the Enemy Back slot on purpose — Back now carries
	# its own readable HP/Guard label (this tick's data-driven roster), and
	# "legible in ten seconds of video" (GAME.md's standard) outranks a purist
	# near/far blur that would wash that label out.
	attrs.dof_blur_amount = 0.2
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 50.0
	attrs.dof_blur_far_transition = 10.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 17.0
	attrs.dof_blur_near_transition = 6.0
	cam.attributes = attrs

	root.add_child(cam)


## The turn queue strip: a full-width HBoxContainer anchored to the top of
## the screen. Centered via BoxContainer's own alignment rather than a
## wrapper, since it already spans the full width. battle.gd populates and
## re-populates its children every turn; this just gives it a home.
func _add_ui(root: Node3D) -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	root.add_child(layer)

	var strip := HBoxContainer.new()
	strip.name = "TurnQueueStrip"
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.anchor_top = 0.0
	strip.anchor_bottom = 0.0
	strip.offset_left = 0.0
	strip.offset_right = 0.0
	strip.offset_top = 22.0
	strip.offset_bottom = 110.0
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 14)
	layer.add_child(strip)

	var log_label := Label.new()
	log_label.name = "CombatLog"
	log_label.anchor_left = 0.0
	log_label.anchor_right = 1.0
	log_label.anchor_top = 1.0
	log_label.anchor_bottom = 1.0
	log_label.offset_left = 20.0
	log_label.offset_right = -20.0
	log_label.offset_top = -56.0
	log_label.offset_bottom = -16.0
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_label.add_theme_font_size_override("font_size", 22)
	log_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(log_label)

	# A second line, above CombatLog rather than replacing it — a player
	# needs to see "what just happened" (CombatLog) and "what I'm choosing
	# now" (this) on screen at once, not one overwriting the other.
	var prompt_label := Label.new()
	prompt_label.name = "PlayerPrompt"
	prompt_label.anchor_left = 0.0
	prompt_label.anchor_right = 1.0
	prompt_label.anchor_top = 1.0
	prompt_label.anchor_bottom = 1.0
	prompt_label.offset_left = 20.0
	prompt_label.offset_right = -20.0
	prompt_label.offset_top = -96.0
	prompt_label.offset_bottom = -60.0
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 22)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	layer.add_child(prompt_label)

	var player_charge := Label.new()
	player_charge.name = "PlayerCharge"
	player_charge.text = "Player Charge: 0"
	player_charge.anchor_left = 0.0
	player_charge.anchor_top = 0.0
	player_charge.offset_left = 20.0
	player_charge.offset_top = 130.0
	player_charge.add_theme_font_size_override("font_size", 18)
	player_charge.add_theme_color_override("font_color", PLAYER_COLOR)
	layer.add_child(player_charge)

	var enemy_charge := Label.new()
	enemy_charge.name = "EnemyCharge"
	enemy_charge.text = "Enemy Charge: 0"
	enemy_charge.anchor_left = 1.0
	enemy_charge.anchor_top = 0.0
	enemy_charge.offset_left = -220.0
	enemy_charge.offset_top = 130.0
	enemy_charge.add_theme_font_size_override("font_size", 18)
	enemy_charge.add_theme_color_override("font_color", ENEMY_COLOR)
	layer.add_child(enemy_charge)
