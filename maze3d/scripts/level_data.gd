extends RefCounted
## JSON is the authoring boundary: geometry, topology and gameplay stay separate.
const INDEX := "res://levels/index.json"
const Assets = preload("res://scripts/asset_library.gd")
static var entries: Array = []

static func chapters() -> Array:
	if entries.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
		if parsed is Dictionary and parsed.get("version") == 1:
			entries = parsed.get("chapters", [])
	return entries

static func count() -> int:
	return chapters().size()

static func load_chapter(index: int) -> Dictionary:
	if Assets.catalog().is_empty(): return {}
	if chapters().is_empty():
		push_error("Level index is empty or unsupported: " + INDEX)
		return {}
	var path: String = chapters()[clampi(index, 0, count()-1)].path
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("Invalid level JSON %s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var errors := validate(json.data)
	if not errors.is_empty():
		push_error("Invalid level %s: %s" % [path, "; ".join(errors)])
		return {}
	return json.data

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _vector(value: Variant, length: int, integers: bool = false) -> bool:
	if not value is Array or value.size() != length: return false
	for component in value:
		if not _number(component) or (integers and float(component) != floorf(float(component))): return false
	return true

static func _open(grid: Array, cell: Variant) -> bool:
	if not _vector(cell, 2, true): return false
	var x := int(cell[0]); var z := int(cell[1])
	return z >= 0 and z < grid.size() and x >= 0 and x < grid.size() and grid[z][x] in [".", "="]

static func validate(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not data is Dictionary: return PackedStringArray(["root must be an object"])
	if data.get("version") != 1: errors.append("unsupported version")
	for key in ["id", "title", "subtitle", "difficulty"]:
		if not data.get(key) is String or data.get(key, "").is_empty(): errors.append("missing text: " + key)
	if data.get("tile_size") != 4.0: errors.append("tile_size must be 4 meters")
	if not _number(data.get("seed")) or float(data.seed) != floorf(float(data.seed)): errors.append("seed must be an integer")
	var grid = data.get("grid")
	if not grid is Array or grid.size() < 5 or grid.size() > 41: return PackedStringArray(["grid must be a square of 5..41 cells"])
	for row in grid:
		if not row is String or row.length() != grid.size(): return PackedStringArray(["grid rows must have equal square dimensions"])
		for symbol in row:
			if symbol not in ["#", ".", "~", "="]: errors.append("unknown grid symbol: " + symbol)
	for z in grid.size():
		for x in grid.size():
			if (x == 0 or z == 0 or x == grid.size()-1 or z == grid.size()-1) and grid[z][x] != "#": errors.append("outer boundary must be closed")
	var used: Array = []
	for key in ["start", "goal"]:
		var cell = data.get(key)
		if not _open(grid, cell): errors.append(key + " must be on a passage")
		elif cell in used: errors.append("duplicate objective: " + key)
		else: used.append(cell)
	for key in ["beacons", "motes"]:
		var cells = data.get(key)
		if not cells is Array: return PackedStringArray([key + " must be an array"])
		if (key == "beacons" and cells.size() != 3) or (key == "motes" and (cells.is_empty() or cells.size() > 100)): errors.append("invalid count: " + key)
		for cell in cells:
			if not _open(grid, cell): errors.append(key + " must be on a passage")
			elif cell in used: errors.append("duplicate objective: " + key)
			else: used.append(cell)
	var challenges = data.get("challenges", [])
	if not challenges is Array: return PackedStringArray(["challenges must be an array"])
	var hazard_cells: Array = []
	for challenge in challenges:
		if not challenge is Dictionary: errors.append("challenge must be an object"); continue
		var cell = challenge.get("cell"); var axis = challenge.get("axis")
		if not _open(grid, cell) or cell in used or cell in hazard_cells: errors.append("challenge overlaps an objective or invalid cell"); continue
		if not _vector(axis, 2, true) or absf(axis[0]) + absf(axis[1]) != 1: errors.append("challenge axis must be cardinal"); continue
		if challenge.get("kind") not in ["gap", "hurdle"]: errors.append("unknown challenge kind")
		if not _number(challenge.get("height")) or challenge.height <= 0 or challenge.height > .75: errors.append("hurdle exceeds jump height")
		if not _number(challenge.get("span")) or challenge.span <= 0 or challenge.span > 1.4: errors.append("gap exceeds jump distance")
		if not _open(grid, [cell[0]+axis[0], cell[1]+axis[1]]) or not _open(grid, [cell[0]-axis[0], cell[1]-axis[1]]): errors.append("challenge needs two landings")
		hazard_cells.append(cell)
	for challenge in challenges:
		if not challenge is Dictionary or not _vector(challenge.get("cell"), 2, true) or not _vector(challenge.get("axis"), 2, true): continue
		var c: Array = challenge.cell; var a: Array = challenge.axis
		if [c[0]+a[0], c[1]+a[1]] in hazard_cells or [c[0]-a[0], c[1]-a[1]] in hazard_cells: errors.append("challenge landing is hazardous")
	var elevated = data.get("elevated_motes", [])
	if not elevated is Array: errors.append("elevated_motes must be an array")
	else:
		var unique: Array = []
		for index in elevated:
			if not _number(index) or float(index) != floorf(float(index)) or index < 0 or index >= data.get("motes", []).size() or index in unique: errors.append("invalid elevated mote index")
			unique.append(index)
	var scenery = data.get("scenery", [])
	if not scenery is Array: return PackedStringArray(["scenery must be an array"])
	for item in scenery:
		if not item is Dictionary: errors.append("scenery must be an object"); continue
		if not item.get("asset") is String or not Assets.has_asset(item.get("asset", "")): errors.append("unknown scenery asset")
		if not _vector(item.get("position"), 3): errors.append("invalid scenery position")
		if not _number(item.get("rotation_y", 0)): errors.append("invalid scenery rotation")
		if not _number(item.get("scale", 1)) or item.get("scale", 1) <= 0 or item.get("scale", 1) > 4: errors.append("invalid scenery scale")
		if not item.get("collisions", true) is bool: errors.append("collisions must be boolean")
	var style = data.get("environment", {})
	var surfaces = data.get("surface_assets", {})
	if not surfaces is Dictionary: errors.append("surface_assets must be an object")
	else:
		for key in surfaces:
			if key not in ["floor", "bridge", "wall"]: errors.append("unknown surface role")
			elif not surfaces[key] is String or not Assets.has_asset(surfaces[key]): errors.append("unknown surface asset")
			elif Assets.catalog()[surfaces[key]].get("colliders", []).is_empty(): errors.append("surface asset requires collision")
	if not style is Dictionary: errors.append("environment must be an object")
	else:
		for key in ["background", "fog", "water"]:
			if style.has(key) and (not style[key] is String or not Color.html_is_valid(style[key])): errors.append("invalid environment color: " + key)
	if not _number(data.get("bridge_rotation_y", 0)): errors.append("invalid bridge rotation")
	var regions = data.get("regions", [])
	if not regions is Array: errors.append("regions must be an array")
	else:
		for region in regions:
			if not region is Dictionary: errors.append("region must be an object"); continue
			if not region.get("name") is String or not _vector(region.get("bounds"), 4, true): errors.append("invalid region name or bounds"); continue
			var bounds: Array = region.bounds
			if bounds[0] < 0 or bounds[1] < 0 or bounds[2] < bounds[0] or bounds[3] < bounds[1] or bounds[2] >= grid.size() or bounds[3] >= grid.size(): errors.append("region bounds outside grid")
			if region.has("floor") and (not region.floor is String or not Color.html_is_valid(region.floor)): errors.append("invalid region floor color")
	# Reject disconnected authored worlds before replacing the running scene.
	if not errors.is_empty(): return errors
	var start := Vector2i(data.start[0], data.start[1])
	var visited := {start: true}; var queue: Array[Vector2i] = [start]; var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]; cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if _open(grid, [next.x, next.y]) and not visited.has(next): visited[next] = true; queue.append(next)
	for z in grid.size():
		for x in grid.size():
			if _open(grid, [x, z]) and not visited.has(Vector2i(x,z)): errors.append("disconnected passage at %d,%d" % [x,z])
	return errors
