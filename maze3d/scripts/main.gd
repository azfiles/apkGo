extends Node3D
const World = preload("res://scripts/world.gd")
const Interface = preload("res://scripts/interface.gd")
var world
var ui
var page := "home"
var chapter := 0
var toast := ""
var toast_timer := 0.0
var session: Dictionary = {}
var records: Dictionary = {}
var settings := {"sound":true,"quality":true,"sensitivity":1.0}
var move_pointer := -99
var look_pointer := -99
var sprint_pointer := -99
var joystick := Vector2.ZERO
var joystick_origin := Vector2(155,565)
var mouse_look := false
var preview_pointers: Dictionary = {}
var tutorial_time := 18.0
var autosave_time := 0.0
var ambiance: AudioStreamPlayer
var finish_stars := 1
var saving := false
var loading := false
const SAVE_PATH := "user://ruins-v2.json"

func _ready() -> void:
	get_tree().auto_accept_quit=false
	get_tree().quit_on_go_back=false
	Engine.max_fps=60
	load_progress()
	world=World.new();add_child(world)
	world.picked.connect(func():show_toast("星星 +1  ·  %d / 12"%world.collected.size(),1.4))
	world.lit.connect(save_progress)
	world.escaped.connect(finish)
	world.message.connect(show_toast)
	world.muted=not settings.sound
	world.high_quality=settings.quality
	world.build(chapter)
	var canvas:=CanvasLayer.new();add_child(canvas)
	ui=Interface.new();ui.game=self;canvas.add_child(ui);ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambiance=AudioStreamPlayer.new();ambiance.stream=load("res://assets/audio/ambience.wav");ambiance.volume_db=-22;add_child(ambiance)
	ambiance.finished.connect(func():if settings.sound:ambiance.play())
	if settings.sound:ambiance.play()
	print("PIPI_PAGE home")

func _process(dt: float) -> void:
	toast_timer=maxf(0,toast_timer-dt)
	if page=="play":
		tutorial_time=maxf(0,tutorial_time-dt)
		var v:=joystick
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):v.y-=1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):v.y+=1
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):v.x-=1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):v.x+=1
		world.input_move=v.limit_length()
		world.sprint=sprint_pointer!=-99 or Input.is_physical_key_pressed(KEY_SHIFT)
		if Input.is_physical_key_pressed(KEY_Q):world.yaw-=dt*1.6
		if Input.is_physical_key_pressed(KEY_R):world.yaw+=dt*1.6
		autosave_time+=dt
		if autosave_time>8:autosave_time=0;save_progress()
	if ui:ui.queue_redraw()

func start_game(resume: bool=false) -> void:
	if loading:return
	loading=true
	var data:Dictionary=session if resume else {}
	if resume:chapter=clampi(int(data.get("chapter",chapter)),0,2)
	world.build(chapter,data);world.title_mode=false;world.active=true;page="play"
	reset_input();tutorial_time=18 if not resume else 5;show_toast("点亮三座灯塔 · 跳过障碍，收集高处星星",4)
	save_progress();loading=false;print("PIPI_PAGE play")

func action(id: String) -> void:
	match id:
		"start":start_game(false)
		"continue":start_game(true)
		"pause":pause_game()
		"resume":page="play";world.active=true;reset_input()
		"map":page="map";world.active=false;reset_input()
		"close_map":page="play";world.active=true
		"home":
			if page!="win":save_progress()
			page="home";world.active=false;world.title_mode=true;world.reset_preview();reset_input()
		"retry":page="confirm";world.active=false;reset_input()
		"confirm_retry":start_game(false)
		"cancel_retry":page="pause"
		"next":chapter=(chapter+1)%3;start_game(false)
		"hint":world.hint()
		"interact":world.interact()
		"jump":
			if page=="play":world.request_jump()
		"camera":world.reset_camera();show_toast("视角已回正",1)
		"preview_reset":world.reset_preview()
		"preview_auto":world.preview_auto=not world.preview_auto
		"preview_expression":
			var expressions=world.character.EXPRESSIONS
			var next: int=(expressions.find(world.character.expression)+1)%expressions.size()
			world.character.emote(expressions[next],4.0)
		"preview_in":world.zoom_preview(.85)
		"preview_out":world.zoom_preview(1.0/.85)
		"sound":
			settings.sound=not settings.sound;world.muted=not settings.sound
			if settings.sound:ambiance.play()
			else:ambiance.stop()
			save_progress()
		"quality":settings.quality=not settings.quality;world.set_quality(settings.quality);save_progress()
		"sensitivity":settings.sensitivity=1.5 if settings.sensitivity==1.0 else (0.7 if settings.sensitivity==1.5 else 1.0);save_progress()
		"chapter0","chapter1","chapter2":
			chapter=int(id.right(1));world.build(chapter);world.title_mode=true;reset_input()

	print("PIPI_PAGE ",page)

func pause_game() -> void:
	if page=="play" or page=="map":save_progress();page="pause";world.active=false;reset_input()
	elif page=="pause":action("resume")
	print("PIPI_PAGE ",page)

func finish() -> void:
	page="win";world.active=false;reset_input();finish_stars=1
	if world.collected.size()>=6:finish_stars=2
	if world.collected.size()==12:finish_stars=3
	var key:=str(chapter)
	var record:Dictionary=records.get(key,{})
	record["stars"]=maxi(finish_stars,int(record.get("stars",0)))
	record["motes"]=maxi(world.collected.size(),int(record.get("motes",0)))
	record["seconds"]=minf(world.elapsed,float(record.get("seconds",999999)))
	records[key]=record;session={};save_progress();print("PIPI_PAGE win")

