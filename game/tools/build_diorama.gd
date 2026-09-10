extends SceneTree
## Builds scenes/diorama.tscn from code and saves it as a real scene file.
##
## Hand-writing .tscn resource ids is error-prone; letting the engine serialize a
## live node tree is not. Run with:
##   godot --headless --path game --script res://tools/build_diorama.gd
## The result is a normal scene, editable in the editor and by hand afterwards.

const SPRITE_PIXEL_SIZE := 0.05   # 32px tall sprite -> 1.6 world units
const TRAVELER_HEIGHT := 32.0 * SPRITE_PIXEL_SIZE

## World units covered by one texture tile. One grass tile is roughly a stride;
## one masonry tile is about a character's height. Keeping this explicit is what
## stops textures from stretching into plank soup on non-square meshes.
const GRASS_TILE_UNITS := 2.0
const STONE_TILE_UNITS := 1.6
## The path is seen at a shallower angle than the props, so it needs larger
## tiles or the masonry mips away into featureless gravel.
const PATH_TILE_UNITS := 2.6


func _initialize() -> void:
	var root := Node3D.new()
	root.name = "Diorama"

	_add_environment(root)
	_add_lights(root)
	_add_ground(root)
	_add_set_dressing(root)
	var traveler := _add_traveler(root)
	_add_camera(traveler)

	# Ownership is what makes children serialize into the packed scene.
	for child in root.get_children():
		_own_recursive(child, root)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("pack failed: %d" % err)
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute("res://scenes")
	err = ResourceSaver.save(packed, "res://scenes/diorama.tscn")
	if err != OK:
		push_error("save failed: %d" % err)
		quit(1)
		return

	print("wrote res://scenes/diorama.tscn")
	quit(0)


func _own_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_own_recursive(child, owner_node)


## The HD-2D look lives here: heavy bloom, filmic tonemap, and a tilt-shift
## depth of field that keeps a narrow band sharp and melts everything else.
func _add_environment(root: Node3D) -> void:
	var env := Environment.new()

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.24, 0.36, 0.60)
	sky_mat.sky_horizon_color = Color(0.70, 0.72, 0.78)
	sky_mat.ground_bottom_color = Color(0.30, 0.31, 0.36)
	sky_mat.ground_horizon_color = Color(0.62, 0.60, 0.60)
	sky_mat.sun_angle_max = 24.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	# Generous ambient on purpose. Crushed black shadows are the fastest way to
	# make this look like an untextured prototype instead of a lit diorama.
	env.ambient_light_energy = 1.30

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0

	# Bloom. Octopath's glow is unsubtle on purpose.
	env.glow_enabled = true
	env.glow_intensity = 1.15
	env.glow_strength = 1.2
	env.glow_bloom = 0.35
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.72
	env.glow_hdr_scale = 2.2

	env.ssao_enabled = true
	env.ssao_intensity = 0.9
	env.ssao_radius = 1.0
	env.ssao_power = 1.4

	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.18
	env.adjustment_brightness = 1.0

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.62, 0.68, 0.80)
	env.fog_density = 0.008
	env.fog_sky_affect = 0.25

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)


func _add_lights(root: Node3D) -> void:
	# Warm key.
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-44.0, -118.0, 0.0)
	sun.light_color = Color(1.0, 0.88, 0.70)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_blur = 2.6
	sun.shadow_normal_bias = 1.4
	sun.directional_shadow_max_distance = 70.0
	root.add_child(sun)

	# Cool fill from the opposite side, no shadows. This is the whole trick behind
	# the HD-2D palette: shadows go blue instead of black, and the warm/cool split
	# does more for the look than any post-processing effect.
	var fill := DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.rotation_degrees = Vector3(-28.0, 62.0, 0.0)
	fill.light_color = Color(0.68, 0.77, 0.94)
	fill.light_energy = 0.30
	fill.shadow_enabled = false
	root.add_child(fill)

	# The practical: a lantern that justifies the warm pool of light and gives
	# the bloom something to bite on.
	var lantern := OmniLight3D.new()
	lantern.name = "LanternLight"
	lantern.position = Vector3(-3.4, 2.45, 1.6)
	lantern.light_color = Color(1.0, 0.70, 0.34)
	lantern.light_energy = 4.0
	lantern.omni_range = 9.0
	lantern.omni_attenuation = 1.5
	lantern.shadow_enabled = true
	root.add_child(lantern)


