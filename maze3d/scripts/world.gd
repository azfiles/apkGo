extends Node3D
signal picked
signal lit
signal escaped
signal message(text: String)
const Maze = preload("res://scripts/maze.gd")
const Character = preload("res://scripts/character.gd")
const MODEL_PATH := "res://assets/models/"
const GRAVITY := 18.0
const JUMP_SPEED := 6.8
const COYOTE_TIME := .10
const JUMP_BUFFER := .12
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
var character = Character.new()
var celebrating := false
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
var jump_buffer := 0.0
var coyote_time := 0.0
var jumps := 0
var rescues := 0
var safe_position := Vector3.ZERO
var contact_shadow: MeshInstance3D
var challenge_tip := ""
var preview_yaw := -.5
var preview_pitch := .18
var preview_distance := 6.0
var preview_auto := false
var preview_stage: Node3D

func _ready() -> void:
	var environment := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color=Color("b9dfe0")
	env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("e1f0ea");env.ambient_light_energy=.25
	env.ambient_light_sky_contribution=0.0
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.fog_enabled=true;env.fog_light_color=Color("c7e2d7");env.fog_density=.001
	environment.environment=env;add_child(environment)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-44,-38,0)
	sun.light_color=Color("fff0d2");sun.light_energy=.25
	sun.shadow_enabled=true;sun.directional_shadow_max_distance=65
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias=.15;sun.shadow_normal_bias=3.0
	add_child(sun)
	var rim:=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-25,150,0);rim.light_color=Color("c7e7ed");rim.light_energy=.12;add_child(rim)
	camera=Camera3D.new();camera.fov=52;camera.near=.15;camera.far=180;camera.current=true;add_child(camera)
	step_audio=AudioStreamPlayer.new();step_audio.stream=load("res://assets/audio/step.wav");step_audio.volume_db=-14;add_child(step_audio)
	chime_audio=AudioStreamPlayer.new();chime_audio.volume_db=-7;add_child(chime_audio)
	for i in 3:
		var lamp:=OmniLight3D.new();lamp.light_color=Color("ffd38c");lamp.omni_range=5;lamp.light_energy=.12
		add_child(lamp);lamp_lights.append(lamp)

