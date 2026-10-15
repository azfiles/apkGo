extends SceneTree

const Main = preload("res://scripts/main.gd")
var app
var destination: String

func _initialize() -> void:
	destination = OS.get_cmdline_user_args()[0]
	call_deferred("run")

func capture(label: String) -> void:
	for i in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(destination.path_join(label + ".png"))

func run() -> void:
	root.size = Vector2i(720, 1280)
	app = Main.new()
	app.testing = true
	app.store.path = "user://preview-%d.json" % OS.get_process_id()
	root.add_child(app)
	await capture("home")
	app.start_level(0)
	await capture("play")
	for n in range(1, 10):
		var orb = app.orbs.filter(func(o): return o.number == n)[0]
		app._tap(orb)
	await capture("result")
	DirAccess.remove_absolute(app.store.path)
	app.queue_free()
	await process_frame
	quit()
