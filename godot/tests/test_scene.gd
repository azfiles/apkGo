extends SceneTree

const Main = preload("res://scripts/main.gd")
const Round = preload("res://scripts/round.gd")
var checks := 0
var failures := 0
var app
var collided := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func touch(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(1)

func run() -> void:
	root.size = Vector2i(720, 1280)
	app = Main.new()
	app.testing = true
	app.store.path = "user://scene-test-%d.json" % OS.get_process_id()
	root.add_child(app)
	await frames(2)
	check(app.screen == "home", "home boots")
	app.start_level(8)
	check(app.screen == "home", "locked level cannot start")
	await touch(Vector2(360, 527))
	check(app.screen == "play" and app.orbs.size() == 9, "real start button")
	if app.orbs.is_empty():
		quit(1)
		return
	var wrong = app.orbs.filter(func(o): return o.number == 2)[0]
	await touch(wrong.position)
	check(app.game.mistakes == 1 and app.game.next == 1, "real wrong touch")
	check(app.effects.get_child_count() > 0, "particle emitters created")
	var first = app.orbs.filter(func(o): return o.number == 1)[0]
	await touch(first.position)
	check(app.game.next == 2 and first.done, "real correct touch")
	await touch(Vector2(220, 1090))
	check(app.screen == "pause" and not app.world.visible, "pause hides numbers")
	var elapsed: float = app.game.elapsed
	var position: Vector2 = first.position
	await frames(20)
	check(app.game.elapsed == elapsed and first.position == position, "pause freezes both clock and physics")
	await touch(Vector2(360, 715))
	check(app.game.state == Round.State.RUNNING and app.world.visible, "resume button")
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(app.game.state == Round.State.PAUSED, "background auto pause")
	app._home()
	await touch(Vector2(360, 527))
	check(app.screen == "pause" and app.game.next == 2, "saved round restores paused")
	app._resume()
	# Force two real bodies into a head-on collision and assert velocity reversal.
	for i in range(app.orbs.size()):
		app.orbs[i].position = Vector2(130 + (i % 3) * 220, 700 + (i / 3) * 110)
	var a = app.orbs[0]
	var b = app.orbs[1]
	a.position = Vector2(240, 480)
	b.position = Vector2(440, 480)
	a.linear_velocity = Vector2(100, 0)
	b.linear_velocity = Vector2(-100, 0)
	a.bumped.connect(func(_at): collided = true)
	await frames(25)
	check(collided and a.linear_velocity.x < 0 and b.linear_velocity.x > 0, "rigid bodies collide and rebound")
	app.start_level(0)
	# Verify a real wall bounce without other bodies in the path.
	a = app.orbs[0]
	a.position = Vector2(40 + a.radius + 2, 470)
	a.linear_velocity = Vector2(-100, 0)
	await frames(8)
	check(a.linear_velocity.x > 0 and a.position.x >= 40 + a.radius - 1, "wall collision contains bodies")
	app._confirm_restart()
	await touch(Vector2(360, 820))
	check(app.screen == "play", "cancel restart resumes")
	app._confirm_restart()
	await touch(Vector2(360, 710))
	check(app.game.next == 1 and app.game.mistakes == 0, "confirmed restart resets")
	for level in range(9):
		app.start_level(level)
		await frames(2)
		check(app.orbs.size() == app.game.count, "correct body count")
		for number in range(1, app.game.count + 1):
			var orb = app.orbs.filter(func(o): return o.number == number)[0]
			await touch(orb.position)
		check(app.screen == "result" and app.game.state == Round.State.COMPLETE, "level completed with input events")
		check(app.store.unlocked == mini(8, level + 1), "next level unlocked")
		check(app.store.records.has(str(level)), "record saved")
		# Return home and start again exercises process-mode reset after pause.
		app._home()
	check(app.store.records.size() == 9, "all nine records persist")
	var path: String = app.store.path
	app.queue_free()
	await frames(2)
	app = Main.new()
	app.testing = true
	app.store.path = path
	root.add_child(app)
	await frames(2)
	check(app.store.unlocked == 8 and app.store.records.size() == 9, "fresh scene loads progress")
	DirAccess.remove_absolute(path)
	app.queue_free()
	await frames(2)
	print("SCENE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