func build(chapter: int, saved: Dictionary = {}) -> void:
	active=false;camera_ready=false
	input_move=Vector2.ZERO;sprint=false;energy=1.0;elapsed=0.0;clock=0.0
	activated.clear();collected.clear();light_nodes.clear();mote_nodes.clear();joints.clear();joint_base.clear();fx.clear();lantern_positions.clear()
	hint_time=0;hint_cooldown=0;hints_used=0;near_beacon=-1;near_gate=false
	jump_buffer=0;coyote_time=0;jumps=0;rescues=0;challenge_tip="";celebrating=false;walking_phase=0;reset_preview()
	if geo:remove_child(geo);geo.queue_free()
	if dynamic:remove_child(dynamic);dynamic.queue_free()
	geo=Node3D.new();add_child(geo)
	dynamic=Node3D.new();add_child(dynamic)
	maze.build(chapter)
	var rng:=RandomNumberGenerator.new();rng.seed=591+chapter
	var size:float=maze.width*Maze.TILE
	# Individual floor colliders leave real openings beneath broken bridges.
	box(Vector3(size+3,.35,size+3),Vector3(0,-4,0),"82b9b5",geo)
	# One shared mesh per material; _batch_static consolidates into GPU instances.
	var tile_mesh:=BoxMesh.new();tile_mesh.size=Vector3(3.96,.10,3.96)
	var mark_mesh:=BoxMesh.new();mark_mesh.size=Vector3(.40,.012,.055)
	var mark_mat:=material("aebfa1")
	var tile_mats: Array = [material("d9dfbe"),material("e0e3c7"),material("d4dbb9"),material("e5e5c9")]
	for z in maze.width:
		for x in maze.width:
			var cell:=Vector2i(x,z)
			var p:Vector3=maze.world(cell)
			if maze.walkable(cell):
				var challenge:Dictionary=maze.challenge_at(cell)
				if challenge.get("kind","")=="gap":
					build_gap(p,challenge)
					continue
				var tile:=MeshInstance3D.new();tile.mesh=tile_mesh;tile.material_override=tile_mats[rng.randi_range(0,3)];tile.position=p-Vector3(0,.07,0);geo.add_child(tile)
				collider(Vector3(4,.6,4),p-Vector3(0,.32,0))
				if not challenge.is_empty():build_hurdle(p,challenge)
				for k in 3:
					var mark:=mesh(mark_mesh,mark_mat,geo,p+Vector3(rng.randf_range(-1.6,1.6),-.008,rng.randf_range(-1.6,1.6)));mark.rotation.y=PI/2 if k%2==0 else 0.0
				if rng.randf()<.34 and challenge.is_empty():
					var grass:=model("grass",geo,p+Vector3(1.56,.02,1.54));grass.rotation.y=rng.randf()*TAU
				if rng.randf()<.12 and cell!=maze.start and challenge.is_empty():
					var pos:=p+Vector3(1.42,0,1.42)
					var lantern:=model("lantern",geo,pos);apply_wall_material(lantern);lantern_positions.append(pos+Vector3(0,1.7,0))
			else:
				var wall:=model("wall_"+str(rng.randi_range(0,2)),geo,p)
				apply_wall_material(wall)
				collider(Vector3(4,2.35,4),p+Vector3(0,1.15,0))
				if (x==0 or z==0 or x==maze.width-1 or z==maze.width-1) and (x+z)%3==0:
					var tree:=model("tree_"+str(chapter%2),geo,p+Vector3(0,2.25,0));tree.rotation.y=rng.randf()*TAU;tree.scale=Vector3.ONE*rng.randf_range(.85,1.35)
					apply_wall_material(tree)
	# Soft hills and rounded cloud banks continue the picture-book silhouettes.
	var mountain:=SphereMesh.new();mountain.radius=1;mountain.height=2;mountain.radial_segments=16;mountain.rings=8
	for i in 16:
		var angle:=float(i)*TAU/16
		var peak:=mesh(mountain,material(["94c8b7","a9d1b4","b7d8c0"][i%3]),geo,Vector3(cos(angle)*76,-8,sin(angle)*76))
		peak.scale=Vector3(rng.randf_range(13,23),rng.randf_range(12,20),rng.randf_range(14,22))
		peak.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if i%2==0:
			var cloud:=model("cloud",geo,Vector3(cos(angle)*65,16+(i%3)*3,sin(angle)*65))
			cloud.scale=Vector3.ONE*3;cloud.rotation.y=-angle
	# Start plaza: inset mosaic, four welcoming lamps, and a tree on the edge.
	var start_p:Vector3=maze.world(maze.start)
	for ofs in [Vector3(-1.5,0,-1.5),Vector3(1.5,0,-1.5)]:
		var lantern:=model("lantern",geo,start_p+ofs);apply_wall_material(lantern);lantern_positions.append(start_p+ofs+Vector3(0,1.7,0))
	ring(1.25,.035,start_p+Vector3(0,.03,0),Color("d5bd83"),geo)
	for i in 3:
		var p:Vector3=maze.world(maze.beacons[i])+Vector3(1.05,0,-1.05)
		model("beacon",geo,p)
		collider(Vector3(.95,1.1,.95),p+Vector3(0,.55,0))
		ring(.95,.035,p+Vector3(0,.035,0),Color("b5c6ae"),geo)
		var orb:=model("crystal",dynamic,p+Vector3(0,1.85,0))
		light_nodes.append(orb)
	for i in maze.motes.size():
		var p:Vector3=maze.world(maze.motes[i])+Vector3(0,maze.mote_height(i),0)
		var orb:=model("star",dynamic,p)
		mote_nodes.append(orb)
		if i in maze.elevated_motes:
			ring(.55,.025,maze.world(maze.motes[i])+Vector3(0,.02,0),Color("ffdc8f"),geo)
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
	avatar=model("brown",player,Vector3.ZERO)
	avatar.rotation.y=PI
	character.bind(avatar);joints=character.joints;joint_base=character.base
	preview_stage=Node3D.new();dynamic.add_child(preview_stage)
	var podium:=CylinderMesh.new();podium.top_radius=.92;podium.bottom_radius=1.02;podium.height=.12;podium.radial_segments=64
	mesh(podium,material("f6e5b9"),preview_stage,Vector3(0,-.07,0))
	ring(.91,.025,Vector3(0,-.005,0),Color("e8bf59"),preview_stage)
	# Gentle contact shadow keeps the character grounded even on low quality.
	var shadow_mat:=StandardMaterial3D.new();shadow_mat.albedo_color=Color(0.02,.08,.09,.24);shadow_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;shadow_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var shadow:=CylinderMesh.new();shadow.top_radius=.36;shadow.bottom_radius=.36;shadow.height=.008
	contact_shadow=mesh(shadow,shadow_mat,dynamic,start_p+Vector3(0,.008,0))
	yaw=0;pitch=.40
	safe_position=start_p+Vector3(0,.08,0)
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
		mote_nodes[i].position.y=maze.mote_height(i)+sin(clock*2.3+i)*.10
		mote_nodes[i].rotation=Vector3(0,clock*.65+i*.7,sin(clock*1.8+i)*.10)
	preview_stage.visible=title_mode
	if title_mode:preview_stage.position=maze.world(maze.start)+Vector3(4,0,-4)
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
		jump_buffer=maxf(0,jump_buffer-dt)
		coyote_time=COYOTE_TIME if player.is_on_floor() else maxf(0,coyote_time-dt)
		if jump_buffer>0 and coyote_time>0:
			player.velocity.y=JUMP_SPEED;jump_buffer=0;coyote_time=0;jumps+=1
			tone("jump");haptic(15)
			burst(player.position+Vector3(0,.08,0),Color("d1e7d4"),7)
		var was_grounded:=player.is_on_floor()
		player.velocity.y-=GRAVITY*dt
		player.move_and_slide()
		if player.position.y< -2.5:rescue()
		if not was_grounded and player.is_on_floor():
			burst(player.position+Vector3(0,.06,0),Color("d1e7d4"),6)
		var traveled:=Vector2(player.position.x-last_position.x,player.position.z-last_position.z).length()
		moving=traveled>.003
		if player.is_on_floor():walking_phase+=traveled*3.3
		if moving:
			var facing:=Vector2(player.velocity.x,player.velocity.z)
			if facing.length()>.05:avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(facing.x,facing.y),minf(1,dt*12))
			foot_time+=traveled if player.is_on_floor() else 0.0
			if foot_time>.9:
				foot_time=0
				if not muted:step_audio.pitch_scale=randf_range(.9,1.15);step_audio.play()
		var c:Vector2i=maze.cell(player.position)
		if player.is_on_floor() and absf(player.position.y)<.1 and maze.safe_cell(c) and flat_distance(player.position,maze.world(c))<.7:
			safe_position=maze.world(c)+Vector3(0,.08,0)
		maze.reveal(c)
		near_beacon=-1;near_gate=false
		for i in light_nodes.size():
			if i not in activated and player.is_on_floor() and flat_distance(player.position,light_nodes[i].position)<1.65:near_beacon=i
		for i in mote_nodes.size():
			if i not in collected and (player.position+Vector3(0,.85,0)).distance_to(mote_nodes[i].position)<.72:
				collected.append(i);mote_nodes[i].visible=false;burst(mote_nodes[i].position,Color("ffdc8f"));tone("mote");character.emote("Joy");picked.emit()
		near_gate=player.is_on_floor() and flat_distance(player.position,gate.position)<1.8
		update_challenge_tip()
		last_position=player.position
	else:
		# Pausing in flight preserves vertical speed, without advancing physics.
		moving=false
	contact_shadow.position=Vector3(player.position.x,.008,player.position.z)
	contact_shadow.visible=player.position.y>=-.05 and maze.challenge_at(maze.cell(player.position)).get("kind","")!="gap"
	contact_shadow.scale=Vector3.ONE*clampf(1-player.position.y*.22,.5,1)
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
	if not active and not title_mode and not celebrating:return
	var velocity:=player.velocity if active and moving else Vector3(0,player.velocity.y,0)
	character.step(dt,velocity,player.is_on_floor(),walking_phase,clock,title_mode or celebrating)

