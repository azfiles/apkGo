extends SceneTree
## Focused regressions for jump physics, recovery, saves and the home viewer.
var app
var checks:=0
func check(ok:bool,label:String) -> void:
	if not ok:push_error("FAILED: "+label);quit(1)
	assert(ok,label);checks+=1
func frames(n:int) -> void:
	for i in n:await physics_frame
func _initialize() -> void:call_deferred("run")
func key(code:int,pressed:bool,echo:bool=false) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.echo=echo
	Input.parse_input_event(event);await frames(2)
func move_along(axis:Vector2i) -> void:
	app.world.yaw=0;app.joystick=Vector2(axis.x,axis.y)
func place(p:Vector3) -> void:
	app.reset_input();app.world.player.position=p+Vector3(0,.08,0);app.world.player.velocity=Vector3.ZERO
	await frames(8)
func run() -> void:
	root.size=Vector2i(1280,720)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);Engine.max_fps=0
	await frames(4)
	var w=app.world
	var yaw:float=w.preview_yaw
	app.pointer_down(1,Vector2(820,280));app.pointer_move(1,Vector2(1080,350),Vector2(260,70));app.pointer_up(1)
	check(absf(angle_difference(yaw,w.preview_yaw))>1.5,"home drag rotates to another side")
	check(w.preview_pitch>.5,"home vertical drag changes elevation")
	var held_yaw:float=w.preview_yaw;await frames(30)
	check(is_equal_approx(held_yaw,w.preview_yaw),"home pose remains where released")
	app.pointer_down(7,Vector2(800,300));app.pointer_move(7,Vector2(1000,330),Vector2.ZERO);app.pointer_up(7)
	check(absf(angle_difference(held_yaw,w.preview_yaw))>1.5,"absolute touch positions rotate even when a device reports zero relative motion")
	check(is_zero_approx(w.yaw),"preview orbit does not change gameplay yaw")
	for i in 8:w.orbit_preview(Vector2(100,0))
	check(w.preview_yaw>=-PI and w.preview_yaw<=PI,"orbit supports full revolutions without a horizontal stop")
	app.pointer_down(2,Vector2(780,280));app.pointer_down(3,Vector2(980,280))
	var distance:float=w.preview_distance
	app.pointer_move(3,Vector2(1100,280),Vector2(120,0))
	check(w.preview_distance<distance,"two-finger pinch zooms in")
	app.pointer_up(2);app.pointer_up(3)
	w.zoom_preview(.001);check(is_equal_approx(w.preview_distance,3.8),"zoom cannot enter character")
	w.zoom_preview(100);check(is_equal_approx(w.preview_distance,8.0),"zoom-out bounded")
	w.orbit_preview(Vector2(0,10000));check(w.preview_pitch<=1.25,"preview avoids pole flip")
	app.action("preview_auto");yaw=w.preview_yaw;await frames(20)
	check(not is_equal_approx(yaw,w.preview_yaw),"auto rotation works")
	app.action("preview_reset")
	check(is_equal_approx(w.preview_yaw,-.5) and is_equal_approx(w.preview_distance,6) and not w.preview_auto,"reset restores front framing")
	check(not w.request_jump(),"home cannot jump")
	app.pointer_down(4,Vector2(800,300));app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(app.preview_pointers.is_empty(),"focus loss releases home gestures")

	app.start_game(false);await frames(10)
	w=app.world
	var ground:float=w.player.position.y
	await key(KEY_SPACE,true);await key(KEY_SPACE,false)
	check(w.jumps==1 and w.player.position.y>ground+.1,"space starts a physical jump")
	var peak:float=w.player.position.y
	for i in 52:
		if i==6:await key(KEY_SPACE,true,true);await key(KEY_SPACE,false)
		if i==8:w.request_jump()
		await frames(1);peak=maxf(peak,w.player.position.y)
	check(peak>1.1 and peak<1.4,"jump height clears rails but not full walls")
	check(w.jumps==1,"key repeat and early airborne press cannot double jump")
	check(w.player.is_on_floor() and absf(w.player.position.y-ground)<.04,"jump lands on the floor")

	w.request_jump();await frames(10)
	var position:Vector3=w.player.position;var velocity:Vector3=w.player.velocity
	app.pause_game();await frames(25)
	check(w.player.position.is_equal_approx(position) and w.player.velocity.is_equal_approx(velocity),"pause preserves airborne position and velocity")
	check(not w.request_jump(),"pause ignores jump requests")
	app.action("resume");await frames(50)
	check(w.player.is_on_floor(),"resume finishes the interrupted jump")
	w.request_jump();await frames(4)
	for i in 60:
		await frames(1)
		if w.player.velocity.y<0 and w.player.position.y<.22:break
	var before:int=w.jumps
	w.request_jump();await frames(12)
	check(w.jumps==before+1 and not w.player.is_on_floor(),"late press buffers a jump on landing")
	await frames(50)

	for chapter in 3:
		app.chapter=chapter;app.start_game(false);w=app.world;await frames(8)
		var hurdle:Dictionary={};var gap:Dictionary={}
		for challenge in w.maze.challenges:
			if challenge.kind=="hurdle":hurdle=challenge
			elif challenge.kind=="gap":gap=challenge
		var axis:=Vector3(hurdle.axis.x,0,hurdle.axis.y)
		var center:Vector3=w.maze.world(hurdle.cell)
		await place(center-axis*1.5);move_along(hurdle.axis);await frames(40)
		check((w.player.position-center).dot(axis)<-.5,"chapter %d rail blocks walking"%chapter)
		w.request_jump();await frames(55);app.reset_input()
		check((w.player.position-center).dot(axis)>.9,"chapter %d jump clears rail"%chapter)

		axis=Vector3(gap.axis.x,0,gap.axis.y);center=w.maze.world(gap.cell)
		await place(center-axis*1.32)
		w.safe_position=w.maze.world(gap.cell-gap.axis)+Vector3(0,.08,0)
		w.activated.assign([0]);w.collected.assign([0])
		var rescues:int=w.rescues
		move_along(gap.axis)
		for i in 100:
			await frames(1)
			if w.rescues>rescues:break
		app.reset_input()
		check(w.rescues==rescues+1,"chapter %d actual gap causes a fall"%chapter)
		check(w.flat_distance(w.player.position,w.safe_position)<.2,"fall returns to safe ground")
		check(w.activated==[0] and w.collected==[0],"fall preserves objectives and pickups")
		await place(center-axis*1.32);move_along(gap.axis);w.request_jump()
		await frames(52);app.reset_input()
		check(w.rescues==rescues+1 and (w.player.position-center).dot(axis)>.9,"chapter %d jump clears the gap"%chapter)
		check(w.player.is_on_floor(),"gap crossing has a supported landing")

		var high:int=w.maze.elevated_motes[-1]
		w.collected.erase(high)
		await place(w.maze.world(w.maze.motes[high]));await frames(30)
		check(high not in w.collected,"high mote cannot be collected from the ground")
		w.request_jump();await frames(50)
		check(high in w.collected,"jump collects the aerial mote")
		w.player.position=center+Vector3(0,1,0)
		var saved:Dictionary=w.snapshot()
		var saved_p:=Vector3(saved.position[0],0,saved.position[1])
		check(w.maze.safe_cell(w.maze.cell(saved_p)),"midair save records a safe landing")
		w.restore({"position":[center.x,center.z]})
		check(w.maze.safe_cell(w.maze.cell(w.player.position)),"old save on a new obstacle moves to adjacent safe ground")
		print("JUMP: chapter ",chapter+1," rail, gap and aerial collectible verified")

	# Step off an edge, then jump within the brief grace interval.
	app.chapter=0;app.start_game(false);w=app.world;await frames(8)
	var gap:Dictionary={}
	for challenge in w.maze.challenges:
		if challenge.kind=="gap":gap=challenge;break
	var axis:=Vector3(gap.axis.x,0,gap.axis.y);var center:Vector3=w.maze.world(gap.cell)
	await place(center-axis*(gap.span/2+.35));move_along(gap.axis)
	for i in 40:
		await frames(1)
		if not w.player.is_on_floor():break
	w.request_jump();await frames(4)
	check(w.jumps==1 and w.player.velocity.y>0,"edge grace accepts a slightly late jump")
	app.reset_input()
	print("JUMP: ",checks," checks, 0 failures")
	app.queue_free();await frames(3);OS.delay_msec(150);quit()
