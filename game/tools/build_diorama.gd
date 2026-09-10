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
## Plaza tiles are seen closer to face-on than the path, so they can stay
## small without mipping into gravel.
const PLAZA_TILE_UNITS := 1.8

## Ground positions (y is always 0, "up" is added by whatever sits on them).
## Kept as named constants because _add_lights and the town-square dressing
## both need the lantern positions to agree.
const LANTERN_A := Vector3(-3.4, 0.0, 1.6)
const LANTERN_B := Vector3(3.4, 0.0, 1.6)
const WELL_POS := Vector3(2.0, 0.0, -2.0)
const BUILDING_L_POS := Vector3(-6.5, 0.0, -4.0)
const BUILDING_R_POS := Vector3(6.5, 0.0, -4.0)
const STALL_POS := Vector3(-2.9, 0.0, 3.0)

const BUILDING_SIZE := Vector3(2.6, 3.0, 3.6)
const BUILDING_ROOF_COLOR := Color(0.55, 0.22, 0.16)
const BUILDING_DOOR_COLOR := Color(0.12, 0.09, 0.08)
const WELL_RIM_RADIUS := 0.9
const WELL_HEIGHT := 0.6
const WELL_WATER_COLOR := Color(0.16, 0.28, 0.42)
const STALL_COUNTER_SIZE := Vector3(1.8, 0.8, 0.7)
const STALL_POST_SIZE := Vector3(0.12, 1.2, 0.12)
const STALL_AWNING_COLOR := Color(0.62, 0.16, 0.14)


func _initialize() -> void:
	var root := Node3D.new()
	root.name = "Diorama"

	_add_environment(root)
	_add_lights(root)
	_add_ground(root)
	_add_town_square(root)
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

	# The practicals: two lanterns flanking the square, so the light from M1
	# doesn't read as a lopsided accident now that there's an actual room for
	# it to light.
	var lantern := OmniLight3D.new()
	lantern.name = "LanternLight"
	lantern.position = LANTERN_A + Vector3(0.0, 2.45, 0.0)
	lantern.light_color = Color(1.0, 0.70, 0.34)
	lantern.light_energy = 4.0
	lantern.omni_range = 9.0
	lantern.omni_attenuation = 1.5
	lantern.shadow_enabled = true
	root.add_child(lantern)

	var lantern_b := OmniLight3D.new()
	lantern_b.name = "LanternLightB"
	lantern_b.position = LANTERN_B + Vector3(0.0, 2.45, 0.0)
	lantern_b.light_color = Color(1.0, 0.70, 0.34)
	lantern_b.light_energy = 4.0
	lantern_b.omni_range = 9.0
	lantern_b.omni_attenuation = 1.5
	lantern_b.shadow_enabled = true
	root.add_child(lantern_b)


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


## A shop facade: a solid stone block, a contrasting roof-cap, and a
## door-shaped inset on the face pointed at the plaza. `pos` is the ground
## anchor (footprint center, y=0); `door_dir` is +1 or -1 for which way the
## door protrudes, i.e. which side faces the square. The roof is a second,
## wider box rather than real wedge geometry — the project has no modeling
## step, so a stacked box reads as a roof cap at diorama-camera distance the
## same way the lantern head is just an emissive box, not a lamp mesh.
func _add_facade(dressing: Node3D, suffix: String, pos: Vector3, door_dir: float) -> void:
	var center := pos + Vector3(0.0, BUILDING_SIZE.y * 0.5, 0.0)
	dressing.add_child(_block("Building" + suffix, center, BUILDING_SIZE))

	var roof := BoxMesh.new()
	roof.size = BUILDING_SIZE + Vector3(0.5, -2.5, 0.5)
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = BUILDING_ROOF_COLOR
	roof_mat.roughness = 0.85
	var roof_mi := MeshInstance3D.new()
	roof_mi.name = "Roof" + suffix
	roof_mi.mesh = roof
	roof_mi.material_override = roof_mat
	roof_mi.position = pos + Vector3(0.0, BUILDING_SIZE.y + 0.25, 0.0)
	dressing.add_child(roof_mi)

	var door := BoxMesh.new()
	door.size = Vector3(0.06, 1.6, 0.9)
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = BUILDING_DOOR_COLOR
	door_mat.roughness = 1.0
	var door_mi := MeshInstance3D.new()
	door_mi.name = "Door" + suffix
	door_mi.mesh = door
	door_mi.material_override = door_mat
	door_mi.position = pos + Vector3(door_dir * (BUILDING_SIZE.x * 0.5 + 0.03), 0.8, 0.0)
	dressing.add_child(door_mi)


