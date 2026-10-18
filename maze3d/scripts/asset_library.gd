extends RefCounted
## Stable asset IDs keep Blender filenames and level placement independent.
const MANIFEST := "res://assets/model_catalog.json"
static var definitions: Dictionary = {}
static var scenes: Dictionary = {}

static func catalog() -> Dictionary:
	if definitions.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		var errors := validate(parsed)
		if not errors.is_empty():
			push_error("Invalid model catalog: " + "; ".join(errors))
			return {}
		definitions = parsed.assets
	return definitions

static func validate(data: Variant) -> PackedStringArray:
	if not data is Dictionary or data.get("version") != 1: return PackedStringArray(["unsupported catalog version"])
	if not data.get("assets") is Dictionary or data.assets.is_empty(): return PackedStringArray(["assets must be a nonempty object"])
	var errors := PackedStringArray()
	for id in data.assets:
		var entry = data.assets[id]
		if not id is String or not entry is Dictionary: errors.append("invalid asset entry"); continue
		var path = entry.get("path", "")
		if not path is String or not path.begins_with("res://assets/models/") or not path.ends_with(".glb") or not ResourceLoader.exists(path): errors.append("missing GLB: " + id)
		if not entry.get("source") is String or not entry.get("source", "").ends_with(".blend"): errors.append("missing Blender source: " + id)
		if not entry.get("source_root") is String or entry.get("source_root", "").is_empty(): errors.append("missing Blender root: " + id)
		if not entry.get("colliders", []) is Array: errors.append("colliders must be an array: " + id); continue
		for box in entry.get("colliders", []):
			if not box is Dictionary: errors.append("invalid collider: " + id); continue
			for key in ["size", "position"]:
				var components = box.get(key)
				if not components is Array or components.size() != 3: errors.append("invalid collider " + key + ": " + id); continue
				for component in components:
					if not (component is float or component is int) or not is_finite(float(component)) or (key == "size" and component <= 0): errors.append("invalid collider component: " + id)
	return errors

static func has_asset(id: String) -> bool:
	return catalog().has(id)

static func instantiate(id: String, parent: Node3D, position: Vector3, collisions: bool = false) -> Node3D:
	var entry: Dictionary = catalog().get(id, {})
	if entry.is_empty():
		push_error("Unknown model asset: " + id)
		return null
	if not scenes.has(id):
		scenes[id] = load(entry.path)
	if not scenes[id] is PackedScene:
		push_error("Cannot load GLB asset: " + str(entry.path))
		return null
	var node: Node3D = scenes[id].instantiate()
	node.position = position
	node.set_meta("asset_id", id)
	parent.add_child(node)
	if collisions:
		for box in entry.get("colliders", []):
			var body := StaticBody3D.new()
			var shape := BoxShape3D.new()
			shape.size = vector(box.size)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			body.position = vector(box.position)
			body.add_child(collision)
			node.add_child(body)
	return node

static func vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])
