extends Node3D
## Orthographic 3D garden with original character art displayed as paper sprites.

signal changed
signal finished
const TILE := 1.35
const SPEED := 3.1
var model
var geometry: Node3D
var camera: Camera3D
var player: CharacterBody3D
var paper: Sprite3D
var goal_paper: Sprite3D
var ground_ring: MeshInstance3D
var hover_ring: MeshInstance3D
var route_root: Node3D
var stamps: Dictionary = {}
var route: Array[Vector2i] = []
var manual := Vector2.ZERO
var active := false
var clock := 0.0
var hint_remaining := 0.0
var step_clock := 0.0
var materials: Dictionary = {}

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("f3f0e7")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f5efdc")
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -28, 0)
	sun.light_color = Color("fff0d2")
	sun.light_energy = 0.60
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55
	sun.shadow_blur = 2.2
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 100
	camera.v_offset = 0.5
	camera.position = Vector3(14, 20, 18)
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true

func build(next_model) -> void:
	model = next_model
	active = false
	route.clear()
	manual = Vector2.ZERO
	materials.clear()
	stamps.clear()
	if geometry:
		remove_child(geometry)
		geometry.queue_free()
	geometry = Node3D.new()
	add_child(geometry)
	var w: float = model.width * TILE
	var h: float = model.height * TILE
	camera.size = maxf(w, h) * 1.14 + 0.4
	_box(Vector3(w + 0.5, 0.38, h + 0.5), Vector3(0, -0.65, 0), Color("9c8468"))
	_box(Vector3(w + 0.65, 0.19, h + 0.65), Vector3(0, -0.42, 0), Color("c2b38b"))
	_box(Vector3(w + 0.30, 0.36, h + 0.30), Vector3(0, -0.17, 0), Color(model.level.grass), true)
	var random := RandomNumberGenerator.new()
	random.seed = 480 + int(model.level.id)
	for y in range(model.height):
		for x in range(model.width):
			var cell := Vector2i(x, y)
			var p := cell_to_world(cell)
			if model.walkable(cell):
				var shade := Color("e5d9b9").lerp(Color("eee4c9"), float(random.randi_range(0, 3)) * 0.15)
				_box(Vector3(TILE - 0.06, 0.055, TILE - 0.06), p - Vector3(0, 0.035, 0), shade)
				if random.randf() < 0.3:
					for i in range(3):
						_ball(Vector3(0.025, 0.009, 0.025), p + Vector3(random.randf_range(-0.5, 0.5), 0.003, random.randf_range(-0.5, 0.5)), Color("b8ad90"))
			else:
				var color := Color(model.level.hedge).lightened(float(random.randi_range(0, 3)) * 0.04)
				_box(Vector3(TILE - 0.12, 0.57, TILE - 0.12), p + Vector3(0, 0.24, 0), color)
				# Rounded crown reads as a low hedge, leaving characters visible above it.
				_ball(Vector3(0.65, 0.22, 0.63), p + Vector3(0, 0.55, 0), color.lightened(0.07))
				_collider(Vector3(TILE - 0.07, 0.90, TILE - 0.07), p + Vector3(0, 0.39, 0))
				if random.randf() < 0.16:
					_flower(p + Vector3(0.24, 0.68, 0.13), Color("f1dca1"))
	# Decorative trees sit on blocked boundary cells, sharing the maze footprint.
	for cell in [Vector2i(0, 0), Vector2i(model.width - 1, 0), Vector2i(0, model.height - 1), Vector2i(model.width - 1, model.height - 1)]:
		_tree(cell_to_world(cell), Color(model.level.hedge))
	if int(model.level.id) == 1:
		_pond(cell_to_world(Vector2i(4, 4)))
	_bench(cell_to_world(Vector2i(0, model.height / 2)))
	for i in range(24):
		var cell := Vector2i(random.randi_range(0, model.width - 1), random.randi_range(0, model.height - 1))
		if not model.walkable(cell):
			_flower(cell_to_world(cell) + Vector3(random.randf_range(-0.4, 0.4), 0.68, random.randf_range(-0.4, 0.4)), Color("e4c0ac") if i % 2 else Color("f4e6c3"))
	for cell in model.stamps:
		var stamp := Node3D.new()
		stamp.position = cell_to_world(cell)
		geometry.add_child(stamp)
		_ring(stamp, 0.28, Color("d5b365"), Vector3(0, 0.04, 0))
		var leaf := _ball(Vector3(0.12, 0.22, 0.065), Vector3(0, 0.5, 0), Color("e2b65d"), stamp)
		leaf.rotation_degrees.z = -28
		stamp.visible = not model.collected.has(cell)
		stamps[cell] = stamp
	var spawn := cell_to_world(model.start)
	_ring(geometry, 0.43, Color("a88a54"), spawn + Vector3(0, 0.025, 0))
	for i in range(3):
		_box(Vector3(0.12, 0.035, 0.10), spawn + Vector3(0.0, 0.03, -0.2 + i * 0.18), Color("b7a578"))
	var goal := cell_to_world(model.goal)
	_ring(geometry, 0.53, Color("e6c376"), goal + Vector3(0, 0.035, 0))
	goal_paper = _character("koala", Rect2(72, 48, 319, 361), 0.0035, goal + Vector3(0, 0.72, 0))
	# The detective is a guide at the entrance; the playable character is Brown.
	_character("detective", Rect2(25, 33, 299, 392), 0.0037, cell_to_world(Vector2i(0, model.height - 2)) + Vector3(-0.04, 0.83, 0))
	player = CharacterBody3D.new()
	player.name = "Brown"
	player.position = cell_to_world(model.cell)
	geometry.add_child(player)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.19
	capsule.height = 0.78
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.41
	player.add_child(collision)
	paper = _character("brown", Rect2(95, 168, 159, 257), 0.0045, Vector3(0, 0.64, 0), player)
	ground_ring = _ring(player, 0.30, Color("f9f0c5"), Vector3(0, 0.018, 0))
	hover_ring = _ring(geometry, 0.40, Color("faf3d4"), Vector3.ZERO)
	hover_ring.visible = false
	route_root = Node3D.new()
	geometry.add_child(route_root)
	clock = 0
	hint_remaining = 0
	_batch_static()

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player): return
	clock += delta
	goal_paper.position.y = 0.72 + sin(clock * 1.8) * 0.025
	for cell in stamps:
		var stamp: Node3D = stamps[cell]
		if stamp.get_child_count() > 1:
			stamp.get_child(1).position.y = 0.5 + sin(clock * 2.2 + cell.x) * 0.07
			stamp.get_child(1).rotation.y = clock * 0.6
	if hint_remaining > 0:
		hint_remaining -= delta
		if hint_remaining <= 0: clear_marks()
	if not active:
		player.velocity = Vector3.ZERO
		return
	var movement := Vector3.ZERO
	if manual.length() > 0.1:
		route.clear()
		var right := camera.global_basis.x
		var forward := -camera.global_basis.z
		right.y = 0
		forward.y = 0
		movement = (right.normalized() * manual.x - forward.normalized() * manual.y).normalized() * SPEED
	elif not route.is_empty():
		var target := cell_to_world(route[0])
		var offset := target - player.position
		offset.y = 0
		if offset.length() < 0.06:
			player.position.x = target.x
			player.position.z = target.z
			route.pop_front()
		else:
			movement = offset.normalized() * minf(SPEED, offset.length() / maxf(delta, 0.001))
	player.velocity = Vector3(movement.x, -2.5, movement.z)
	player.move_and_slide()
	var current := world_to_cell(player.position)
	if current != model.cell and model.walkable(current):
		# At a four-way intersection two grid boundaries can be crossed in one tick.
		if (current - model.cell).length_squared() == 2:
			var via := Vector2i(current.x, model.cell.y)
			if not model.walkable(via): via = Vector2i(model.cell.x, current.y)
			_visit(via)
		_visit(current)
	var walking := movement.length_squared() > 0.01
	paper.position.y = 0.64 + absf(sin(clock * 13)) * 0.045 if walking else 0.64
	paper.rotation.z = sin(clock * 13) * 0.035 if walking else 0.0
	if walking and absf(movement.x) > 0.1: paper.flip_h = movement.x < 0

