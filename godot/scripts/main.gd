extends Node2D

const Levels = preload("res://scripts/levels.gd")
const Round = preload("res://scripts/round.gd")
const Store = preload("res://scripts/save_store.gd")
const Orb = preload("res://scripts/orb.gd")
const FONT = preload("res://assets/flow-font.otf")
const BG = Color("0c191d")
const PANEL = Color("142a30")
const WHITE = Color("eff5ed")
const MUTED = Color("8fa8a8")
const LIME = Color("c8f77a")
const MINT = Color("78d9cb")
const RED = Color("ff9992")
const BOARD = Rect2(40, 368, 640, 640)

var game = Round.new()
var store = Store.new()
var world: Node2D
var effects: Node2D
var ui: Control
var overlay: Control
var orbs: Array = []
var screen: String = "home"
var target_label: Label
var clock_label: Label
var status_label: Label
var progress: ProgressBar
var combo: int = 0
var last_hit: float = -10.0
var autosave: float = 0.0
var sounds: Array[AudioStreamWAV] = []
var audio: AudioStreamPlayer
var testing: bool = false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	store.load_data()
	world = Node2D.new()
	add_child(world)
	effects = Node2D.new()
	add_child(effects)
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	_build_audio()
	_home()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), BG)
	for i in range(38):
		var point := Vector2(fmod(i * 173.0 + 31, 720), fmod(i * 257.0 + 53, 1280))
		draw_circle(point, 1.4 if i % 3 else 2.2, Color(0.47, 0.85, 0.79, 0.10))
	if screen in ["play", "pause", "result", "restart"]:
		var box := _style(Color("10252a"), Color("2a4449"), 28)
		draw_style_box(box, BOARD.grow(9))
		for x in range(7):
			for y in range(7):
				draw_circle(BOARD.position + Vector2(48 + x * 90, 48 + y * 90), 1.6, Color("294047"))
	else:
		draw_arc(Vector2(580, 377), 61, 0, TAU, 80, Color("3b6259"), 2, true)
		draw_arc(Vector2(580, 377), 85, 0, TAU, 80, Color("28443f"), 1, true)
		draw_circle(Vector2(580, 377), 37, LIME)
		draw_circle(Vector2(624, 335), 12, MINT)
		draw_circle(Vector2(503, 412), 7, LIME)

func _process(delta: float) -> void:
	game.tick(delta)
	if game.state == Round.State.RUNNING:
		clock_label.text = _time(game.elapsed)
		autosave += delta
		if autosave >= 2.0:
			autosave = 0.0
			_save_round()

func _notification(what: int) -> void:
	if not is_instance_valid(ui):
		return
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if game.state == Round.State.RUNNING:
			_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if game.state == Round.State.RUNNING:
			_pause()
		elif screen in ["pause", "restart", "result"]:
			_home()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_round()
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if game.state == Round.State.RUNNING:
			_pause()
		elif screen == "pause":
			_resume()
	if game.state != Round.State.RUNNING:
		return
	if event is InputEventScreenTouch and event.pressed:
		for orb in orbs:
			if orb.position.distance_to(event.position) <= orb.radius:
				_tap(orb)
				get_viewport().set_input_as_handled()
				break

func _style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _label(text: String, rect: Rect2, size: int = 24, color: Color = WHITE, parent: Node = ui) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(text: String, rect: Rect2, action: Callable, primary: bool = false,
		parent: Node = ui, tag: String = "") -> Button:
	var button := Button.new()
	button.name = tag if tag else "Action"
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", BG if primary else WHITE)
	button.add_theme_color_override("font_hover_color", BG if primary else WHITE)
	button.add_theme_color_override("font_pressed_color", BG if primary else WHITE)
	button.add_theme_color_override("font_disabled_color", Color("50666b"))
	button.add_theme_stylebox_override("normal", _style(LIME if primary else PANEL, Color("355057")))
	button.add_theme_stylebox_override("hover", _style(Color("d4ff8e") if primary else Color("244047")))
	button.add_theme_stylebox_override("pressed", _style(MINT if primary else Color("35545b")))
	button.add_theme_stylebox_override("disabled", _style(Color("112228"), Color("24383d")))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, MINT))
	button.pressed.connect(action, CONNECT_DEFERRED)
	parent.add_child(button)
	return button

func _clear_ui() -> void:
	for node in ui.get_children():
		node.free()
	overlay = null
	target_label = null
	clock_label = null
	status_label = null

