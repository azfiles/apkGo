extends Node3D
signal picked
signal lit
signal escaped
signal message(text: String)
const Maze = preload("res://scripts/maze.gd")
const MODEL_PATH := "res://assets/models/"
var maze = Maze.new()
var player: CharacterBody3D
var avatar: Node3D
var camera: Camera3D
var geo: Node3D
var dynamic: Node3D
var light_nodes: Array[Node3D] = []
var mote_nodes: Array[Node3D] = []
var activated: Array[int] = []
var collected: Array[int] = []
var route_root: Node3D
var gate: Node3D
var gate_surface: MeshInstance3D
var active := false
var title_mode := true
var input_move := Vector2.ZERO
var sprint := false
var energy := 1.0
var elapsed := 0.0
var clock := 0.0
var yaw := 0.0
var pitch := 0.40
var hint_time := 0.0
var hint_cooldown := 0.0
var hints_used := 0
var near_beacon := -1
var near_gate := false
var foot_time := 0.0
var save_clock := 0.0
var moving := false
var camera_ready := false
var camera_distance := 6.8
var high_quality := true
var materials: Dictionary = {}
var scenes: Dictionary = {}
var joints: Dictionary = {}
var joint_base: Dictionary = {}
var fireflies: MultiMeshInstance3D
var firefly_base: Array[Vector3] = []
var fx: Array = []
var env: Environment
var sun: DirectionalLight3D
var lamp_lights: Array[OmniLight3D] = []
var lantern_positions: Array[Vector3] = []
var step_audio: AudioStreamPlayer
var chime_audio: AudioStreamPlayer
var muted := false
var desired_camera := Vector3.ZERO
var last_position := Vector3.ZERO
var walking_phase := 0.0
var low_speed := 0.0
var wall_materials: Dictionary = {}

func _ready() -> void:
	var environment := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("19384e")
	sky_mat.sky_horizon_color=Color("879c9e")
	sky_mat.ground_bottom_color=Color("132e40")
	sky_mat.ground_horizon_color=Color("879c9e")
	sky_mat.sky_curve=.22
	sky_mat.sun_angle_max=8
	sky.sky_material=sky_mat;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("a2c1cc");env.ambient_light_energy=.38
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true;env.fog_light_color=Color("547b89");env.fog_density=.006
	environment.environment=env;add_child(environment)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-44,-38,0)
	sun.light_color=Color("ffdea1");sun.light_energy=.85
	sun.shadow_enabled=true;sun.directional_shadow_max_distance=65
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias=.15;sun.shadow_normal_bias=3.0
	add_child(sun)
	var rim:=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-25,150,0);rim.light_color=Color("83c9de");rim.light_energy=.20;add_child(rim)
	camera=Camera3D.new();camera.fov=52;camera.near=.15;camera.far=180;camera.current=true;add_child(camera)
	step_audio=AudioStreamPlayer.new();step_audio.stream=load("res://assets/audio/step.wav");step_audio.volume_db=-14;add_child(step_audio)
	chime_audio=AudioStreamPlayer.new();chime_audio.volume_db=-7;add_child(chime_audio)
	for i in 3:
		var lamp:=OmniLight3D.new();lamp.light_color=Color("ffd38c");lamp.omni_range=5;lamp.light_energy=.65
		add_child(lamp);lamp_lights.append(lamp)