## The plaza's centerpiece: a solid stone rim (so it blocks like anything
## else) capped with a dark water disc proud of the rim's top surface — the
## rim mesh is a solid drum, not a hollow well, so a disc sunk *into* it is
## fully swallowed and invisible (the first version of this made that
## mistake and the well read as a plain stone stool with nothing in it).
## Raising the disc above the cap instead makes it the visible top surface,
## reading as a raised fountain lip. No water shader, just a flush color.
func _add_well(dressing: Node3D, pos: Vector3) -> void:
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = WELL_RIM_RADIUS
	rim_mesh.bottom_radius = WELL_RIM_RADIUS + 0.08
	rim_mesh.height = WELL_HEIGHT
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.55, 0.53, 0.50)
	rim_mat.roughness = 0.9
	var rim_mi := MeshInstance3D.new()
	rim_mi.name = "Mesh"
	rim_mi.mesh = rim_mesh
	rim_mi.material_override = rim_mat

	var shape := CylinderShape3D.new()
	shape.radius = WELL_RIM_RADIUS
	shape.height = WELL_HEIGHT
	var collider := CollisionShape3D.new()
	collider.shape = shape

	var body := StaticBody3D.new()
	body.name = "Well"
	body.position = pos + Vector3(0.0, WELL_HEIGHT * 0.5, 0.0)
	body.add_child(rim_mi)
	body.add_child(collider)
	dressing.add_child(body)

	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = WELL_RIM_RADIUS * 0.75
	water_mesh.bottom_radius = WELL_RIM_RADIUS * 0.75
	water_mesh.height = 0.12
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = WELL_WATER_COLOR
	water_mat.roughness = 0.15
	water_mat.metallic = 0.4
	var water_mi := MeshInstance3D.new()
	water_mi.name = "WellWater"
	water_mi.mesh = water_mesh
	water_mi.material_override = water_mat
	water_mi.position = pos + Vector3(0.0, WELL_HEIGHT + 0.02, 0.0)
	dressing.add_child(water_mi)


## A market stall built around the crates the traversal-collision tick
## already placed: a counter, two posts, and a cloth awning, so that old set
## dressing gets a job instead of just sitting there. `pos` is the ground
## anchor; CrateA/B stay exactly where they were (traversal_demo's collision
## beat is tuned around CrateA's position) and this is placed clear of them.
func _add_market_stall(dressing: Node3D, pos: Vector3) -> void:
	dressing.add_child(_block(
		"StallCounter", pos + Vector3(0.0, STALL_COUNTER_SIZE.y * 0.5, 0.0), STALL_COUNTER_SIZE))

	var post_x := STALL_COUNTER_SIZE.x * 0.5 - 0.1
	dressing.add_child(_block(
		"StallPostL", pos + Vector3(-post_x, STALL_POST_SIZE.y * 0.5, 0.0), STALL_POST_SIZE))
	dressing.add_child(_block(
		"StallPostR", pos + Vector3(post_x, STALL_POST_SIZE.y * 0.5, 0.0), STALL_POST_SIZE))

	var awning := BoxMesh.new()
	awning.size = Vector3(STALL_COUNTER_SIZE.x + 0.4, 0.1, 1.1)
	var awning_mat := StandardMaterial3D.new()
	awning_mat.albedo_color = STALL_AWNING_COLOR
	awning_mat.roughness = 0.8
	var awning_mi := MeshInstance3D.new()
	awning_mi.name = "StallAwning"
	awning_mi.mesh = awning
	awning_mi.material_override = awning_mat
	awning_mi.position = pos + Vector3(0.0, STALL_POST_SIZE.y, 0.0)
	dressing.add_child(awning_mi)


