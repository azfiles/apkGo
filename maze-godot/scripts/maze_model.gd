extends RefCounted
## Pure grid rules shared by click navigation, hints, collision checks and saves.

const DIRECTIONS = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
var level: Dictionary
var width: int
var height: int
var start: Vector2i
var goal: Vector2i
var cell: Vector2i
var stamps: Array[Vector2i] = []
var collected: Array[Vector2i] = []
var steps := 0
var hints := 0
var completed := false

static func catalog() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels.json"))

func setup(data: Dictionary) -> void:
	level = data
	height = data.rows.size()
	width = data.rows[0].length()
	stamps.clear()
	collected.clear()
	steps = 0
	hints = 0
	completed = false
	for y in range(height):
		for x in range(width):
			match data.rows[y][x]:
				"S": start = Vector2i(x, y)
				"G": goal = Vector2i(x, y)
				"*": stamps.append(Vector2i(x, y))
	cell = start

func walkable(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height and level.rows[p.y][p.x] != "#"

func path_to(target: Vector2i, origin: Vector2i = Vector2i(-1, -1)) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if origin == Vector2i(-1, -1): origin = cell
	if not walkable(target) or not walkable(origin):
		return result
	var queue: Array[Vector2i] = [origin]
	var parent := {origin: origin}
	var index := 0
	while index < queue.size():
		var p := queue[index]
		index += 1
		if p == target:
			break
		for d in DIRECTIONS:
			var n: Vector2i = p + d
			if walkable(n) and not parent.has(n):
				parent[n] = p
				queue.append(n)
	if not parent.has(target):
		return result
	var cursor := target
	while cursor != origin:
		result.push_front(cursor)
		cursor = parent[cursor]
	return result

func enter(p: Vector2i) -> bool:
	if completed or not walkable(p) or p == cell or (p - cell).length_squared() != 1:
		return false
	cell = p
	steps += 1
	if stamps.has(cell) and not collected.has(cell):
		collected.append(cell)
	completed = cell == goal
	return true

func hint_path() -> Array[Vector2i]:
	hints += 1
	return path_to(goal).slice(0, 5)

func snapshot() -> Dictionary:
	return {"level": int(level.id), "cell": [cell.x, cell.y], "collected": collected.map(func(p): return [p.x, p.y]), "steps": steps, "hints": hints}

func restore(data: Dictionary) -> bool:
	# Reject malformed or unreachable state; never restore a position inside a wall.
	if not _valid_pair(data.get("cell")):
		return false
	var p := Vector2i(data.cell[0], data.cell[1])
	if not walkable(p) or p == goal:
		return false
	if not data.get("collected", []) is Array:
		return false
	var found: Array[Vector2i] = []
	for item in data.get("collected", []):
		if not _valid_pair(item):
			return false
		var stamp := Vector2i(item[0], item[1])
		if not stamps.has(stamp) or found.has(stamp):
			return false
		found.append(stamp)
	if not _valid_count(data.get("steps", 0)) or not _valid_count(data.get("hints", 0)):
		return false
	cell = p
	collected = found
	steps = int(data.get("steps", 0))
	hints = int(data.get("hints", 0))
	return true

func _valid_pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _valid_count(value[0]) and _valid_count(value[1])

func _valid_count(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= 0 and float(value) < 1000000
