extends SceneTree
var app
var checks:=0
var output:= "/workspace/work/pipi-3d/screens"
func _initialize() -> void:call_deferred("run")
func wait_frames(n:int) -> void:
	for i in n:await process_frame
func check(ok:bool,label:String) -> void:
	if not ok:push_error("FAILED: "+label);quit(1)
	assert(ok,label);checks+=1
func touch(index:int,p:Vector2,pressed:bool) -> void:
	var event:=InputEventScreenTouch.new();event.index=index;event.position=p*app.ui.factor();event.pressed=pressed
	root.push_input(event,true)
func drag(index:int,p:Vector2,relative:Vector2) -> void:
	var event:=InputEventScreenDrag.new();event.index=index;event.position=p*app.ui.factor();event.relative=relative*app.ui.factor()
	root.push_input(event,true)
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
	app.session={};app.records={}
	print("CAPTURE: waiting initial frames")
	await wait_frames(3)
	await capture("01-home")
	if OS.get_cmdline_user_args().has("--home-only"):
		app.queue_free();await wait_frames(3);OS.delay_msec(150);quit();return
	app.action("preview_expression")
	check(app.world.character.expression=="Joy","homepage control changes the actual face geometry")
	await capture("01d-home-joy")
	app.world.character.emote("Smile",.01)
	var yaw:float=app.world.preview_yaw
	touch(1,Vector2(800,270),true);drag(1,Vector2(1010,305),Vector2(210,35));touch(1,Vector2(1010,305),false)
	check(absf(angle_difference(yaw,app.world.preview_yaw))>1,"rendered home accepts a real touch rotation")
	await capture("01a-home-side")
	app.world.preview_yaw=PI-.5;app.world.preview_pitch=.18
	await capture("01b-home-back")
	app.world.preview_pitch=1.05
	await capture("01c-home-above")
	app.world.reset_preview()
	app.world.preview_yaw=1.0
	await wait_frames(2)
	touch(1,Vector2(app.ui.width()-150,480),true);touch(1,Vector2(app.ui.width()-150,480),false)
	check(is_equal_approx(app.world.preview_yaw,-.5),"home reset control remains clickable")
	var scroll:=InputEventMouseButton.new();scroll.position=Vector2(900,280)*app.ui.factor();scroll.button_index=MOUSE_BUTTON_WHEEL_UP;scroll.pressed=true
	root.push_input(scroll,true)
	check(app.world.preview_distance<6,"mouse wheel zooms the home character")
	touch(1,Vector2(207,513),true);touch(1,Vector2(207,513),false)
	check(app.page=="play","real home primary button starts game")
	await wait_frames(3)
	await capture("02-play")
	var jumps:int=app.world.jumps
	touch(1,Vector2(155,565),true);drag(1,Vector2(155,510),Vector2(0,-55))
	touch(2,Vector2(800,320),true);drag(2,Vector2(825,320),Vector2(25,0))
	touch(3,Vector2(app.ui.width()-228,520),true)
	await wait_frames(3)
	check(app.world.jumps==jumps+1,"touch jump works while movement and camera fingers are held")
	check(app.move_pointer==1 and app.look_pointer==2,"jump keeps both other gestures active")
	touch(1,Vector2(155,510),false);touch(2,Vector2(825,320),false);touch(3,Vector2(app.ui.width()-228,520),false)
	await capture("02a-jump")
	app.world.hint()
	await capture("03-hint")
	app.action("pause")
	await capture("04-pause")
	app.action("resume")
	var w=app.world
	w.player.position=w.light_nodes[0].position*Vector3(1,0,1)+Vector3(0,.1,1.4)
	w.player.velocity=Vector3.ZERO
	w.yaw=0;w.pitch=.4;w.camera_ready=false
	await wait_frames(12)
	await capture("05-beacon")
	w.interact()
	check(0 in w.activated,"beacon screenshot reflects a real successful interaction")
	await capture("06-lit")
	w.activated.assign([0,1,2]);w.update_gate();app.toast_timer=0;app.tutorial_time=0
	w.player.position=w.gate.position+w.gate.global_basis.z*2.3+Vector3(0,.1,0)
	var direction:Vector3=-w.gate.global_basis.z
	w.yaw=atan2(direction.x,-direction.z);w.avatar.rotation.y=atan2(direction.x,direction.z);w.camera_ready=false
	await capture("07-portal")
	w.player.position=w.gate.position+w.gate.global_basis.z*1.4+Vector3(0,.1,0)
	w.player.velocity=Vector3.ZERO
	await wait_frames(12);w.interact()
	check(app.page=="win","completion screenshot shows the result screen")
	await capture("08-complete")
	app.chapter=0;app.start_game(false);app.tutorial_time=0;app.toast_timer=0
	w=app.world
	for challenge in w.maze.challenges:
		var axis:=Vector3(challenge.axis.x,0,challenge.axis.y)
		w.player.position=w.maze.world(challenge.cell)-axis*2.4+Vector3(0,.08,0)
		w.player.velocity=Vector3.ZERO;w.yaw=atan2(axis.x,-axis.z);w.avatar.rotation.y=atan2(axis.x,axis.z);w.pitch=.55;w.camera_ready=false
		await wait_frames(3)
		await capture("09-"+challenge.kind)
		if challenge.kind=="gap":break
	print("RENDER: ",checks," checks, 0 failures")
	app.queue_free();await wait_frames(3);OS.delay_msec(150);quit()