func _visit(cell: Vector2i) -> void:
	var before: int = model.collected.size()
	if not model.enter(cell): return
	if model.collected.size() > before:
		stamps[cell].visible = false
		_burst(cell_to_world(cell))
	changed.emit()
	if model.completed:
		active = false
		route.clear()
		finished.emit()

func navigate(cell: Vector2i) -> bool:
	if not active or not model.walkable(cell): return false
	var found: Array[Vector2i] = model.path_to(cell)
	if found.is_empty() and cell != model.cell: return false
	route = [model.cell]
	route.append_array(found)
	show_marks(found, false)
	return true

func show_marks(cells: Array[Vector2i], hint: bool = true) -> void:
	clear_marks()
	for cell in cells:
		_ball(Vector3(0.075, 0.025, 0.075), cell_to_world(cell) + Vector3(0, 0.02, 0), Color("faf1b6") if hint else Color("c5ab71"), route_root)
	hint_remaining = 7.0 if hint else 3.0

func clear_marks() -> void:
	if route_root:
		for child in route_root.get_children():
			route_root.remove_child(child)
			child.queue_free()

func screen_cell(screen: Vector2) -> Vector2i:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var distance := (0.04 - origin.y) / direction.y
	return world_to_cell(origin + direction * distance)

func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3((cell.x - (model.width - 1) * 0.5) * TILE, 0.05, (cell.y - (model.height - 1) * 0.5) * TILE)

func world_to_cell(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x / TILE + (model.width - 1) * 0.5), roundi(p.z / TILE + (model.height - 1) * 0.5))