func _pixel_material(tex_path: String, uv: Vector2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(tex_path)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.uv1_scale = Vector3(uv.x, uv.y, 1.0)
	mat.roughness = 0.95
	mat.metallic_specular = 0.05
	return mat


func _add_ground(root: Node3D) -> void:
	var ground_size := Vector2(70.0, 70.0)
	var plane := PlaneMesh.new()
	plane.size = ground_size
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = _pixel_material(
		"res://assets/textures/grass.png", ground_size / GRASS_TILE_UNITS)
	root.add_child(ground)

	# A stone path, lifted a hair to avoid z-fighting with the grass.
	var path_size := Vector2(5.0, 70.0)
	var path_mesh := PlaneMesh.new()
	path_mesh.size = path_size
	var path := MeshInstance3D.new()
	path.name = "StonePath"
	path.mesh = path_mesh
	path.position = Vector3(0.0, 0.012, 0.0)
	path.material_override = _pixel_material(
		"res://assets/textures/stone.png", path_size / PATH_TILE_UNITS)
	root.add_child(path)


## A set-dressing block that actually blocks: a StaticBody3D carries the visual
## mesh and a matching box collider, so the traveler's move_and_slide sees it
## instead of walking straight through.
func _block(node_name: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = box
	mi.material_override = _pixel_material(
		"res://assets/textures/stone.png",
		Vector2(size.x, size.y) / STONE_TILE_UNITS)

	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape

	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.add_child(mi)
	body.add_child(collider)
	return body


## Depth layering. Tilt-shift only reads as tilt-shift if there is something
## near and something far to go soft. Props are kept at or below the traveler's
## height so he never reads as a doll among giants.
func _add_set_dressing(root: Node3D) -> void:
	var dressing := Node3D.new()
	dressing.name = "SetDressing"

	# Far: a low wall and pillars behind the subject.
	dressing.add_child(_block("WallBack", Vector3(0, 1.2, -13.0), Vector3(30, 2.4, 1.0)))
	dressing.add_child(_block("PillarBackL", Vector3(-7.0, 2.1, -10.5), Vector3(1.4, 4.2, 1.4)))
	dressing.add_child(_block("PillarBackR", Vector3(7.0, 2.1, -10.5), Vector3(1.4, 4.2, 1.4)))
	dressing.add_child(_block("StepsBack", Vector3(0, 0.22, -8.6), Vector3(10.0, 0.44, 1.8)))

	# Mid: low crates near the traveler, for the sun to throw shadows off.
	dressing.add_child(_block("CrateA", Vector3(-2.9, 0.5, 1.6), Vector3(1.0, 1.0, 1.0)))
	dressing.add_child(_block("CrateB", Vector3(-2.85, 1.35, 1.65), Vector3(0.7, 0.7, 0.7)))
	dressing.add_child(_block("CrateC", Vector3(3.4, 0.55, -1.2), Vector3(1.1, 1.1, 1.1)))
	dressing.add_child(_block("BenchR", Vector3(4.6, 0.3, 3.2), Vector3(2.4, 0.6, 0.9)))

	# Lantern post under the practical light.
	dressing.add_child(_block("LanternPost", Vector3(-3.4, 1.15, 1.6), Vector3(0.2, 2.3, 0.2)))

	# The lantern head itself: emissive, so the bloom has an actual source in
	# frame rather than a glow with nothing behind it.
	var head := BoxMesh.new()
	head.size = Vector3(0.42, 0.5, 0.42)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(1.0, 0.74, 0.38)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.60, 0.22)
	glass.emission_energy_multiplier = 1.8
	var head_mi := MeshInstance3D.new()
	head_mi.name = "LanternHead"
	head_mi.mesh = head
	head_mi.position = Vector3(-3.4, 2.45, 1.6)
	head_mi.material_override = glass
	dressing.add_child(head_mi)

	# Near: foreground blockers that sit in front of the focal plane and blur out.
	dressing.add_child(_block("FgPillarL", Vector3(-8.0, 2.3, 8.6), Vector3(1.6, 4.6, 1.6)))
	dressing.add_child(_block("FgPillarR", Vector3(8.0, 2.3, 8.6), Vector3(1.6, 4.6, 1.6)))

	root.add_child(dressing)


func _build_traveler_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", load("res://assets/sprites/traveler_idle.png"))

	# Walk cycle: the cloak hides most of the legs, so the boots stepping
	# under the hem is enough motion to read as a stride at 12fps.
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 6.0)
	frames.add_frame("walk", load("res://assets/sprites/traveler_walk_a.png"))
	frames.add_frame("walk", load("res://assets/sprites/traveler_idle.png"))
	frames.add_frame("walk", load("res://assets/sprites/traveler_walk_b.png"))
	frames.add_frame("walk", load("res://assets/sprites/traveler_idle.png"))
	return frames