func build(chapter: int, saved: Dictionary = {}) -> void:
	active=false;camera_ready=false
	input_move=Vector2.ZERO;sprint=false;energy=1.0;elapsed=0.0;clock=0.0
	activated.clear();collected.clear();light_nodes.clear();mote_nodes.clear();joints.clear();joint_base.clear();fx.clear();lantern_positions.clear()
	hint_time=0;hint_cooldown=0;hints_used=0;near_beacon=-1;near_gate=false
	if geo:remove_child(geo);geo.queue_free()
	if dynamic:remove_child(dynamic);dynamic.queue_free()
	geo=Node3D.new();add_child(geo)
	dynamic=Node3D.new();add_child(dynamic)
	maze.build(chapter)
	var rng:=RandomNumberGenerator.new();rng.seed=591+chapter
	var size:float=maze.width*Maze.TILE
	box(Vector3(size+3,.6,size+3),Vector3(0,-.35,0),"263f48",geo)
	collider(Vector3(size+4,.6,size+4),Vector3(0,-.35,0))
	# One shared mesh per material; _batch_static consolidates into GPU instances.
	var tile_mesh:=BoxMesh.new();tile_mesh.size=Vector3(3.96,.10,3.96)
	var mark_mesh:=BoxMesh.new();mark_mesh.size=Vector3(.40,.012,.055)
	var mark_mat:=material("546d70")
	var tile_mats: Array = [material("718585"),material("778b88"),material("82928a"),material("6c8182")]
	for z in maze.width:
		for x in maze.width:
			var cell:=Vector2i(x,z)
			var p:Vector3=maze.world(cell)
			if maze.walkable(cell):
				var tile:=MeshInstance3D.new();tile.mesh=tile_mesh;tile.material_override=tile_mats[rng.randi_range(0,3)];tile.position=p-Vector3(0,.07,0);geo.add_child(tile)
				for k in 3:
					var mark:=mesh(mark_mesh,mark_mat,geo,p+Vector3(rng.randf_range(-1.6,1.6),-.008,rng.randf_range(-1.6,1.6)));mark.rotation.y=PI/2 if k%2==0 else 0.0
				if rng.randf()<.34:
					var grass:=model("grass",geo,p+Vector3(1.56,.02,1.54));grass.rotation.y=rng.randf()*TAU
				if rng.randf()<.12 and cell!=maze.start:
					var pos:=p+Vector3(1.42,0,1.42)
					model("lantern",geo,pos);lantern_positions.append(pos+Vector3(0,1.7,0))
			else:
				var wall:=model("wall_"+str(rng.randi_range(0,2)),geo,p)
				apply_wall_material(wall)
				collider(Vector3(4,2.35,4),p+Vector3(0,1.15,0))
				if (x==0 or z==0 or x==maze.width-1 or z==maze.width-1) and (x+z)%3==0:
					var tree:=model("tree_"+str(chapter%2),geo,p+Vector3(0,2.25,0));tree.rotation.y=rng.randf()*TAU;tree.scale=Vector3.ONE*rng.randf_range(.85,1.35)
	# Distant low-poly ridgelines frame the ruins and give the horizon depth.
	var mountain:=CylinderMesh.new();mountain.top_radius=0;mountain.bottom_radius=1;mountain.height=1;mountain.radial_segments=7
	for i in 16:
		var angle:=float(i)*TAU/16
		var peak:=mesh(mountain,material(["2b4c5e","355b69","3b6270"][i%3]),geo,Vector3(cos(angle)*76,-3,sin(angle)*76))
		peak.scale=Vector3(rng.randf_range(12,22),rng.randf_range(15,28),rng.randf_range(13,21))
		peak.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Start plaza: inset mosaic, four welcoming lamps, and a tree on the edge.
	var start_p:Vector3=maze.world(maze.start)
	for ofs in [Vector3(-1.5,0,-1.5),Vector3(1.5,0,-1.5)]:
		model("lantern",geo,start_p+ofs);lantern_positions.append(start_p+ofs+Vector3(0,1.7,0))
	ring(1.25,.035,start_p+Vector3(0,.03,0),Color("d5bd83"),geo)
	for i in 3:
		var p:Vector3=maze.world(maze.beacons[i])+Vector3(1.05,0,-1.05)
		model("beacon",geo,p)
		collider(Vector3(.95,1.1,.95),p+Vector3(0,.55,0))
		ring(.95,.035,p+Vector3(0,.035,0),Color("b5c6ae"),geo)
		var orb:=model("crystal",dynamic,p+Vector3(0,1.85,0))
		light_nodes.append(orb)
	for i in maze.motes.size():
		var p:Vector3=maze.world(maze.motes[i])+Vector3(0,.85,0)
		var orb:=Node3D.new();orb.position=p;dynamic.add_child(orb)
		var gem:=SphereMesh.new();gem.radius=.12;gem.height=.24;gem.radial_segments=8;gem.rings=4
		mesh(gem,material("ffdc8f",true),orb,Vector3.ZERO)
		ring(.26,.018,Vector3.ZERO,Color("ffcf81"),orb).rotation.x=PI/2
		mote_nodes.append(orb)
	gate=Node3D.new();gate.position=maze.world(maze.goal);dynamic.add_child(gate)
	var adjacent:Array=maze.neighbors(maze.goal)
	if not adjacent.is_empty():
		var direction:Vector3=maze.world(adjacent[0])-gate.position
		gate.rotation.y=atan2(direction.x,direction.z)
	model("portal",gate,Vector3.ZERO)
	for side in [-1,1]:collider(Vector3(.8,3.0,.8),gate.to_global(Vector3(side*1.35,1.5,0)))
	var quad:=QuadMesh.new();quad.size=Vector2(2.2,3.0)
	gate_surface=mesh(quad,portal_material(),gate,Vector3(0,1.65,.08))
	gate_surface.visible=false
	for i in 3:
		var orb:=SphereMesh.new();orb.radius=.12;orb.height=.24
		mesh(orb,material("839494"),gate,Vector3(-.4+i*.4,3.23,.4))
	route_root=Node3D.new();dynamic.add_child(route_root)
	player=CharacterBody3D.new();player.name="Pipi";player.position=start_p+Vector3(0,.1,0);player.floor_snap_length=.3
	dynamic.add_child(player)
	var shape:=CapsuleShape3D.new();shape.radius=.30;shape.height=1.65
	var col:=CollisionShape3D.new();col.shape=shape;col.position.y=.83;player.add_child(col)
	avatar=model("pipi_explorer",player,Vector3.ZERO)
	avatar.rotation.y=PI
	for name in ["Torso","Head","ArmL","ArmR","LegL","LegR","ScarfTail"]:
		var node:=avatar.find_child(name,true,false)
		if node:joints[name]=node;joint_base[name]=node.position
	# Gentle contact shadow keeps the character grounded even on low quality.
	var shadow_mat:=StandardMaterial3D.new();shadow_mat.albedo_color=Color(0.02,.08,.09,.24);shadow_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;shadow_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var shadow:=CylinderMesh.new();shadow.top_radius=.36;shadow.bottom_radius=.36;shadow.height=.008
	mesh(shadow,shadow_mat,player,Vector3(0,.008,0))
	yaw=0;pitch=.40
	if not saved.is_empty():restore(saved)
	for i in activated:add_beam(i)
	update_gate()
	_batch_static()
	_make_fireflies(rng)
	last_position=player.position
	set_quality(high_quality)

