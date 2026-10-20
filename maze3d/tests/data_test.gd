extends SceneTree
## Authoring contract, legacy save coordinates, actual GLBs and FPS preferences.
const Levels=preload("res://scripts/level_data.gd")
const Assets=preload("res://scripts/asset_library.gd")
const Character=preload("res://scripts/character.gd")
var checks:=0
var app
func check(ok:bool,label:String) -> void:
	if not ok:push_error("FAILED: "+label);quit(1)
	assert(ok,label);checks+=1
func frames(n:int) -> void:
	for i in n:await physics_frame
func _initialize() -> void:call_deferred("run")
func run() -> void:
	check(Levels.count()==5,"five authored chapters exposed by the catalog")
	var legacy_hashes:=["63cc65cca7145a0856d40fdf320afbacc3639301463ac16a6ddff567e275ddaf","dc66bd55cae3bd7e1ba09aaeb0f158b40a77233c602e11a7855d65407d357850","3d2bf14c61624508c714943216600760e082ec7e7affc12d97a130b8e31b101e","97c77dc44b3237c92bfbd88d4a91132a7d4838dbe0ea9851227a5256f41e894a"]
	var legacy_objectives:=["f9b9521322734d8306dacd504dc1b2ecc8add9794373d4287788dc81fb6b894c","f4662f8f425496163902cc35ad9332c77dcf53b40d19d0b1a421a03c91923f17","3353d6793fc727baf1366220d6c7cb3d00a6c3573938ba3588b8bc3f64a70d81","d33c8aa12bb2c38b3cdff1da6bbcf23bb71944bd40df2573a65e426e55050403"]
	for i in Levels.count():
		var data:=Levels.load_chapter(i)
		check(not data.is_empty(),"chapter JSON passes the authoring contract")
		if i<4:check("\n".join(data.grid).sha256_text()==legacy_hashes[i],"legacy maze coordinates remain byte-for-byte stable")
		if i<4:
			var cells:PackedStringArray=[]
			for c in [data.start,data.goal]+data.beacons+data.motes:cells.append("%d,%d"%[c[0],c[1]])
			check("|".join(cells).sha256_text()==legacy_objectives[i],"legacy objective indices and collectible save bits remain stable")
	var data:=Levels.load_chapter(3)
	check(data.grid.size()==19 and data.scenery.size()>=20,"larger authored world has composed scenery")
	check(data.regions.size()==5 and data.motes.size()==18,"five distinct regions and eighteen pickups")
	var water:=0;var bridges:=0
	for row in data.grid:water+=row.count("~");bridges+=row.count("=")
	check(water>=30 and bridges==9,"three complete bridges cross the canal")
	for mutation in ["version","grid","beacons","motes","challenges","elevated_motes","scenery","regions","environment","seed"]:
		var invalid:Dictionary=data.duplicate(true)
		invalid[mutation]=null
		check(not Levels.validate(invalid).is_empty(),"malformed "+mutation+" is rejected without a runtime error")
	var invalid:Dictionary=data.duplicate(true)
	invalid.scenery[0].asset="missing_glb"
	check(not Levels.validate(invalid).is_empty(),"unknown asset ID is rejected")
	invalid=data.duplicate(true);invalid.beacons[0]=invalid.start
	check(not Levels.validate(invalid).is_empty(),"objectives cannot overlap spawn")
	invalid=data.duplicate(true);invalid.challenges[0].span=8
	check(not Levels.validate(invalid).is_empty(),"unjumpable obstacle rejected")
	invalid=data.duplicate(true);invalid.challenges[0].axis=[1,1]
	check(not Levels.validate(invalid).is_empty(),"diagonal jump challenges rejected")
	invalid=data.duplicate(true);invalid.grid[16]="#".repeat(19);invalid.grid[17]="#."+"#".repeat(17)
	check(not Levels.validate(invalid).is_empty(),"disconnected authored passages rejected")
	var models:=Node3D.new();root.add_child(models)
	var bad_catalog:Dictionary={"version":1,"assets":Assets.catalog().duplicate(true)}
	bad_catalog.assets.courtyard_tile.path="res://assets/models/missing.glb"
	check(not Assets.validate(bad_catalog).is_empty(),"missing GLB rejected before constructing a world")
	bad_catalog.assets.courtyard_tile.path=Assets.catalog().courtyard_tile.path
	bad_catalog.assets.courtyard_tile.colliders[0].size=[0,1,1]
	check(not Assets.validate(bad_catalog).is_empty(),"degenerate physics collider rejected")
	for id in Assets.catalog():
		var entry:Dictionary=Assets.catalog()[id]
		check(entry.path.ends_with(".glb") and ResourceLoader.exists(entry.path),"GLB exists: "+id)
		var source:String=ProjectSettings.globalize_path("res://").path_join("../"+entry.source).simplify_path()
		check(FileAccess.file_exists(source),"editable Blender source exists: "+id)
		var node:=Assets.instantiate(id,models,Vector3.ZERO,true)
		check(is_instance_valid(node) and node.get_meta("asset_id")==id,"real imported model instantiated: "+id)
		if id=="brown":
			check(entry.animation_nodes==Character.JOINTS,"catalog preserves the fourteen animation pivots")
			for name in Character.JOINTS:check(node.find_child(name,true,false)!=null,"Brown pivot exists: "+name)
		node.queue_free()
	models.queue_free()
	await frames(2)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);Engine.max_fps=0
	await frames(3)
	app.settings.show_fps=true;app.frame_counter.visible=true
	check(app.frame_counter.mouse_filter==Control.MOUSE_FILTER_IGNORE,"FPS overlay does not consume controls")
	app.action("fps")
	check(not app.frame_counter.visible and not app.settings.show_fps,"FPS preference hides the overlay")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(app.SAVE_PATH))
	check(saved.settings.show_fps==false,"FPS preference persisted to disk")
	app.settings.show_fps=true;app.load_progress()
	check(not app.settings.show_fps,"FPS preference restored from disk")
	app.action("fps");app.action("chapter3");app.start_game(false);await frames(8)
	check(app.world.maze.definition.id=="starbridge_garden","fourth chapter can actually start")
	check(app.frame_counter.visible,"FPS counter visible during play")
	app.pause_game();await frames(40)
	check(app.frame_counter.visible and not app.world.active,"FPS overlay remains enabled while paused")
	app.action("resume")
	check(app.resume_chapter({"chapter":0,"level_id":"starbridge_garden"})==3,"stable level ID selects restored chapter")
	check(app.resume_chapter({"chapter":2})==2,"legacy numeric chapter saves still load")
	var w=app.world
	var bridge:Vector3=w.maze.world(Vector2i(9,9))
	w.player.position=bridge+Vector3(0,.12,0);w.player.velocity=Vector3.ZERO;await frames(20)
	check(w.player.is_on_floor(),"bridge GLB has an actual walkable deck collider")
	w.safe_position=w.maze.world(w.maze.start)+Vector3(0,.08,0)
	w.player.position=w.maze.world(Vector2i(9,8))+Vector3(0,.12,0);w.player.velocity=Vector3.ZERO
	var rescues:int=w.rescues;await frames(65)
	check(w.rescues==rescues+1,"canal is a real opening and recovers safely")
	app.action("chapter4");app.start_game(false);await frames(8)
	w=app.world
	check(w.maze.definition.id=="sunland_lake" and w.mote_nodes.size()==24,"Sunland starts with all 24 stars")
	check(app.resume_chapter({"chapter":0,"level_id":"sunland_lake"})==4,"Sunland save uses stable ID")
	check(w.maze.definition.scenery.size()>=32,"Sunland landmark placements loaded")
	var sunland:Dictionary=w.maze.definition
	for bad in [null,{"floor":"missing"},{"bridge":"sunland_reeds"},{"roof":"sunland_bridge"}]:
		invalid=sunland.duplicate(true);invalid.surface_assets=bad
		check(not Levels.validate(invalid).is_empty(),"invalid or non-colliding surface palette rejected")
	w.player.position=w.maze.world(Vector2i(12,12))+Vector3(0,.12,0);w.player.velocity=Vector3.ZERO;await frames(20)
	check(w.player.is_on_floor(),"Sunland wooden crossing supports the player")
	w.safe_position=w.maze.world(w.maze.start)+Vector3(0,.08,0)
	w.player.position=w.maze.world(Vector2i(12,10))+Vector3(0,.12,0);w.player.velocity=Vector3.ZERO
	rescues=w.rescues;await frames(65)
	check(w.rescues==rescues+1,"Sunland lake safely recovers a fall")
	app.action("home");app.chapter=0;app.start_game(false)
	print("DATA: ",checks," checks, 0 failures")
	app.queue_free();await frames(3);OS.delay_msec(150);quit()