func update_camera(dt: float) -> void:
	if title_mode:
		var p:Vector3=maze.world(maze.start)+Vector3(4,0,-4)
		player.position=p;avatar.rotation.y=-.5
		if preview_auto:preview_yaw=wrapf(preview_yaw+dt*.24,-PI,PI)
		var focus:=p+Vector3(0,1.1,0)
		var right:=Vector3(cos(preview_yaw),0,-sin(preview_yaw))
		var offset:=Vector3(sin(preview_yaw)*cos(preview_pitch),sin(preview_pitch),cos(preview_yaw)*cos(preview_pitch))*preview_distance
		var framing:=right*preview_distance*.24
		camera.position=focus+offset-framing;camera.look_at(focus-framing);camera.fov=42
		for mat in wall_materials.values():
			mat.set_shader_parameter("hero",p);mat.set_shader_parameter("eye",camera.position);mat.set_shader_parameter("cutaway",true)
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
		character.emote("Joy",2.0)
		tone("beacon");haptic(50);lit.emit();update_gate()
		message.emit("三座灯塔已点亮 · 出口苏醒了" if activated.size()==3 else "灯塔已点亮  %d / 3"%activated.size())
	elif near_gate:
		if activated.size()==3:
			active=false;celebrating=true;character.emote("Joy",3600);tone("win");haptic(90);escaped.emit()
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
	message.emit("跟随金色光迹 · 石栏与断桥需要跳跃")

