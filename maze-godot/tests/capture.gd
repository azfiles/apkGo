extends SceneTree

const Main = preload("res://scripts/main.gd")
var app
var destination: String

func _initialize() -> void:
	destination = OS.get_cmdline_user_args()[0]
	call_deferred("run")

func capture(label_: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(destination.path_join(label_ + ".png"))
	print("CAPTURE: ", label_, " | draw calls: ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))

func run() -> void:
	root.size = Vector2i(1280, 800)
	app = Main.new()
	app.testing = true
	app.store.path = "user://capture-%s.json" % OS.get_process_id()
	root.add_child(app)
	await capture("01-home")
	app.start_play()
	app.world.navigate(app.model.stamps[0])
	await create_timer(2.3).timeout
	app.show_hint()
	await capture("02-play")
	app.state = "home"
	app.load_level(1)
	await capture("03-pond")
	app.load_level(2)
	await capture("04-twilight")
	app.load_level(0)
	app.start_play()
	app.world.active = false
	for target in app.model.stamps + [app.model.goal]:
		for cell in app.model.path_to(target): app.world._visit(cell)
	await capture("05-complete")
	DirAccess.remove_absolute(app.store.path)
	app.queue_free()
	await process_frame
	quit()