func reset_input() -> void:
	move_pointer=-99;look_pointer=-99;sprint_pointer=-99;joystick=Vector2.ZERO;mouse_look=false
	preview_pointers.clear()
	if world:world.input_move=Vector2.ZERO;world.sprint=false;world.jump_buffer=0

func _input(event: InputEvent) -> void:
	if not ui:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE or event.keycode==KEY_P:
			if page=="map":action("close_map")
			elif page=="confirm":action("cancel_retry")
			else:pause_game()
		elif event.keycode==KEY_ENTER or event.keycode==KEY_SPACE:
			if page=="home":action("continue" if not session.is_empty() else "start")
			elif page=="play" and event.keycode==KEY_SPACE:world.request_jump()
		elif page=="home":
			match event.keycode:
				KEY_LEFT:world.orbit_preview(Vector2(-35,0))
				KEY_RIGHT:world.orbit_preview(Vector2(35,0))
				KEY_UP:world.orbit_preview(Vector2(0,25))
				KEY_DOWN:world.orbit_preview(Vector2(0,-25))
				KEY_PAGEUP:world.zoom_preview(.85)
				KEY_PAGEDOWN:world.zoom_preview(1.0/.85)
				KEY_C:world.reset_preview()
		elif page=="play":
			match event.keycode:
				KEY_E:world.interact()
				KEY_H:world.hint()
				KEY_M:action("map")
				KEY_C:world.reset_camera()
		elif page=="map" and event.keycode==KEY_M:action("close_map")
	if event is InputEventScreenTouch:
		var p:Vector2=ui.logical(event.position)
		if event.pressed and not event.canceled:pointer_down(event.index,p)
		else:pointer_up(event.index)
	elif event is InputEventScreenDrag:
		pointer_move(event.index,ui.logical(event.position),event.relative/ui.factor())
	elif event is InputEventMouseButton:
		var p:Vector2=ui.logical(event.position)
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:pointer_down(-1,p)
			else:pointer_up(-1)
		elif event.button_index==MOUSE_BUTTON_RIGHT:
			mouse_look=event.pressed and (page=="play" or (page=="home" and ui.preview_rect().has_point(p)))
		elif page=="home" and event.pressed and ui.preview_rect().has_point(p):
			if event.button_index==MOUSE_BUTTON_WHEEL_UP:world.zoom_preview(.9)
			elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:world.zoom_preview(1.0/.9)
	elif event is InputEventMouseMotion:
		pointer_move(-1,ui.logical(event.position),event.relative/ui.factor())
		if mouse_look and page=="play":world.orbit(event.relative/ui.factor()*settings.sensitivity)
		elif mouse_look and page=="home" and not preview_pointers.has(-1):world.orbit_preview(event.relative/ui.factor())

func pointer_down(id: int,p: Vector2) -> void:
	var button:String=ui.hit(p)
	if button!="":
		if button=="sprint" and page=="play":sprint_pointer=id
		else:action(button)
		return
	if page=="home":
		if ui.preview_rect().has_point(p) and preview_pointers.size()<2:preview_pointers[id]=p
		return
	if page!="play":return
	if p.x<ui.width()*.43 and p.y>290 and move_pointer==-99:
		move_pointer=id;joystick_origin=Vector2(clampf(p.x,90,ui.width()*.4),clampf(p.y,390,625));joystick=Vector2.ZERO
	elif p.x>ui.width()*.43 and look_pointer==-99:look_pointer=id
func pointer_move(id: int,p: Vector2,relative: Vector2) -> void:
	if page=="home" and preview_pointers.has(id):
		if preview_pointers.size()==2:
			var other:int=preview_pointers.keys()[0] if preview_pointers.keys()[1]==id else preview_pointers.keys()[1]
			var before:float=preview_pointers[id].distance_to(preview_pointers[other])
			var after:float=p.distance_to(preview_pointers[other])
			if before>12 and after>12:world.zoom_preview(before/after)
		else:world.orbit_preview(relative)
		preview_pointers[id]=p;return
	if page!="play":return
	if id==move_pointer:joystick=((p-joystick_origin)/62.0).limit_length()
	elif id==look_pointer:world.orbit(relative*settings.sensitivity)
func pointer_up(id: int) -> void:
	preview_pointers.erase(id)
	if id==move_pointer:move_pointer=-99;joystick=Vector2.ZERO
	if id==look_pointer:look_pointer=-99
	if id==sprint_pointer:sprint_pointer=-99

func show_toast(text: String,duration: float=2.8) -> void:
	toast=text;toast_timer=duration
func save_progress() -> void:
	if saving or not is_instance_valid(world):return
	saving=true
	if page in ["play","pause","map","confirm"]:session=world.snapshot()
	var data:Dictionary={"version":2,"session":session,"records":records,"settings":settings}
	var file:=FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data));file.close()
		DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)
	saving=false
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):return
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:return
	if parsed.get("session",{}) is Dictionary:session=parsed.get("session",{})
	if parsed.get("records",{}) is Dictionary:records=parsed.get("records",{})
	var s=parsed.get("settings",{})
	if s is Dictionary:
		settings.sound=bool(s.get("sound",true));settings.quality=bool(s.get("quality",true))
		settings.sensitivity=clampf(float(s.get("sensitivity",1.0)),.7,1.5)
	chapter=clampi(int(session.get("chapter",0)),0,2)
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		if page=="play" or page=="map":pause_game()
		reset_input()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if page=="play" or page=="map":pause_game()
		elif page=="pause":action("resume")
		elif page=="home":save_progress();get_tree().quit()
		elif page=="win":action("home")
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress();get_tree().quit()

func _exit_tree() -> void:
	if ambiance:ambiance.stop()