func request_jump() -> bool:
	if not active or title_mode:return false
	jump_buffer=JUMP_BUFFER
	return true

func rescue() -> void:
	player.position=safe_position;player.velocity=Vector3.ZERO
	input_move=Vector2.ZERO;jump_buffer=0;coyote_time=0;rescues+=1
	last_position=player.position;camera_ready=false
	character.emote("Surprise",1.0)
	message.emit("已回到安全落脚点 · 灯塔和星星进度保留")

func update_challenge_tip() -> void:
	challenge_tip=""
	for challenge in maze.challenges:
		if flat_distance(player.position,maze.world(challenge.cell))<4.6:
			challenge_tip="断桥 · 靠近金色边线起跳" if challenge.kind=="gap" else "矮石栏 · 移动时跳跃越过"
			return
	for i in maze.elevated_motes:
		if i not in collected and flat_distance(player.position,mote_nodes[i].position)<2.6:
			challenge_tip="高处星星 · 站在标记内跳起收集";return

func build_hurdle(p: Vector3,challenge: Dictionary) -> void:
	var along_x:bool=challenge.axis.x!=0
	var height:float=challenge.height
	var size:=Vector3(.65,height,4) if along_x else Vector3(4,height,.65)
	var rail:=model("hurdle",geo,p)
	rail.scale.y=height/.65;rail.rotation.y=PI/2 if along_x else 0.0
	collider(size,p+Vector3(0,height/2-.02,0))
	jump_marks(p,challenge)

func build_gap(p: Vector3,challenge: Dictionary) -> void:
	var axis:=Vector3(challenge.axis.x,0,challenge.axis.y)
	var span:float=challenge.span
	var length:float=(Maze.TILE-span)/2
	var size:=Vector3(length,.6,4) if challenge.axis.x!=0 else Vector3(4,.6,length)
	for side in [-1,1]:
		var center:Vector3=p+axis*side*(Maze.TILE+span)/4-Vector3(0,.32,0)
		box(size,center,"d8dfbf",geo);collider(size,center)
	var water_size:=Vector3(span,.06,3.98) if challenge.axis.x!=0 else Vector3(3.98,.06,span)
	box(water_size,p-Vector3(0,1.5,0),"69bfc9",geo)
	jump_marks(p,challenge)

