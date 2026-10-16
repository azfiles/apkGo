extends SceneTree
var app
var output:= "/workspace/work/pipi-3d/screens"
func _initialize() -> void:call_deferred("run")
func wait_frames(n:int) -> void:
	for i in n:await process_frame
func capture(name:String) -> void:
	print("CAPTURE: ",name)
	await wait_frames(3)
	await RenderingServer.frame_post_draw
	print("RENDER: draws=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	root.get_texture().get_image().save_png(output+"/"+name+".png")
func run() -> void:
	if OS.get_cmdline_user_args().size()>0:output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	print("CAPTURE: instantiate")
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	print("CAPTURE: waiting initial frames")
	await wait_frames(3)
	await capture("01-home")
	app.start_game(false)
	await wait_frames(3)
	await capture("02-play")
	app.world.hint()
	await capture("03-hint")
	app.action("pause")
	await capture("04-pause")
	app.action("resume")
	var w=app.world
	w.player.position=w.light_nodes[0].position*Vector3(1,0,1)+Vector3(0,.1,1.4)
	w.yaw=0;w.pitch=.4;w.camera_ready=false
	await wait_frames(3)
	await capture("05-beacon")
	w.interact()
	await capture("06-lit")
	w.activated.assign([0,1,2]);w.update_gate()
	w.player.position=w.gate.position+w.gate.global_basis.z*2.3+Vector3(0,.1,0)
	var direction:Vector3=-w.gate.global_basis.z
	w.yaw=atan2(direction.x,-direction.z);w.avatar.rotation.y=atan2(direction.x,direction.z);w.camera_ready=false
	await capture("07-portal")
	w.player.position=w.gate.position+w.gate.global_basis.z*1.4+Vector3(0,.1,0)
	await wait_frames(3);w.interact()
	await capture("08-complete")
	app.queue_free();await wait_frames(3);OS.delay_msec(150);quit()