func _physics_process(dt: float) -> void:
	if not is_instance_valid(player):return
	clock+=dt
	for i in light_nodes.size():
		var orb:=light_nodes[i];orb.position.y=1.85+sin(clock*2+i)*.13;orb.rotation.y=clock*.7
		orb.scale=Vector3.ONE*(.75 if i in activated else 1.0)
	for i in mote_nodes.size():
		mote_nodes[i].position.y=.85+sin(clock*2.8+i)*.14;mote_nodes[i].rotation.y=clock
	if active:
		elapsed+=dt;hint_time=maxf(0,hint_time-dt);hint_cooldown=maxf(0,hint_cooldown-dt)
		route_root.visible=hint_time>0
		var stick:=input_move.limit_length()
		if stick.length()<.12:stick=Vector2.ZERO
		var forward:=Vector3(sin(yaw),0,-cos(yaw))
		var right:=Vector3(cos(yaw),0,sin(yaw))
		var direction:=right*stick.x-forward*stick.y
		var running:=sprint and energy>.06 and direction.length()>.2
		energy=clampf(energy+dt*(-.25 if running else .19),0,1)
		var speed:=5.5 if running else 3.25
		var target:=direction*speed
		player.velocity.x=move_toward(player.velocity.x,target.x,dt*18)
		player.velocity.z=move_toward(player.velocity.z,target.z,dt*18)
		player.velocity.y-=18*dt
		player.move_and_slide()
		var traveled:=Vector2(player.position.x-last_position.x,player.position.z-last_position.z).length()
		moving=traveled>.003
		walking_phase+=traveled*7
		if moving:
			avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(direction.x,direction.z),minf(1,dt*12))
			foot_time+=traveled
			if foot_time>.9:
				foot_time=0
				if not muted:step_audio.pitch_scale=randf_range(.9,1.15);step_audio.play()
		var c:Vector2i=maze.cell(player.position)
		maze.reveal(c)
		near_beacon=-1;near_gate=false
		for i in light_nodes.size():
			if i not in activated and flat_distance(player.position,light_nodes[i].position)<1.65:near_beacon=i
		for i in mote_nodes.size():
			if i not in collected and flat_distance(player.position,mote_nodes[i].position)<.7:
				collected.append(i);mote_nodes[i].visible=false;burst(mote_nodes[i].position,Color("ffdc8f"));tone("mote");picked.emit()
		near_gate=flat_distance(player.position,gate.position)<1.8
		last_position=player.position
	else:
		moving=false;player.velocity=Vector3.ZERO
	animate_character(dt)
	update_camera(dt)
	update_fx(dt)
	if fireflies and high_quality:
		for i in firefly_base.size():
			var p:=firefly_base[i];p+=Vector3(sin(clock*.35+i)*.4,sin(clock*.8+i)*.3,cos(clock*.3+i)*.4)
			var tr:=Transform3D(Basis.IDENTITY,p);tr=tr.scaled_local(Vector3.ONE*(.025+.015*(1+sin(clock*2+i))))
			fireflies.multimesh.set_instance_transform(i,tr)
	for i in lamp_lights.size():
		var sorted:=lantern_positions.duplicate()
		sorted.sort_custom(func(a,b):return a.distance_squared_to(player.position)<b.distance_squared_to(player.position))
		lamp_lights[i].visible=high_quality and sorted.size()>i
		if sorted.size()>i:lamp_lights[i].position=sorted[i]