func jump_marks(p: Vector3,challenge: Dictionary) -> void:
	var axis:=Vector3(challenge.axis.x,0,challenge.axis.y)
	var side:=Vector3(-axis.z,0,axis.x)
	var length:float=challenge.span/2+.38 if challenge.kind=="gap" else .98
	for sign_ in [-1,1]:
		var center:Vector3=p+axis*sign_*length+Vector3(0,.025,0)
		var stripe:=Vector3(.07,.025,3.7) if challenge.axis.x!=0 else Vector3(3.7,.025,.07)
		box(stripe,center,"e9ad44",geo)
		for k in [-1,1]:
			var arrow:=box(Vector3(.045,.025,.30),center+axis*sign_*.22+side*k*.12,"ead39b",geo)
			arrow.rotation.y=atan2(axis.x,axis.z)+k*sign_*PI/4

func reset_preview() -> void:
	preview_yaw=-.5;preview_pitch=.18;preview_distance=6.0;preview_auto=false
func orbit_preview(delta: Vector2) -> void:
	preview_auto=false
	preview_yaw=wrapf(preview_yaw-delta.x*.008,-PI,PI)
	preview_pitch=clampf(preview_pitch+delta.y*.006,-.06,1.25)
func zoom_preview(factor: float) -> void:
	preview_distance=clampf(preview_distance*factor,3.8,8.0)

func reset_camera() -> void:
	yaw=wrapf(PI-avatar.rotation.y,-PI,PI);pitch=.40
func orbit(delta: Vector2) -> void:
	yaw+=delta.x*.005;pitch=clampf(pitch+delta.y*.003,.35,.95)
func set_quality(high: bool) -> void:
	high_quality=high;sun.shadow_enabled=high
	get_viewport().msaa_3d=Viewport.MSAA_2X if high else Viewport.MSAA_DISABLED
	if fireflies:fireflies.visible=high
func snapshot() -> Dictionary:
	var explored:Array=[]
	for c in maze.seen:explored.append([c.x,c.y])
	# Save a supported landing point, never an airborne position above a gap.
	var p:=safe_position
	if player.is_on_floor() and maze.safe_cell(maze.cell(player.position)):p=player.position
	return {"chapter":maze.chapter,"position":[p.x,p.z],"activated":activated.duplicate(),"collected":collected.duplicate(),"elapsed":elapsed,"seen":explored,"hints":hints_used,"yaw":yaw,"pitch":pitch,"jumps":jumps,"rescues":rescues}
func restore(data: Dictionary) -> void:
	# Only restore valid, walkable positions and bounded progress values.
	var p=data.get("position",[])
	if p is Array and p.size()==2 and (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int):
		var v:=Vector3(float(p[0]),.1,float(p[1]))
		if v.is_finite() and maze.walkable(maze.cell(v)):
			# Snap to tile center if saved within the collision margin of a wall.
			var c:Vector2i=maze.cell(v);var center:Vector3=maze.world(c)
			if absf(v.x-center.x)>1.55 or absf(v.z-center.z)>1.55:v=center+Vector3(0,.1,0)
			if not maze.safe_cell(c):
				var route:Array=maze.path(c,maze.start)
				v=maze.world(route[0] if not route.is_empty() else maze.start)+Vector3(0,.1,0)
			player.position=v;safe_position=v
	for i in data.get("activated",[]):
		if (i is int or i is float) and int(i)>=0 and int(i)<3 and int(i) not in activated:activated.append(int(i))
	for i in data.get("collected",[]):
		if (i is int or i is float) and int(i)>=0 and int(i)<mote_nodes.size() and int(i) not in collected:collected.append(int(i));mote_nodes[int(i)].visible=false
	elapsed=clampf(float(data.get("elapsed",0)),0,99999);hints_used=clampi(int(data.get("hints",0)),0,9999)
	jumps=clampi(int(data.get("jumps",0)),0,999999);rescues=clampi(int(data.get("rescues",0)),0,999999)
	yaw=float(data.get("yaw",0));pitch=clampf(float(data.get("pitch",.4)),.35,.95)
	if not is_finite(yaw):yaw=0
	for a in data.get("seen",[]):
		if a is Array and a.size()==2:
			var c:=Vector2i(int(a[0]),int(a[1]))
			if c.x>=0 and c.y>=0 and c.x<maze.width and c.y<maze.width:maze.seen[c]=true
	player.velocity=Vector3.ZERO;jump_buffer=0;coyote_time=0;last_position=player.position
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