func _header() -> void:
	_label("◉", Rect2(40, 56, 52, 58), 40, LIME)
	_label("循光", Rect2(104, 55, 200, 40), 29)
	_label("S C H U L T E   F L O W", Rect2(105, 100, 310, 24), 13, MUTED)
	_label("流动数字  /  02", Rect2(485, 76, 195, 40), 18, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _home() -> void:
	if game.state == Round.State.RUNNING or game.state == Round.State.PAUSED:
		game.pause()
		_save_round()
	_clear_world()
	game.state = Round.State.READY
	screen = "home"
	_clear_ui()
	_header()
	_label("让专注，流动起来。", Rect2(40, 172, 650, 70), 43)
	_label("寻找数字 · 追随微光 · 每一次相遇都有回响", Rect2(42, 252, 640, 40), 21, MUTED)
	_label("今日，从一束光开始", Rect2(44, 330, 470, 45), 27, LIME)
	_label("真实碰撞与轻柔漂流\n从 1 开始，按顺序点亮数字", Rect2(44, 389, 445, 70), 21, MUTED)
	var saved = Round.new()
	var can_continue: bool = saved.restore(store.active) and saved.level <= store.unlocked
	if not can_continue:
		store.active = {}
	_button("继续上次的微光" if can_continue else "开始第 %02d 关" % (store.unlocked + 1),
		Rect2(40, 489, 640, 76), _continue_round if can_continue else func(): start_level(store.unlocked), true, ui, "Start")
	_label("星光旅程", Rect2(42, 605, 320, 40), 28)
	_label("%02d / 09 已解锁" % (store.unlocked + 1), Rect2(420, 611, 260, 30), 19, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for index in range(9):
		var level: Dictionary = Levels.DATA[index]
		var record: Dictionary = store.records.get(str(index), {})
		var rating := "★".repeat(record.get("stars", 0))
		var title := "%02d  %s\n%s" % [index + 1, level.name, rating if rating else "%d × %d" % [level.grid, level.grid]]
		var button := _button(title, Rect2(40 + (index % 3) * 218, 669 + (index / 3) * 117, 204, 101),
			func(): start_level(index), false, ui, "Level%d" % index)
		button.add_theme_font_size_override("font_size", 20)
		button.disabled = index > store.unlocked
		if button.disabled:
			button.text = "%02d  待解锁\n完成上一关" % (index + 1)
	_label("通关即解锁 · 零误触并达到目标用时可获三星", Rect2(40, 1042, 640, 40), 19, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button("音效  " + ("开" if store.sound else "关"), Rect2(40, 1120, 308, 65), _toggle_sound, false, ui, "Sound")
	_button("触感  " + ("开" if store.haptics else "关"), Rect2(372, 1120, 308, 65), _toggle_haptics, false, ui, "Haptics")
	_label("离线运行  ·  成绩只保存在本机", Rect2(40, 1210, 640, 30), 17, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	queue_redraw()
	print("FLOW_SCREEN home")

func start_level(index: int) -> void:
	if index < 0 or index > store.unlocked or index >= Levels.DATA.size():
		return
	game.start(index, int(Levels.DATA[index].grid) ** 2)
	combo = 0
	last_hit = -10.0
	_spawn_board()
	_freeze(false)
	_play_ui()
	_save_round()

func _clear_world() -> void:
	orbs.clear()
	for node in world.get_children():
		node.free()
	for node in effects.get_children():
		node.queue_free()

func _spawn_board() -> void:
	_clear_world()
	var level: Dictionary = Levels.DATA[game.level]
	var grid: int = level.grid
	var cell: float = BOARD.size.x / grid
	for rect in [Rect2(20, 348, 20, 680), Rect2(680, 348, 20, 680),
			Rect2(20, 348, 680, 20), Rect2(20, 1008, 680, 20)]:
		var wall := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		collision.shape = RectangleShape2D.new()
		collision.shape.size = rect.size
		wall.position = rect.get_center()
		wall.add_child(collision)
		world.add_child(wall)
	var numbers := range(1, game.count + 1)
	numbers.shuffle()
	for i in range(game.count):
		var orb = Orb.new()
		orb.number = numbers[i]
		orb.font = FONT
		orb.radius = cell * 0.38
		orb.speed = level.speed
		orb.position = BOARD.position + Vector2((i % grid + 0.5) * cell, (i / grid + 0.5) * cell)
		orb.linear_velocity = Vector2.from_angle(randf() * TAU) * level.speed
		orb.done = orb.number < game.next
		orb.bumped.connect(func(at: Vector2): _burst(at, MINT, 5, 0.3, 28.0))
		world.add_child(orb)
		orbs.append(orb)

func _play_ui() -> void:
	screen = "play"
	_clear_ui()
	_header()
	var level: Dictionary = Levels.DATA[game.level]
	_label("第 %02d 关  /  %s" % [game.level + 1, level.name], Rect2(42, 157, 640, 40), 24, MINT)
	_label("下一个目标", Rect2(42, 216, 260, 30), 18, MUTED)
	target_label = _label("%02d" % game.next, Rect2(40, 245, 220, 80), 64, LIME)
	clock_label = _label(_time(game.elapsed), Rect2(350, 235, 330, 60), 39)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label("三星目标  %.0f 秒 · 零误触" % level.par, Rect2(330, 298, 350, 30), 18, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress = ProgressBar.new()
	progress.position = Vector2(42, 344)
	progress.size = Vector2(636, 5)
	progress.max_value = game.count
	progress.value = game.next - 1
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", _style(Color("29434a"), Color.TRANSPARENT, 2))
	progress.add_theme_stylebox_override("fill", _style(LIME, Color.TRANSPARENT, 2))
	ui.add_child(progress)
	_button("暂停一下", Rect2(40, 1054, 426, 76), _pause, false, ui, "Pause")
	_button("重新开始", Rect2(486, 1054, 194, 76), _confirm_restart, false, ui, "Restart")
	status_label = _label(level.hint, Rect2(40, 1151, 640, 42), 21, MINT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label("按顺序寻找 · 点错不加时 · 暂停会隐藏数字", Rect2(40, 1210, 640, 30), 17, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	queue_redraw()
	print("FLOW_SCREEN play level=%d" % game.level)

func _tap(orb: RigidBody2D) -> void:
	var hit = game.tap(orb.number)
	if hit == Round.Hit.IGNORED:
		return
	if hit == Round.Hit.WRONG:
		orb.flash = 1.0
		combo = 0
		last_hit = -10.0
		status_label.text = "先找 %d  ·  误触 %d 次" % [game.next, game.mistakes]
		_tone(0, 0.55)
		_burst(orb.position, RED, 12, 0.4, 80.0)
	else:
		orb.done = true
		combo = combo + 1 if game.elapsed - last_hit <= 1.8 else 1
		last_hit = game.elapsed
		_tone(mini(combo, 6), 1.0)
		_burst(orb.position, LIME, 24, 0.65, 125.0)
		for neighbor in orbs:
			var direction: Vector2 = neighbor.position - orb.position
			if neighbor != orb and direction.length() < 260:
				neighbor.apply_central_impulse(direction.normalized() * 36.0)
		target_label.text = "%02d" % mini(game.next, game.count)
		progress.value = game.next - 1
		status_label.text = "连击 × %d  ·  节奏正好" % combo if combo >= 3 else "点亮了 %d  ·  继续寻找 %d" % [orb.number, game.next]
	if store.haptics and OS.has_feature("android"):
		Input.vibrate_handheld(18 if hit != Round.Hit.WRONG else 35)
	if hit == Round.Hit.FINISHED:
		_finish()
	else:
		_save_round()

func _freeze(value: bool) -> void:
	for orb in orbs:
		orb.freeze = value
	world.visible = not value
	effects.visible = not value
	world.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	effects.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

func _modal(title: String, subtitle: String) -> Control:
	if is_instance_valid(overlay):
		overlay.free()
	overlay = Control.new()
	overlay.size = Vector2(720, 1280)
	ui.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.06, 0.075, 0.97)
	dim.size = Vector2(720, 1280)
	overlay.add_child(dim)
	_label("S C H U L T E   F L O W", Rect2(40, 218, 640, 35), 17, MUTED, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(title, Rect2(40, 304, 640, 75), 46, LIME, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(subtitle, Rect2(40, 402, 640, 75), 22, MUTED, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return overlay

func _pause() -> void:
	if game.state != Round.State.RUNNING:
		return
	game.pause()
	_save_round()
	_show_pause()

func _show_pause() -> void:
	screen = "pause"
	_freeze(true)
	_modal("稍作停留", "计时与星光都已暂停\n你的进度还在")
	_label(_time(game.elapsed), Rect2(40, 520, 640, 70), 45, WHITE, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button("继续循光", Rect2(80, 676, 560, 80), _resume, true, overlay, "Resume")
	_button("返回关卡", Rect2(80, 784, 560, 76), _home, false, overlay, "Home")
	print("FLOW_SCREEN pause")

func _resume() -> void:
	if game.state != Round.State.PAUSED:
		return
	game.resume()
	combo = 0
	last_hit = -10.0
	_freeze(false)
	_play_ui()

func _confirm_restart() -> void:
	if game.state != Round.State.RUNNING:
		return
	_pause()
	screen = "restart"
	_modal("重新点亮这一关？", "当前进度会重置\n已解锁的关卡与最佳成绩会保留")
	_button("重新开始", Rect2(80, 676, 560, 80), func():
		_freeze(false)
		start_level(game.level), true, overlay, "ConfirmRestart")
	_button("保留这一局", Rect2(80, 784, 560, 76), _resume, false, overlay, "CancelRestart")
	print("FLOW_SCREEN restart")

func _finish() -> void:
	screen = "result"
	_freeze(true)
	var stars: int = Levels.stars(game.elapsed, game.mistakes, Levels.DATA[game.level].par)
	store.complete(game.level, game.elapsed, stars)
	_modal("每一束光，都被点亮", "第 %02d 关完成  ·  %s" % [game.level + 1, Levels.DATA[game.level].name])
	_label("★".repeat(stars) + "☆".repeat(3 - stars), Rect2(40, 495, 640, 70), 52, LIME, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(_time(game.elapsed), Rect2(40, 592, 640, 70), 54, WHITE, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label("准确率 %.0f%%    ·    误触 %d 次" % [game.count * 100.0 / (game.count + game.mistakes), game.mistakes], Rect2(40, 688, 640, 40), 24, MINT, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var record: Dictionary = store.records[str(game.level)]
	_label("本关最佳  %s" % _time(record.time), Rect2(40, 746, 640, 40), 20, MUTED, overlay).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button("下一关，继续循光" if game.level < 8 else "全部通关 · 再次挑战", Rect2(80, 846, 560, 80), func():
		_freeze(false)
		start_level(mini(game.level + 1, 8)), true, overlay, "Next")
	_button("返回星光旅程", Rect2(80, 950, 560, 76), _home, false, overlay, "Home")
	# The celebration lives above the modal, while the board stays hidden.
	for pos in [Vector2(180, 530), Vector2(540, 530)]:
		_burst(pos, LIME, 45, 1.3, 170.0, overlay)
	print("FLOW_SCREEN result level=%d stars=%d" % [game.level, stars])

func _save_round() -> void:
	if game.state not in [Round.State.RUNNING, Round.State.PAUSED]:
		return
	store.active = game.snapshot()
	var positions: Array = []
	for orb in orbs:
		positions.append({"n": orb.number, "x": orb.position.x, "y": orb.position.y,
			"vx": orb.linear_velocity.x, "vy": orb.linear_velocity.y})
	store.active["orbs"] = positions
	if store.save() != OK:
		push_warning("Progress could not be saved")

func _continue_round() -> void:
	if not game.restore(store.active) or game.level > store.unlocked:
		start_level(store.unlocked)
		return
	_spawn_board()
	var positions = store.active.get("orbs", [])
	if _valid_positions(positions):
		for data in positions:
			for orb in orbs:
				if orb.number == int(data.n):
					orb.position = Vector2(data.x, data.y)
					orb.linear_velocity = Vector2(data.vx, data.vy)
	_play_ui()
	_show_pause()

func _valid_positions(positions: Variant) -> bool:
	if not positions is Array or positions.size() != game.count:
		return false
	var seen: Array = []
	var radius: float = BOARD.size.x / Levels.DATA[game.level].grid * 0.38
	for data in positions:
		if not data is Dictionary:
			return false
		for key in ["n", "x", "y", "vx", "vy"]:
			var value = data.get(key)
			if not (value is float or value is int) or not is_finite(float(value)):
				return false
		if data.n != int(data.n) or data.n < 1 or data.n > game.count or data.n in seen:
			return false
		if not BOARD.grow(-radius + 2).has_point(Vector2(data.x, data.y)) or Vector2(data.vx, data.vy).length() > 151:
			return false
		seen.append(data.n)
	return true

func _burst(at: Vector2, color: Color, amount: int, lifetime: float, speed: float, parent: Node = effects) -> void:
	if parent == effects and (game.state != Round.State.RUNNING or effects.get_child_count() >= 32):
		return
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 55)
	particles.initial_velocity_min = speed * 0.3
	particles.initial_velocity_max = speed
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0.0))
	particles.color_ramp = gradient
	particles.finished.connect(particles.queue_free)
	parent.add_child(particles)
	particles.emitting = true

func _build_audio() -> void:
	audio = AudioStreamPlayer.new()
	add_child(audio)
	for frequency in [150.0, 261.63, 329.63, 392.0, 523.25, 659.25, 783.99]:
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var samples := PackedByteArray()
		samples.resize(6615 * 2)
		for i in range(6615):
			var t: float = i / 22050.0
			var envelope: float = minf(t * 120.0, 1.0) * exp(-t * 17.0)
			samples.encode_s16(i * 2, int(sin(TAU * frequency * t) * envelope * 9500))
		stream.data = samples
		sounds.append(stream)

func _tone(index: int, pitch: float) -> void:
	if store.sound and not testing:
		audio.stream = sounds[index]
		audio.pitch_scale = pitch
		audio.volume_db = -8.0
		audio.play()

func _toggle_sound() -> void:
	store.sound = not store.sound
	store.save()
	_tone(3, 1.0)
	_home()

func _toggle_haptics() -> void:
	store.haptics = not store.haptics
	store.save()
	_home()

func _time(seconds: float) -> String:
	var centiseconds := int(seconds * 100)
	return "%02d:%02d.%02d" % [centiseconds / 6000, centiseconds / 100 % 60, centiseconds % 100]
