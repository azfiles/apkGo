extends SceneTree
## Real rendered UI interactions; screenshots are separate from traversal tests.
var app
var checks:=0
var output:="res://../build/maze3d/starbridge-screens"
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in n:await process_frame
func check(ok:bool,label:String) -> void:
	if not ok:push_error("FAILED: "+label);quit(1)
	assert(ok,label);checks+=1
func click(id:String) -> void:
	await frames(2)
	for button in app.ui.buttons:
		if button.id!=id:continue
		var point:Vector2=button.rect.get_center()*app.ui.factor()
		for pressed in [true,false]:
			var event:=InputEventScreenTouch.new();event.index=6;event.position=point;event.pressed=pressed
			root.push_input(event,true)
		return
	check(false,"rendered button exists: "+id)
func capture(name:String) -> void:
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png")
	print("CAPTURE: ",name)
func place(cell:Vector2i,yaw:float) -> void:
	var w=app.world
	w.player.position=w.maze.world(cell)+Vector3(0,.1,0);w.player.velocity=Vector3.ZERO
	w.yaw=yaw;w.pitch=.45;w.camera_ready=false
	app.toast_timer=0;app.tutorial_time=0
func run() -> void:
	if OS.get_cmdline_user_args().size()>0:output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	app.settings.show_fps=true;app.frame_counter.visible=true
	await frames(35)
	await capture("01-four-chapters")
	await click("chapter3")
	check(app.chapter==3,"fourth chapter card accepts touch")
	await click("start");await frames(5)
	check(app.page=="play" and app.world.maze.definition.id=="starbridge_garden","touch starts the new authored chapter")
	place(Vector2i(7,15),PI/2)
	await capture("02-starbridge")
	place(Vector2i(15,11),0)
	await capture("03-fountain-court")
	await click("pause")
	check(app.page=="pause","pause remains accessible with FPS overlay")
	await capture("04-fps-on")
	await click("fps")
	check(not app.frame_counter.visible,"touch hides FPS")
	await capture("05-fps-off")
	await click("fps")
	check(app.frame_counter.visible,"touch restores FPS")
	await click("resume")
	app.action("map")
	for z in app.world.maze.width:
		for x in app.world.maze.width:app.world.maze.seen[Vector2i(x,z)]=true
	await capture("06-waterways-map")
	app.action("close_map");app.world.active=false;app.world.set_physics_process(false)
	app.world.camera.position=Vector3(67,72,82);app.world.camera.look_at(Vector3(0,0,0));app.world.camera.fov=50
	app.ui.visible=false;app.frame_counter.visible=false
	await capture("07-world-overview")
	print("STARBRIDGE RENDER: ",checks," checks, 0 failures")
	app.queue_free();await frames(3);OS.delay_msec(150);quit()