func _add_traveler(root: Node3D) -> CharacterBody3D:
	# CharacterBody3D at ground level; the sprite is offset up to its own
	# height, same as the old static Sprite3D's world position was.
	var body := CharacterBody3D.new()
	body.name = "Traveler"
	body.set_script(load("res://scripts/player.gd"))

	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = TRAVELER_HEIGHT
	collider.shape = capsule
	collider.position = Vector3(0.0, TRAVELER_HEIGHT * 0.5, 0.0)
	body.add_child(collider)

	var sprite := AnimatedSprite3D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = _build_traveler_frames()
	sprite.animation = "idle"
	sprite.pixel_size = SPRITE_PIXEL_SIZE
	# Y-billboard keeps the sprite upright while it turns to face the camera —
	# the trick that lets a 2D sprite live in a 3D scene without shearing.
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = true
	# ALPHA_CUT_DISCARD is what makes the shadow a cut-out silhouette instead of
	# a rectangle. Without it the whole HD-2D illusion collapses.
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	sprite.position = Vector3(0.0, TRAVELER_HEIGHT * 0.5, 0.0)
	body.add_child(sprite)

	root.add_child(body)
	return body


## Camera-follow, done by parenting rather than a script: the camera is a
## child of Traveler with a fixed local offset, so it inherits the
## traveler's position every frame for free. Traveler never rotates its own
## transform (only the sprite turns, via billboard), so the camera's world
## rotation stays exactly this fixed downward tilt no matter where the
## traveler walks — and because the local offset to the traveler is
## constant, the camera-to-subject distance the DOF band below is tuned
## around never changes either.
func _add_camera(traveler: CharacterBody3D) -> void:
	var cam := Camera3D.new()
	cam.name = "DioramaCamera"
	# Narrow FOV from far away is the Octopath flattening trick: perspective is
	# preserved but compressed, so sprites and geometry share a plane.
	cam.fov = 18.0
	cam.position = Vector3(0.0, 13.5, 21.0)
	cam.rotation_degrees = Vector3(-31.0, 0.0, 0.0)
	cam.current = true
	cam.far = 200.0

	# Tilt-shift: a sharp band on the traveler (~24.5 units out), blur near and far.
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_amount = 0.2
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 27.0
	attrs.dof_blur_far_transition = 9.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 21.0
	attrs.dof_blur_near_transition = 7.0
	cam.attributes = attrs

	traveler.add_child(cam)
