extends SceneTree

const Model = preload("res://scripts/maze_model.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failures := 0

func check(ok: bool, label_: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label_)

func _initialize() -> void:
	var levels := Model.catalog()
	check(levels.size() == 3, "three playable chapters")
	for level in levels:
		var model := Model.new()
		model.setup(level)
		check(model.stamps.size() == 3, "three optional stamps")
		check(not model.enter(Vector2i(-1, 1)), "reject out-of-bounds movement")
		check(not model.enter(Vector2i(0, 0)), "reject walls")
		check(not model.enter(model.goal), "reject teleporting to goal")
		var original: Vector2i = model.cell
		var hint: Array[Vector2i] = model.hint_path()
		check(hint.size() > 0 and hint.size() <= 5 and model.cell == original, "hint never moves player or reveals entire maze")
		var goal_neighbors := 0
		for d in Model.DIRECTIONS:
			if model.walkable(model.goal + d): goal_neighbors += 1
		check(goal_neighbors == 1, "goal is a dead-end so optional stamps remain collectable")
		var reachable := 0
		for y in range(model.height):
			check(level.rows[y].length() == model.width, "rectangular map")
			for x in range(model.width):
				var p := Vector2i(x, y)
				if model.walkable(p) and p != model.start:
					check(not model.path_to(p).is_empty(), "every path tile reachable")
					reachable += 1
		check(reachable > 20, "chapter has a real route")
		for stamp in model.stamps:
			var route: Array[Vector2i] = model.path_to(stamp)
			check(not route.has(model.goal), "collectible path does not cross goal")
			for cell in route: check(model.enter(cell), "follow legal route to stamp")
			check(not model.completed, "optional collection never completes chapter early")
		check(model.collected.size() == 3, "all three stamps collected")
		var snapshot: Dictionary = model.snapshot()
		var restored := Model.new()
		restored.setup(level)
		check(restored.restore(snapshot), "valid save restores")
		check(restored.cell == model.cell and restored.collected == model.collected and restored.steps == model.steps, "position and discoveries preserved")
		for invalid in [{"cell": [0, 0]}, {"cell": [-1, 2]}, {"cell": ["x", 3]}, {"cell": [1.5, 2]}, {"cell": [1, 1], "collected": [[0, 0]]}]:
			check(not restored.restore(invalid), "malformed save rejected")
		for cell in model.path_to(model.goal): check(model.enter(cell), "legal goal route")
		check(model.completed, "chapter completes on reaching koala")
		check(not model.enter(model.start), "completed chapter blocks further input")
		var direct := Model.new()
		direct.setup(level)
		for cell in direct.path_to(direct.goal): direct.enter(cell)
		check(direct.completed, "stamps are optional for completion")
		check(direct.collected.size() < 3, "full discovery rewards exploring off the direct goal route")
	var store := Store.new()
	store.path = "user://test-store-%s.json" % OS.get_process_id()
	store.sound = false
	store.active = {"0": {"cell": [1, 7]}, "2": {"cell": [1, 9]}}
	store.save_data()
	store.finish(0, 3)
	store.finish(0, 1)
	var loaded := Store.new()
	loaded.path = store.path
	loaded.load_data()
	check(not loaded.sound and loaded.records.get("0") == 3, "sound and best score persist without downgrade")
	check(not loaded.active.has("0") and loaded.active.has("2"), "finishing one chapter preserves other chapter saves")
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("{corrupt")
	file.close()
	var corrupt := Store.new()
	corrupt.path = store.path
	corrupt.load_data()
	check(corrupt.records.is_empty(), "corrupt save falls back safely")
	DirAccess.remove_absolute(store.path)
	print("MODEL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