func hover(cell: Vector2i) -> void:
	if not hover_ring: return
	hover_ring.visible = active and model.walkable(cell)
	if hover_ring.visible: hover_ring.position = cell_to_world(cell) + Vector3(0, 0.04, 0)

func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if materials.has(key): return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	materials[key] = material
	return material

func _mesh(mesh: Mesh, position_: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position_
	node.material_override = _material(color)
	(parent if parent else geometry).add_child(node)
	return node

func _box(size_: Vector3, position_: Vector3, color: Color, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var node := _mesh(mesh, position_, color, parent)
	node.scale = size_
	if solid: _collider(size_, position_)
	return node

func _batch_static() -> void:
	# Compatibility renderer has no automatic instancing. Batch the static garden
	# by primitive and palette color to keep mobile draw calls modest.
	var batches: Dictionary = {}
	for child in geometry.get_children():
		if not child is MeshInstance3D or child == hover_ring: continue
		if not (child.mesh is BoxMesh or child.mesh is SphereMesh): continue
		var key: String = child.mesh.get_class() + child.material_override.albedo_color.to_html()
		if not batches.has(key): batches[key] = []
		batches[key].append(child)
	for key in batches:
		var nodes: Array = batches[key]
		if nodes.size() < 2: continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = nodes[0].mesh
		multimesh.instance_count = nodes.size()
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multimesh
		batch.material_override = nodes[0].material_override
		geometry.add_child(batch)
		for i in range(nodes.size()):
			multimesh.set_instance_transform(i, nodes[i].transform)
			geometry.remove_child(nodes[i])
			nodes[i].queue_free()

func _ball(scale_: Vector3, position_: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 5
	var node := _mesh(mesh, position_, color, parent)
	node.scale = scale_
	return node

func _ring(parent: Node3D, radius: float, color: Color, position_: Vector3) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.024
	mesh.outer_radius = radius + 0.024
	mesh.rings = 24
	mesh.ring_segments = 6
	return _mesh(mesh, position_, color, parent)

func _collider(size_: Vector3, position_: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = position_
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size_
	shape.shape = box
	body.add_child(shape)
	geometry.add_child(body)

func _character(key: String, rect: Rect2, pixel: float, position_: Vector3, parent: Node3D = null) -> Sprite3D:
	var node := Sprite3D.new()
	node.texture = load("res://assets/characters/%s.png" % key)
	node.region_enabled = true
	node.region_rect = rect
	node.pixel_size = pixel
	node.position = position_
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.shaded = false
	node.no_depth_test = true
	node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	node.alpha_scissor_threshold = 0.15
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else geometry).add_child(node)
	return node

func _tree(p: Vector3, color: Color) -> void:
	_box(Vector3(0.20, 1.6, 0.20), p + Vector3(0, 0.8, 0), Color("95795c"))
	_ball(Vector3(0.87, 0.95, 0.80), p + Vector3(0, 1.8, 0), color.lightened(0.16))
	_ball(Vector3(0.58, 0.65, 0.60), p + Vector3(-0.4, 1.54, 0.25), color.lightened(0.1))
	_ball(Vector3(0.43, 0.53, 0.42), p + Vector3(0.55, 1.7, 0.1), color)

func _flower(p: Vector3, color: Color) -> void:
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		_ball(Vector3(0.055, 0.024, 0.055), p + Vector3(cos(angle) * 0.065, 0, sin(angle) * 0.065), color)
	_ball(Vector3(0.035, 0.026, 0.035), p + Vector3(0, 0.01, 0), Color("e8be64"))

func _bench(p: Vector3) -> void:
	for i in range(3):
		_box(Vector3(0.68, 0.07, 0.11), p + Vector3(0, 0.65, float(i) * 0.14 - 0.14), Color("c5a778"))
	_box(Vector3(0.68, 0.28, 0.08), p + Vector3(0, 0.87, -0.23), Color("c5a778"))
	for x in [-0.26, 0.26]:
		_box(Vector3(0.06, 0.50, 0.34), p + Vector3(x, 0.4, 0), Color("596d59"))

func _pond(p: Vector3) -> void:
	# An ornamental pool sits atop a blocked hedge island, never on a route.
	_ball(Vector3(0.56, 0.10, 0.50), p + Vector3(0, 0.68, 0), Color("c3c3a0"))
	_ball(Vector3(0.48, 0.055, 0.42), p + Vector3(0, 0.75, 0), Color("83b2b8"))
	_ring(geometry, 0.21, Color("c4e1db"), p + Vector3(0.006, 0.81, 0))

func _burst(p: Vector3) -> void:
	for i in range(9):
		var bit := _ball(Vector3.ONE * 0.045, p + Vector3(0, 0.5, 0), Color("ecd086"))
		var angle := TAU * float(i) / 9.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(bit, "position", p + Vector3(cos(angle) * 0.65, 0.2, sin(angle) * 0.65), 0.55).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(bit, "scale", Vector3.ZERO, 0.55)
		tween.chain().tween_callback(bit.queue_free)
