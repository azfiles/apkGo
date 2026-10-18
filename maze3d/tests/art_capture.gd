extends SceneTree
## Actual engine render of expressions and animation phases for visual review.
const Character=preload("res://scripts/character.gd")
var stage:Node3D
func _initialize() -> void:call_deferred("run")
func run() -> void:
	stage=Node3D.new();root.add_child(stage)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("eef3df")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("e1f0ea");environment.environment.ambient_light_energy=.42
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	stage.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_color=Color("fff0d2");light.light_energy=.65;stage.add_child(light)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,150,0);fill.light_energy=.12;stage.add_child(fill)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=6.1;camera.position=Vector3(0,2.6,12);stage.add_child(camera);camera.current=true
	var labels:=["微笑 / SMILE","开心 / JOY","惊讶 / SURPRISE","专注 / FOCUS","跑步 / RUN A","跑步 / RUN B","起跳 / TAKEOFF","落地 / LANDING"]
	for i in 8:
		var model:Node3D=load("res://assets/models/brown.glb").instantiate();stage.add_child(model)
		model.position=Vector3(-3.6+(i%4)*2.4,2.8 if i<4 else .1,0)
		var rig:=Character.new();rig.bind(model)
		if i<4:rig.emote(rig.EXPRESSIONS[i],20)
		else:
			model.rotation.y=-.5
			for frame in 40:
				match i:
					4:rig.step(1.0/60,Vector3(5.5,0,0),true,PI/2,1.0)
					5:rig.step(1.0/60,Vector3(5.5,0,0),true,PI*1.5,1.0)
					6:rig.step(1.0/60,Vector3(2,6,0),false,0,1.0)
					7:rig.step(1.0/60,Vector3(2,-4,0),false,0,1.0)
			if i==7:rig.step(.016,Vector3.ZERO,true,0,1.0)
		var label:=Label3D.new();label.text=labels[i];label.font=load("res://assets/ui-bold.otf");label.font_size=32;label.pixel_size=.005;label.modulate=Color("365b50");label.outline_size=0;label.position=model.position+Vector3(0,-.22,0);stage.add_child(label)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	var output:=OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(output)
	print("ART: expressions and four motion phases rendered")
	stage.queue_free();await process_frame;quit()
