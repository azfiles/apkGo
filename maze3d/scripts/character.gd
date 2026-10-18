extends RefCounted
## A connected, rigid cartoon rig. Poses use velocity, not input, so blocked
## movement never plays a run. Expressions are separate geometry in the GLB.
const JOINTS := ["Body","Torso","Head","ArmL","ArmR","ElbowL","ElbowR","LegL","LegR","KneeL","KneeR","EarL","EarR","Satchel"]
const EXPRESSIONS := ["Smile","Joy","Surprise","Focus"]
var joints: Dictionary = {}
var base: Dictionary = {}
var faces: Dictionary = {}
var eyes: Array[Node3D] = []
var brows: Array[Node3D] = []
var expression := "Smile"
var mood := ""
var mood_time := 0.0
var stride_weight := 0.0
var air_weight := 0.0
var landing := 0.0
var grounded_before := true

func bind(avatar: Node3D) -> void:
	joints.clear();base.clear();faces.clear();eyes.clear();brows.clear()
	stride_weight=0;air_weight=0;landing=0;mood="";mood_time=0;grounded_before=true
	for name in JOINTS:
		var node:Node3D=avatar.find_child(name,true,false)
		if node:joints[name]=node;base[name]=node.position
	for name in EXPRESSIONS:
		var node:Node3D=avatar.find_child("Face"+name,true,false)
		if node:faces[name]=node
	for side in ["L","R"]:
		var eye:Node3D=avatar.find_child("Eye"+side,true,false)
		var brow:Node3D=avatar.find_child("Brow"+side,true,false)
		if eye:eyes.append(eye)
		if brow:brows.append(brow)
	show_face("Smile",0)

func emote(name: String, seconds: float=1.4) -> void:
	if name not in EXPRESSIONS:return
	mood=name;mood_time=seconds
	show_face(name,0)

func show_face(name: String, blink: float) -> void:
	expression=name
	for key in faces:faces[key].visible=key==name
	for eye in eyes:
		eye.visible=name!="Joy"
		eye.scale.y=lerpf(1.0,.08,blink)*(.80 if name=="Focus" else 1.0)
	for i in brows.size():
		brows[i].rotation.z=(.16 if i==0 else -.16) if name=="Focus" else 0.0
		brows[i].position.y=.112 if name=="Surprise" else .095

func pose(name: String, target: Vector3, blend: float) -> void:
	if joints.has(name):joints[name].rotation=joints[name].rotation.lerp(target,blend)

func step(dt: float, velocity: Vector3, grounded: bool, phase: float, clock: float, preview: bool=false) -> void:
	var blend:=1.0-exp(-dt*14)
	var speed:=Vector2(velocity.x,velocity.z).length() if not preview else 0.0
	var running:=clampf((speed-3.0)/2.5,0,1)
	stride_weight=lerpf(stride_weight,clampf(speed/2.0,0,1),blend)
	air_weight=lerpf(air_weight,0.0 if grounded or preview else 1.0,blend)
	if grounded and not grounded_before:landing=1.0
	grounded_before=grounded
	landing=move_toward(landing,0,dt*5)
	var wave:=sin(phase)*stride_weight
	var rising:=clampf((velocity.y+2.0)/7.0,0,1)
	var amplitude:=lerpf(.46,.78,running)
	for i in 2:
		var side:="L" if i==0 else "R"
		var sign_:=-1.0 if i==0 else 1.0
		var gait:=wave*sign_
		var hip:=lerpf(gait*amplitude,lerpf(-.10,-.38,rising)+sign_*.09,air_weight)-landing*.18
		var knee:=lerpf(maxf(0,-gait)*lerpf(.62,1.05,running),lerpf(.25,.82,rising),air_weight)+landing*.40
		var arm:=lerpf(-gait*amplitude*.85,lerpf(-.20,-.85,rising),air_weight)
		var elbow:=lerpf(-.12-running*.48-maxf(0,gait)*.18,-.45,air_weight)
		pose("Leg"+side,Vector3(hip,0,0),blend)
		pose("Knee"+side,Vector3(knee,0,0),blend)
		pose("Arm"+side,Vector3(arm,0,sign_*(.08+air_weight*.20)),blend)
		pose("Elbow"+side,Vector3(elbow,0,0),blend)
		pose("Ear"+side,Vector3(sin(phase-.4)*stride_weight*.06+air_weight*.12,0,sign_*(sin(clock*1.8)*.02+wave*.07)),blend)
	pose("Torso",Vector3(stride_weight*(.04+running*.08)+air_weight*.03+landing*.10,0,-wave*.025),blend)
	pose("Head",Vector3(-stride_weight*.025-air_weight*.04,0,sin(clock*.8)*.018-wave*.012),blend)
	pose("Satchel",Vector3(sin(phase-.65)*stride_weight*.12+air_weight*.12,0,-wave*.055),blend)
	if joints.has("Body"):
		var bob:=lerpf(sin(clock*2)*.008,absf(cos(phase))*.035,stride_weight)*(1-air_weight)
		joints.Body.position=base.Body+Vector3(0,bob-landing*.035,0)
	mood_time=maxf(0,mood_time-dt)
	var face:="Smile"
	if mood_time>0:face=mood
	elif air_weight>.4:face="Surprise"
	elif running>.3 and stride_weight>.3:face="Focus"
	elif preview and fmod(clock,10.0)>8.5:face="Joy"
	var blink_phase:=fmod(clock+1.7,3.9)
	var blink:=sin(clampf(blink_phase/.18,0,1)*PI) if blink_phase<.18 else 0.0
	show_face(face,blink)
