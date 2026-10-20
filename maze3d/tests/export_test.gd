extends SceneTree
## Run with the host Godot and --main-pack pointing at the exported Linux binary.
## Tests are excluded from the pack, so pass this file's absolute path to --script.
var checks:=0
var app
func check(ok:bool,label:String) -> void:
	if not ok:push_error("FAILED: "+label);quit(1)
	assert(ok,label);checks+=1
func frames(n:int) -> void:
	for i in n:await physics_frame
func _initialize() -> void:call_deferred("run")
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);Engine.max_fps=0
	await frames(3)
	if app.settings.sound:app.action("sound")
	app.settings.show_fps=true;app.frame_counter.visible=true
	check(app.page=="home","export starts on the actual homepage")
	check(app.Levels.count()==5,"export contains the five-chapter JSON index")
	check(app.world.Assets.catalog().size()==34,"all dynamic GLBs resolve inside the exported pack")
	for chapter in app.Levels.count():
		app.chapter=chapter;app.start_game(false);await frames(8)
		check(app.page=="play","exported chapter starts")
		check(app.world.maze.chapter==chapter,"correct level data loaded")
		check(app.world.joints.size()==14,"exported Brown animation nodes intact")
		check(app.world.mote_nodes.size()==[12,12,12,18,24][chapter],"exported pickups loaded")
	check(app.world.maze.definition.scenery.size()>=32,"Sunland scenery instances included")
	app.pause_game();app.action("fps");check(not app.frame_counter.visible,"FPS can be hidden in the exported build")
	app.action("fps");check(app.frame_counter.visible,"FPS can be restored in the exported build")
	print("STANDALONE: ",checks," checks, 0 failures")
	app.queue_free();await frames(3);OS.delay_msec(150);quit()