func animate_character(dt: float) -> void:
	var blend:=minf(1,dt*12)
	for name in ["ArmL","ArmR","LegL","LegR"]:
		if not joints.has(name):continue
		var sign:=1.0 if name in ["ArmL","LegR"] else -1.0
		var a:=sin(walking_phase)*.65*sign if moving else sin(clock*1.5)*.025*sign
		joints[name].rotation.x=lerpf(joints[name].rotation.x,a,blend)
	if joints.has("Torso"):joints.Torso.position.y=joint_base.Torso.y+(absf(sin(walking_phase))*.045 if moving else sin(clock*2)*.012)
	if joints.has("Head"):joints.Head.rotation.z=sin(walking_phase*.5)*.025 if moving else sin(clock*.8)*.025
	if joints.has("ScarfTail"):joints.ScarfTail.rotation.x=sin(clock*5)*.12+(.5 if moving else 0)

func update_camera(dt: float) -> void:
	if title_mode:
		var p:Vector3=maze.world(maze.start)+Vector3(4,0,-4)
		player.position=p;avatar.rotation.y=-.5
		var cam:=p+Vector3(-3.0+sin(clock*.10)*.25,2.65,5.5)
		camera.position=cam;camera.look_at(p+Vector3(-2.2,1.15,-.6))
		for mat in wall_materials.values():mat.set_shader_parameter("cutaway",false)
		return
	var focus:=player.global_position+Vector3(0,1.35,0)
	var distance:=6.8+(.65 if sprint and moving else 0.0)
	var offset:=Vector3(-sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	desired_camera=focus+offset
	# Occluders dissolve along the camera-to-character corridor; a fixed-distance
	# follow camera stays outside the avatar even beside a wall or in a dead end.
	var candidate:=camera.position.lerp(desired_camera,minf(1,dt*11)) if camera_ready else desired_camera
	candidate.y=maxf(candidate.y,3.1)
	camera.position=candidate;camera.look_at(focus);camera_ready=true
	for mat in wall_materials.values():
		mat.set_shader_parameter("hero",player.global_position)
		mat.set_shader_parameter("eye",camera.global_position)
		mat.set_shader_parameter("cutaway",true)
	camera.fov=lerpf(camera.fov,56.0 if sprint and moving else 52.0,minf(1,dt*3))

func interact() -> void:
	if not active:return
	if near_beacon>=0:
		var i:=near_beacon;activated.append(i);near_beacon=-1
		burst(light_nodes[i].position,Color("8ce8dd"),30)
		add_beam(i)
		tone("beacon");haptic(50);lit.emit();update_gate()
		message.emit("三座灯塔已点亮 · 出口苏醒了" if activated.size()==3 else "灯塔已点亮  %d / 3"%activated.size())
	elif near_gate:
		if activated.size()==3:active=false;tone("win");haptic(90);escaped.emit()
		else:message.emit("还需要点亮 %d 座灯塔"%(3-activated.size()))

func update_gate() -> void:
	gate_surface.visible=activated.size()==3
	var spheres:Array=[]
	for child in gate.get_children():
		if child is MeshInstance3D and child.mesh is SphereMesh:spheres.append(child)
	for i in spheres.size():spheres[i].material_override=material("ffda8a",true) if i<activated.size() else material("839494")

func hint() -> void:
	if not active:return
	if hint_cooldown>0:message.emit("引路灯正在充能 · %d 秒"%ceili(hint_cooldown));return
	for child in route_root.get_children():child.queue_free()
	var from:Vector2i=maze.cell(player.position)
	var target:Vector2i=maze.goal
	var best:=9999
	for i in 3:
		if i not in activated:
			var steps:int=maze.path(from,maze.beacons[i]).size()
			if steps<best:best=steps;target=maze.beacons[i]
	var path:Array=maze.path(from,target)
	path.push_front(from)
	for i in mini(path.size()-1,6):
		var a:Vector3=maze.world(path[i]);var b:Vector3=maze.world(path[i+1])
		for j in 5:
			var p:=a.lerp(b,float(j)/5.0)+Vector3(0,.07,0)
			var gem:=SphereMesh.new();gem.radius=.065;gem.height=.055;gem.radial_segments=6;gem.rings=3
			mesh(gem,material("ffe6a4",true),route_root,p)
	hint_time=8;hint_cooldown=13;hints_used+=1;route_root.visible=true;tone("hint");haptic(20)
	message.emit("跟随地面的金色光迹 · 持续 8 秒")

func reset_camera() -> void:
	yaw=wrapf(PI-avatar.rotation.y,-PI,PI);pitch=.40
func orbit(delta: Vector2) -> void:
	yaw-=delta.x*.005;pitch=clampf(pitch+delta.y*.003,.35,.95)
func set_quality(high: bool) -> void:
	high_quality=high;sun.shadow_enabled=high
	get_viewport().msaa_3d=Viewport.MSAA_2X if high else Viewport.MSAA_DISABLED
	if fireflies:fireflies.visible=high
func snapshot() -> Dictionary:
	var explored:Array=[]
	for c in maze.seen:explored.append([c.x,c.y])
	return {"chapter":maze.chapter,"position":[player.position.x,player.position.z],"activated":activated.duplicate(),"collected":collected.duplicate(),"elapsed":elapsed,"seen":explored,"hints":hints_used,"yaw":yaw,"pitch":pitch}
func restore(data: Dictionary) -> void:
	# Only restore valid, walkable positions and bounded progress values.
	var p=data.get("position",[])
	if p is Array and p.size()==2 and (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int):
		var v:=Vector3(float(p[0]),.1,float(p[1]))
		if v.is_finite() and maze.walkable(maze.cell(v)):
			# Snap to tile center if saved within the collision margin of a wall.
			var c:Vector2i=maze.cell(v);var center:Vector3=maze.world(c)
			if absf(v.x-center.x)>1.55 or absf(v.z-center.z)>1.55:v=center+Vector3(0,.1,0)
			player.position=v
	for i in data.get("activated",[]):
		if (i is int or i is float) and int(i)>=0 and int(i)<3 and int(i) not in activated:activated.append(int(i))
	for i in data.get("collected",[]):
		if (i is int or i is float) and int(i)>=0 and int(i)<mote_nodes.size() and int(i) not in collected:collected.append(int(i));mote_nodes[int(i)].visible=false
	elapsed=clampf(float(data.get("elapsed",0)),0,99999);hints_used=clampi(int(data.get("hints",0)),0,9999)
	yaw=float(data.get("yaw",0));pitch=clampf(float(data.get("pitch",.4)),.35,.95)
	if not is_finite(yaw):yaw=0
	for a in data.get("seen",[]):
		if a is Array and a.size()==2:
			var c:=Vector2i(int(a[0]),int(a[1]))
			if c.x>=0 and c.y>=0 and c.x<maze.width and c.y<maze.width:maze.seen[c]=true
func tone(name: String) -> void:
	if muted:return
	chime_audio.stream=load("res://assets/audio/"+name+".wav");chime_audio.play()
func haptic(ms: int) -> void:
	if OS.has_feature("android") and not muted:Input.vibrate_handheld(ms)
func flat_distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()
func material(hex: String,emission: bool=false) -> StandardMaterial3D:
	var key:=hex+str(emission)
	if materials.has(key):return materials[key]
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(hex);mat.roughness=.83
	if emission:mat.emission_enabled=true;mat.emission=Color(hex);mat.emission_energy_multiplier=1.6;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	materials[key]=mat;return mat
func mesh(shape: Mesh,mat: Material,parent: Node3D,pos: Vector3) -> MeshInstance3D:
	var m:=MeshInstance3D.new();m.mesh=shape;m.material_override=mat;m.position=pos;parent.add_child(m);return m
func box(size: Vector3,pos: Vector3,hex: String,parent: Node3D) -> MeshInstance3D:
	var m:=BoxMesh.new();m.size=size;return mesh(m,material(hex),parent,pos)
func collider(size: Vector3,pos: Vector3) -> void:
	var body:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;collision.shape=shape
	body.position=pos;body.add_child(collision);geo.add_child(body)
func model(name: String,parent: Node3D,pos: Vector3) -> Node3D:
	if not scenes.has(name):scenes[name]=load(MODEL_PATH+name+".glb")
	var node:Node3D=scenes[name].instantiate();node.position=pos;parent.add_child(node);return node
func ring(radius: float,thickness: float,pos: Vector3,color: Color,parent: Node3D) -> MeshInstance3D:
	var m:=TorusMesh.new();m.inner_radius=radius-thickness;m.outer_radius=radius+thickness;m.rings=32;m.ring_segments=6
	return mesh(m,material(color.to_html(false),true),parent,pos)
func portal_material() -> ShaderMaterial:
	var s:=Shader.new()
	s.code="""shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
void fragment(){vec2 p=UV*2.0-1.0;float r=length(p);float edge=smoothstep(1.02,0.80,r);float waves=sin(r*23.0-TIME*2.3+sin(atan(p.y,p.x)*4.0+TIME)*.65)*.5+.5;vec3 a=vec3(.12,.49,.49);vec3 b=vec3(.96,.84,.50);ALBEDO=mix(a,b,pow(waves,5.0)*.65+pow(r,3.0)*.35);EMISSION=ALBEDO*.7;ALPHA=edge*.8;}"""
	var mat:=ShaderMaterial.new();mat.shader=s;return mat
func _batch_static() -> void:
	var groups:Dictionary={}
	for node in geo.find_children("*","MeshInstance3D",true,false):
		var key:=str(node.mesh.get_instance_id())+str(node.material_override.get_instance_id() if node.material_override else 0)
		if not groups.has(key):groups[key]=[]
		groups[key].append(node)
	for group in groups.values():
		if group.size()<2:continue
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=group[0].mesh;multi.instance_count=group.size()
		var renderer:=MultiMeshInstance3D.new();renderer.multimesh=multi;renderer.material_override=group[0].material_override;geo.add_child(renderer)
		for i in group.size():multi.set_instance_transform(i,group[i].global_transform);group[i].visible=false
func _make_fireflies(rng: RandomNumberGenerator) -> void:
	firefly_base.clear()
	var m:=SphereMesh.new();m.radius=1;m.height=2;m.radial_segments=6;m.rings=3
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=m;multi.instance_count=70
	fireflies=MultiMeshInstance3D.new();fireflies.multimesh=multi;fireflies.material_override=material("dbe6a3",true);dynamic.add_child(fireflies)
	for i in 70:firefly_base.append(Vector3(rng.randf_range(-maze.width*2,maze.width*2),rng.randf_range(.4,3.5),rng.randf_range(-maze.width*2,maze.width*2)))
func burst(pos: Vector3,color: Color,count: int=15) -> void:
	for i in count:
		var sphere:=SphereMesh.new();sphere.radius=.045;sphere.height=.09;sphere.radial_segments=6;sphere.rings=3
		var node:=mesh(sphere,material(color.to_html(false),true),dynamic,pos)
		fx.append({"node":node,"velocity":Vector3(randf_range(-2,2),randf_range(.5,2.8),randf_range(-2,2)),"life":1.0})
func update_fx(dt: float) -> void:
	for i in range(fx.size()-1,-1,-1):
		var f:Dictionary=fx[i];f.life-=dt;f.velocity.y-=dt*2;f.node.position+=f.velocity*dt;f.node.scale=Vector3.ONE*maxf(.01,f.life)
		if f.life<=0:f.node.queue_free();fx.remove_at(i)

func apply_wall_material(node: Node3D) -> void:
	for part in node.find_children("*","MeshInstance3D",true,false):
		var base:StandardMaterial3D=part.get_active_material(0)
		if not base:continue
		var key:=str(base.get_instance_id())
		if not wall_materials.has(key):
			var shader:=Shader.new()
			shader.code="""shader_type spatial;
uniform vec4 stone:source_color=vec4(.3,.4,.4,1.0);
uniform vec3 glow:source_color=vec3(0.0);
uniform vec3 hero;uniform vec3 eye;uniform bool cutaway=false;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 ALBEDO=stone.rgb;ROUGHNESS=.87;EMISSION=glow;
 if(cutaway){vec2 axis=eye.xz-hero.xz;float len=length(axis);vec2 dir=axis/max(len,.01);float along=dot(wp.xz-hero.xz,dir);float sideways=length((wp.xz-hero.xz)-dir*along);float fade=(1.0-smoothstep(1.45,1.75,sideways))*smoothstep(-.3,.5,along)*(1.0-smoothstep(len-.2,len+.8,along));float noise=fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)))*43758.5453);if(noise<fade)discard;}
}"""
			var mat:=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("stone",base.albedo_color)
			mat.set_shader_parameter("glow",base.emission if base.emission_enabled else Color.BLACK)
			wall_materials[key]=mat
		part.material_override=wall_materials[key]

func add_beam(i: int) -> void:
	var beam_mesh:=CylinderMesh.new();beam_mesh.top_radius=.055;beam_mesh.bottom_radius=.22;beam_mesh.height=12
	var beam_mat:=StandardMaterial3D.new();beam_mat.albedo_color=Color(.5,.95,.85,.28);beam_mat.emission_enabled=true;beam_mat.emission=Color("71cabd");beam_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;beam_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh(beam_mesh,beam_mat,dynamic,light_nodes[i].position+Vector3(0,4.25,0))

func _exit_tree() -> void:
	if step_audio:step_audio.stop()
	if chime_audio:chime_audio.stop()