## A lantern post plus its emissive head. `pos` is the ground anchor; the
## matching OmniLight3D lives in `_add_lights` (a light needs to be a scene
## light, not scene dressing) and is kept in sync via the LANTERN_A/B consts.
func _add_lantern(dressing: Node3D, suffix: String, pos: Vector3) -> void:
	dressing.add_child(_block("LanternPost" + suffix, pos + Vector3(0.0, 1.15, 0.0), Vector3(0.2, 2.3, 0.2)))

	var head := BoxMesh.new()
	head.size = Vector3(0.42, 0.5, 0.42)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(1.0, 0.74, 0.38)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.60, 0.22)
	glass.emission_energy_multiplier = 1.8
	var head_mi := MeshInstance3D.new()
	head_mi.name = "LanternHead" + suffix
	head_mi.mesh = head
	head_mi.position = pos + Vector3(0.0, 2.45, 0.0)
	head_mi.material_override = glass
	dressing.add_child(head_mi)


## The town square: a plaza floor wide enough to read as a room rather than a
## road, framed by two shop facades and the existing back wall, organized
## around a well, with a market stall worked in from the crates the
## set-dressing tick already placed. Reasoning for this layout, and the
## alternatives it rejected, is in design/town_square.md.
func _add_town_square(root: Node3D) -> void:
	# The plaza slab sits on top of the long StonePath, right where the path
	# already meets the back wall, so the road visibly widens into a square.
	var plaza_size := Vector2(13.0, 15.0)
	var plaza_center := Vector3(0.0, 0.014, -3.0)
	var plaza_mesh := PlaneMesh.new()
	plaza_mesh.size = plaza_size
	var plaza := MeshInstance3D.new()
	plaza.name = "PlazaFloor"
	plaza.mesh = plaza_mesh
	plaza.position = plaza_center
	plaza.material_override = _pixel_material(
		"res://assets/textures/stone.png", plaza_size / PLAZA_TILE_UNITS)
	root.add_child(plaza)

	var dressing := Node3D.new()
	dressing.name = "SetDressing"

	# Far: a low wall and pillars behind the subject, marking the square's
	# back edge.
	dressing.add_child(_block("WallBack", Vector3(0, 1.2, -13.0), Vector3(30, 2.4, 1.0)))
	dressing.add_child(_block("PillarBackL", Vector3(-7.0, 2.1, -10.5), Vector3(1.4, 4.2, 1.4)))
	dressing.add_child(_block("PillarBackR", Vector3(7.0, 2.1, -10.5), Vector3(1.4, 4.2, 1.4)))
	dressing.add_child(_block("StepsBack", Vector3(0, 0.22, -8.6), Vector3(10.0, 0.44, 1.8)))

	# Two shop facades flanking the plaza, mirrored.
	_add_facade(dressing, "L", BUILDING_L_POS, 1.0)
	_add_facade(dressing, "R", BUILDING_R_POS, -1.0)

	# The centerpiece.
	_add_well(dressing, WELL_POS)

	# Mid: crates and a bench, plus the stall they're now dressing.
	dressing.add_child(_block("CrateA", Vector3(-2.9, 0.5, 1.6), Vector3(1.0, 1.0, 1.0)))
	dressing.add_child(_block("CrateB", Vector3(-2.85, 1.35, 1.65), Vector3(0.7, 0.7, 0.7)))
	dressing.add_child(_block("CrateC", Vector3(3.4, 0.55, -1.2), Vector3(1.1, 1.1, 1.1)))
	dressing.add_child(_block("BenchR", Vector3(4.6, 0.3, 3.2), Vector3(2.4, 0.6, 0.9)))
	_add_market_stall(dressing, STALL_POS)

	# Two lanterns flanking the square, under the two practicals in _add_lights.
	_add_lantern(dressing, "", LANTERN_A)
	_add_lantern(dressing, "B", LANTERN_B)

	# Near: foreground blockers that sit in front of the focal plane and blur
	# out — now doubling as the square's south entrance gate.
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
