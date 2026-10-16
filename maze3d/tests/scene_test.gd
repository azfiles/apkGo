extends SceneTree
var app
var checks:=0
func check(ok:bool,label:String) -> void:
	if not ok:push_error("FAILED: "+label);quit(1)
	assert(ok,label);checks+=1
func frames(n:int) -> void:
	for i in n:await physics_frame
func _initialize() -> void:call_deferred("run")
func walk(target:Vector2i) -> void:
	var w=app.world
	var route:Array=w.maze.path(w.maze.cell(w.player.position),target)
	for cell in route:
		var destination:Vector3=w.maze.world(cell)
		var ticks:=0
		while w.flat_distance(w.player.position,destination)>.13 and ticks<350:
			var diff:Vector3=destination-w.player.position
			var f:=Vector3(sin(w.yaw),0,-cos(w.yaw));var r:=Vector3(cos(w.yaw),0,sin(w.yaw))
			var speed:float=minf(1,diff.length()/.5)
			app.joystick=Vector2(diff.normalized().dot(r),-diff.normalized().dot(f))*speed
			ticks+=1;await physics_frame
		check(ticks<350,"physically walk route cell "+str(cell))
	app.joystick=Vector2.ZERO
	await frames(10)
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);Engine.max_fps=0
	await frames(3)
	check(app.page=="home","home startup")
	check(not quit_on_go_back,"native Android back must not auto-quit")
	for chapter in 3:
		app.chapter=chapter;app.start_game(false);await frames(6)
		var w=app.world
		check(w.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"perspective camera")
		check(w.joints.size()==7,"articulated real 3D model")
		var spawn:Vector3=w.player.position
		# Walk into boundary for two seconds: physical capsule must not cross it.
		app.joystick=Vector2(-1,0);await frames(130);app.joystick=Vector2.ZERO
		check(w.maze.walkable(w.maze.cell(w.player.position)),"wall collision stays in walkable tile")
		check(w.player.position.x>=spawn.x-1.72,"capsule radius prevents wall penetration")
		w.player.position=spawn;w.yaw=0;await frames(6)
		var before:float=w.elapsed;app.pause_game();await frames(60)
		check(is_equal_approx(w.elapsed,before),"pause freezes timer")
		check(w.player.position.distance_to(spawn)<.1,"pause freezes movement")
		app.action("resume")
		var e:float=w.energy;app.sprint_pointer=5;app.joystick=Vector2(0,-1);await frames(30)
		check(w.energy<e,"sprint consumes energy")
		app.reset_input();w.player.position=spawn;await frames(90)
		check(w.energy>.90,"stamina regenerates")
		w.hint();check(w.hint_time>0 and w.hints_used==1,"hint creates path")
		w.hint();check(w.hints_used==1,"hint cooldown blocks spam")
		# Gate stays locked before all objectives are complete.
		w.near_gate=true;w.interact();check(app.page=="play","locked gate cannot complete")
		# Exercise two-finger control using the same input path as Android.
		app.pointer_down(1,Vector2(150,560));app.pointer_move(1,Vector2(180,510),Vector2(30,-50))
		app.pointer_down(2,Vector2(800,350));var angle:float=w.yaw
		app.pointer_move(2,Vector2(860,350),Vector2(60,0));await frames(2)
		check(app.joystick.length()>.5 and w.yaw>angle,"simultaneous joystick and camera")
		app.pointer_up(1);app.pointer_up(2);check(app.joystick==Vector2.ZERO,"release clears movement")
		w.yaw=0;w.player.position=spawn;await frames(6)
		# Move continuously along every maze route to each beacon; no objective teleport.
		for i in 3:
			await walk(w.maze.beacons[i]);await frames(3)
			check(w.near_beacon==i,"proximity finds beacon")
			w.interact();check(i in w.activated,"interaction lights beacon")
		check(w.gate_surface.visible,"three beacons open portal")
		for cell in w.maze.motes:await walk(cell)
		check(w.collected.size()==12,"all twelve motes collect by collision")
		var saved:Dictionary=w.snapshot()
		app.save_progress();check(FileAccess.file_exists(app.SAVE_PATH),"atomic save written")
		app.world.build(chapter,saved);w=app.world;w.title_mode=false;w.active=true;await frames(3)
		check(w.activated.size()==3 and w.collected.size()==12,"restore progress")
		await walk(w.maze.goal);await frames(5)
		check(w.near_gate,"exit reachable by real movement")
		w.interact();check(app.page=="win" and app.finish_stars==3,"complete and award three stars")
		check(app.session.is_empty(),"completion clears unfinished session")
		print("SCENE: chapter ",chapter+1," physically completed; ",checks," checks")
	# Invalid position must never spawn through a wall.
	app.chapter=0;app.start_game(false)
	app.world.restore({"position":[999999,999999],"activated":[-1,999,1,1],"collected":[-1,999]})
	check(app.world.maze.walkable(app.world.maze.cell(app.world.player.position)),"invalid save position safely rejected")
	check(app.world.activated==[1],"invalid and duplicate progress rejected")
	app.action("map");var before:float=app.world.elapsed;await frames(60)
	check(is_equal_approx(before,app.world.elapsed),"map pauses exploration")
	app.action("close_map");check(app.world.active,"map returns to play")
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(app.page=="pause","Android back opens pause")
	app.action("resume")
	app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(app.page=="pause" and not app.world.active,"background loss pauses safely")
	print("SCENE: ",checks," checks, 0 failures")
	app.queue_free();await frames(3);OS.delay_msec(150);quit()
