extends "res://tests/starbridge_capture.gd"
## Real UI selection and rendered review of the Sunland adaptation.
func run() -> void:
	output="res://../build/maze3d/sunland-screens"
	if OS.get_cmdline_user_args().size()>0:output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	app.settings.show_fps=true;app.frame_counter.visible=true
	await frames(25)
	await capture("17-five-chapters")
	for i in app.Levels.count():
		await click("chapter%d"%i)
		check(app.chapter==i,"chapter card accepts touch: %d"%i)
	await click("start");await frames(8)
	check(app.page=="play" and app.world.maze.definition.id=="sunland_lake","touch opens fifth chapter")
	place(Vector2i(5,12),PI/2)
	await capture("18-sunland-crossing")
	place(Vector2i(5,9),.9)
	app.world.set_physics_process(false)
	app.world.camera.position=Vector3(-43,15,3)
	app.world.camera.look_at(Vector3(-20.8,5,-20.8))
	await capture("19-sunland-camp")
	app.world.set_physics_process(true)
	place(Vector2i(21,4),-PI/2)
	await capture("20-sunland-pavilion")
	await click("pause");check(app.page=="pause","Sunland pause accepts touch")
	await click("fps");check(not app.frame_counter.visible,"Sunland FPS can be hidden")
	await click("fps");await click("resume")
	app.action("map")
	for z in app.world.maze.width:
		for x in app.world.maze.width:app.world.maze.seen[Vector2i(x,z)]=true
	await capture("21-sunland-map")
	app.action("close_map");app.world.active=false;app.world.set_physics_process(false)
	app.world.camera.position=Vector3(65,87,78);app.world.camera.look_at(Vector3(0,0,0));app.world.camera.fov=55
	app.ui.visible=false;app.frame_counter.visible=false
	await capture("22-sunland-overview")
	app.ui.visible=true;app.action("home");await click("credits")
	check(app.page=="credits","visible attribution page opens")
	await capture("23-sunland-credits")
	await click("close_credits");check(app.page=="home","attribution page closes")
	print("SUNLAND RENDER: ",checks," checks, 0 failures")
	app.queue_free();await frames(3);OS.delay_msec(150);quit()
