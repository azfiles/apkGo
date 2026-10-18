extends SceneTree
var app
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:push_error(label);quit(1)
	assert(ok,label);checks+=1
func frames(n:int) -> void:
	for i in n:await physics_frame
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	app.settings.sound=false;app.world.muted=true
	await frames(3)
	var w=app.world
	var rig=w.character
	check(rig.joints.size()==14,"all connected animation pivots exported")
	check(rig.joints.Head.get_parent()==rig.joints.Torso,"head inherits every chest movement")
	check(rig.joints.Torso.get_parent()==rig.joints.Body,"chest inherits whole-body bounce")
	for side in ["L","R"]:
		check(rig.joints["Elbow"+side].get_parent()==rig.joints["Arm"+side],"elbow stays attached to upper arm")
		check(rig.joints["Knee"+side].get_parent()==rig.joints["Leg"+side],"knee stays attached to upper leg")
	var head_mesh:MeshInstance3D=rig.joints.Head.get_node("Head_Mesh")
	var chest_mesh:MeshInstance3D=rig.joints.Torso.get_node("Torso_Mesh")
	check(head_mesh.get_aabb().size.z>.7,"head has front-to-back volume")
	check(chest_mesh.get_aabb().size.z>.5,"shirt has front-to-back volume")
	for phase in [0.0,PI/2,PI,PI*1.5]:
		rig.step(.2,Vector3(5.5,0,0),true,phase,1.0)
		var head_bounds:AABB=head_mesh.global_transform*head_mesh.get_aabb()
		var chest_bounds:AABB=chest_mesh.global_transform*chest_mesh.get_aabb()
		check(head_bounds.position.y<chest_bounds.end.y,"neck and head remain overlapping throughout run")
		check(rig.joints.Head.position.is_equal_approx(rig.base.Head),"head never bobs away from neck")
	check(rig.joints.ElbowL.rotation.x<-.3,"run uses bent elbows")
	check(rig.expression=="Focus","running changes facial expression")
	rig.mood_time=0;rig.step(.2,Vector3(2,6,0),false,0,1.0)
	check(rig.expression=="Surprise","jump has surprised expression")
	var takeoff_knee:float=rig.joints.KneeL.rotation.x
	rig.step(.2,Vector3(2,-5,0),false,0,1.0)
	check(rig.joints.KneeL.rotation.x<takeoff_knee,"legs extend in preparation for landing")
	rig.step(.016,Vector3.ZERO,true,0,1.0)
	check(rig.landing>.8,"ground contact starts a brief landing compression")
	for expression in rig.EXPRESSIONS:
		rig.emote(expression,.5)
		var visible:=0
		for face in rig.faces.values():visible+=1 if face.visible else 0
		check(visible==1 and rig.faces[expression].visible,"exactly one mouth/expression rendered")
		check(rig.eyes[0].visible==(expression!="Joy"),"joy uses curved smiling eyes")
	rig.mood_time=0;rig.step(.2,Vector3.ZERO,true,0,2.29,true)
	check(rig.eyes[0].scale.y<.2,"idle blink closes both eyes")
	rig.step(.2,Vector3.ZERO,true,0,3.0,true)
	check(rig.eyes[0].scale.y>.9,"eyes reopen after a blink")
	app.action("preview_expression")
	check(rig.mood_time>0,"homepage expression control is wired")
	app.start_game(false);await frames(5);w=app.world
	w.character.emote("Smile",.01)
	w.player.position=w.mote_nodes[0].position-Vector3(0,.85,0);w.player.velocity=Vector3.ZERO
	await frames(3)
	check(0 in w.collected and w.character.expression=="Joy","collecting a real star triggers joy")
	check(w.mote_nodes[1].find_child("PuffyFivePointStar",true,false)!=null,"collectibles use the new three-dimensional star")
	print("CHARACTER: ",checks," checks, 0 failures")
	app.queue_free();await frames(3);OS.delay_msec(150);quit()
