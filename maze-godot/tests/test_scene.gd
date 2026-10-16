extends SceneTree

const Main = preload("res://scripts/main.gd")
var app
var checks := 0
var failures := 0

func check(ok: bool, label_: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label_)

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i in range(count): await physics_frame

func click(point: Vector2) -> void:
	for pressed_ in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed_
		root.push_input(event, true)
		await ticks(2)

func key(code: int, pressed_: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed_
	Input.parse_input_event(event)
	await ticks(2)

func walk(target: Vector2i) -> void:
	check(app.world.navigate(target), "path request accepted")
	for i in range(2600):
		await physics_frame
		if (app.model.cell == target and app.world.route.is_empty()) or app.model.completed: break
	check(app.model.cell == target, "CharacterBody3D physically arrives at target")
	check(app.world.player.position.y > -0.1, "player remains on floor")

func run() -> void:
	root.size = Vector2i(1280, 800)
	app = Main.new()
	app.testing = true
	app.store.path = "user://test-scene-%s.json" % OS.get_process_id()
	root.add_child(app)
	app.sound.enabled = false # This suite runs faster than real time with a dummy audio driver.
	await ticks(4)
	check(app.state == "home" and not app.world.active, "home diorama does not move")
	check(app.world.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "true orthographic 3D scene")
	check(app.world.player is CharacterBody3D, "physical player body")
	await click(Vector2(182, 650))
	check(app.state == "playing", "real start button input")
	var destination: Vector2i = app.model.cell + Vector2i.RIGHT
	var point: Vector2 = app.map_container.position + app.world.camera.unproject_position(app.world.cell_to_world(destination))
	await click(point)
	check(not app.world.route.is_empty(), "projected floor click creates route")
	for i in range(180): await physics_frame
	check(app.model.cell == destination, "click navigation moves through real physics")
	var position_: Vector3 = app.world.player.position
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	check(app.state == "paused" and app.modal.visible, "Escape pauses and shows modal")
	await ticks(30)
	check(app.world.player.position.is_equal_approx(position_), "paused body is stationary")
	await click(Vector2(640, 516))
	check(app.state == "playing", "resume button restores gameplay")
	var old_cell: Vector2i = app.model.cell
	await key(KEY_H, true)
	await key(KEY_H, false)
	check(app.model.hints == 1 and app.model.cell == old_cell and app.world.route.is_empty(), "keyboard hint reveals route without moving")
	# Press into an adjacent hedge for two simulated seconds; no clipping or escape.
	app.world.route.clear()
	await key(KEY_W, true)
	await ticks(120)
	await key(KEY_W, false)
	check(app.model.walkable(app.world.world_to_cell(app.world.player.position)), "manual movement respects hedge colliders")
	check(app.world.player.position.y > -0.1, "manual movement stays on island")
	# Fresh runs traverse each stamp and then the goal using real move_and_slide.
	for index in range(3):
		app.state = "home"
		app.load_level(index, true)
		app.start_play()
		await ticks(4)
		for target in app.model.stamps.duplicate():
			await walk(target)
		check(app.model.collected.size() == 3, "three physical pickups")
		await walk(app.model.goal)
		check(app.state == "complete" and app.modal.visible, "real physics finishes chapter and shows result")
		check(app.stamp_summary.text == "★★★", "all discoveries earn three stars")
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute("user://test-scene-%s.json" % OS.get_process_id())
	print("SCENE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
