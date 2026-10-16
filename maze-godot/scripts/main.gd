extends Control

const Model = preload("res://scripts/maze_model.gd")
const World = preload("res://scripts/garden_world.gd")
const Store = preload("res://scripts/save_store.gd")
const Sound = preload("res://scripts/sound.gd")
const FONT = preload("res://assets/garden-font.otf")
const BOLD = preload("res://assets/garden-bold.otf")
const LATIN = preload("res://assets/latin-font.otf")
const SERIF = preload("res://assets/title-font.otf")
const INK = Color("344c40")
const MUTED = Color("83877a")
const CREAM = Color("f3f0e7")
const LINE = Color("dcded1")

var testing := false
var store = Store.new()
var model = Model.new()
var levels: Array = Model.catalog()
var level_index := 0
var state := "home"
var world
var sound
var viewport_3d: SubViewport
var map_container: SubViewportContainer
var primary: Button
var sound_button: Button
var pause_button: Button
var eyebrow: Label
var heading: Label
var intro: Label
var map_title: Label
var toast_label: Label
var status_label: Label
var stamp_labels: Array[Label] = []
var chapter_buttons: Array[Button] = []
var controls: Control
var modal: Control
var modal_panel: Panel
var modal_title: Label
var modal_body: Label
var modal_main: Button
var modal_second: Button
var modal_third: Button
var modal_pictures: Control
var stamp_summary: Label
var player_badge: Label
var goal_badge: Label
var touch_direction := Vector2.ZERO
var toast_time := 0.0
var previous_found := 0

func _ready() -> void:
	name = "GardenMaze"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().auto_accept_quit = false
	store.load_data()
	_setup_input()
	sound = Sound.new()
	add_child(sound)
	sound.enabled = store.sound
	_build_ui()
	var initial := 0
	for i in range(levels.size()):
		if store.active.has(str(i)): initial = i
	load_level(initial)
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_title("Pipi Maze · 花园捉迷藏")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), CREAM)
	draw_circle(Vector2(855, 373), 274, Color("eeeee2"))
	draw_circle(Vector2(855, 373), 233, Color("f0efe5"))
	draw_line(Vector2(48, 110), Vector2(1232, 110), LINE, 1.0)
	draw_line(Vector2(48, 405), Vector2(317, 405), LINE, 1.0)
	draw_line(Vector2(48, 695), Vector2(1232, 695), LINE, 1.0)
	# Small maze mark; all other icons use the bundled font.
	draw_style_box(_style(INK, 12), Rect2(48, 33, 44, 44))
	var points := PackedVector2Array([Vector2(59,65),Vector2(59,45),Vector2(77,45),Vector2(77,53),Vector2(67,53),Vector2(67,65)])
	draw_polyline(points, Color("eee7d1"), 3.0, true)
	draw_circle(Vector2(79,65), 4, Color("d6ad67"))

func _build_ui() -> void:
	_label(self, "PIPI MAZE", Rect2(105, 30, 250, 30), 25, INK, LATIN)
	_label(self, "小侦探的花园漫游", Rect2(106, 65, 250, 20), 13, MUTED)
	_label(self, "GARDEN HIDE & SEEK", Rect2(515, 47, 350, 25), 14, MUTED, LATIN)
	sound_button = _button(self, "♪  声音开启", Rect2(938, 36, 140, 44), _toggle_sound, false)
	pause_button = _button(self, "操作与来源", Rect2(1090, 36, 142, 44), _header_action, false)
	eyebrow = _label(self, "", Rect2(48, 151, 285, 25), 13, MUTED, LATIN)
	heading = _label(self, "", Rect2(44, 191, 290, 116), 43, INK, BOLD)
	heading.add_theme_constant_override("line_spacing", 5)
	intro = _label(self, "", Rect2(48, 331, 280, 62), 16, Color("798372"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var mission := _panel(self, Rect2(48, 428, 270, 91), Color("fbfaf5"), 16)
	_picture(mission, "koala", Rect2(15, 17, 58, 58))
	_label(mission, "这次要找到", Rect2(90, 15, 150, 23), 13, MUTED)
	_label(mission, "小考拉", Rect2(89, 40, 154, 34), 23, INK, BOLD)
	_label(self, "顺路发现自然印记", Rect2(48, 538, 210, 25), 13, MUTED)
	_label(self, "可选", Rect2(276, 538, 45, 25), 12, MUTED)
	for i in range(3):
		var stamp := _label(self, "", Rect2(48 + i * 94, 572, 82, 36), 14, INK, LATIN)
		stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stamp_labels.append(stamp)
	primary = _button(self, "开始探险  ↗", Rect2(48, 625, 270, 52), start_play, true)
	map_container = SubViewportContainer.new()
	map_container.name = "GardenView"
	map_container.position = Vector2(345, 152)
	map_container.size = Vector2(890, 525)
	map_container.stretch = true
	map_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_container)
	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(890, 525)
	viewport_3d.transparent_bg = true
	viewport_3d.own_world_3d = true
	viewport_3d.msaa_3d = Viewport.MSAA_2X
	map_container.add_child(viewport_3d)
	world = World.new()
	viewport_3d.add_child(world)
	world.changed.connect(_on_progress)
	world.finished.connect(_on_finish)
	# Map labels are siblings of the viewport so they stay crisp at every DPI.
	map_title = _label(self, "", Rect2(674, 132, 270, 39), 15, INK)
	map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	map_title.add_theme_stylebox_override("normal", _style(Color("fcfbf5"), 19, LINE))
	_label(self, "一座小花园，一场小冒险。", Rect2(375, 654, 450, 25), 14, MUTED)
	status_label = _label(self, "", Rect2(375, 626, 525, 23), 13, MUTED)
	toast_label = _label(self, "", Rect2(495, 574, 480, 39), 15, INK)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_stylebox_override("normal", _style(Color("fff9e8"), 18, Color("e6d7ad")))
	toast_label.visible = false
	player_badge = _label(self, "布朗", Rect2(0, 0, 64, 27), 12, INK)
	player_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_badge.add_theme_stylebox_override("normal", _style(Color("faf7e9"), 13))
	goal_badge = _label(self, "小考拉", Rect2(0, 0, 78, 28), 12, INK)
	goal_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_badge.add_theme_stylebox_override("normal", _style(Color("f7eed3"), 13))
	_build_controls()
	for i in range(3):
		var index := i
		var button := _button(self, "", Rect2(48 + i * 402, 711, 380, 55), func(): load_level(index), false)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		chapter_buttons.append(button)
	_label(self, "PIPI MAZE  /  原创迷宫 · 2.5D 探索体验", Rect2(48, 779, 600, 18), 11, MUTED)
	var foot := _label(self, "慢慢走，也能找到答案。", Rect2(890, 779, 342, 18), 11, MUTED)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_build_modal()

func load_level(index: int, fresh: bool = false) -> void:
	if world and state == "playing": _persist()
	level_index = clampi(index, 0, levels.size() - 1)
	model.setup(levels[level_index])
	if not fresh and store.active.has(str(level_index)):
		var data = store.active[str(level_index)]
		if data is Dictionary and not model.restore(data): store.active.erase(str(level_index))
	state = "home"
	touch_direction = Vector2.ZERO
	modal.visible = false
	controls.visible = false
	world.build(model)
	previous_found = model.collected.size()
	var titles := ["花园里的\n捉迷藏", "沿着池畔\n慢慢探索", "暮色里的\n秘密小径"]
	heading.text = titles[level_index]
	eyebrow.text = "CHAPTER  %02d / 03" % (level_index + 1)
	intro.text = levels[level_index].subtitle
	map_title.text = "%02d   %s" % [level_index + 1, levels[level_index].title]
	_update_ui()
	queue_redraw()

func start_play() -> void:
	if state == "playing":
		show_hint()
		return
	if state != "home": return
	state = "playing"
	world.active = true
	controls.visible = true
	sound.play_note(0)
	_toast("点一下浅色小路，布朗就会走过去。")
	_persist()
	_update_ui()

func show_hint() -> void:
	if state != "playing": return
	world.show_marks(model.hint_path())
	_toast("亮点指向小考拉，接下来由你来走。")
	sound.play_note(2)
	_persist()

func _on_progress() -> void:
	if model.collected.size() > previous_found:
		previous_found = model.collected.size()
		sound.play_note(2 + previous_found * 2)
		_toast("发现一枚自然印记！  %d / 3" % previous_found)
	_update_ui()
	_persist()

func _on_finish() -> void:
	state = "complete"
	touch_direction = Vector2.ZERO
	controls.visible = false
	store.finish(level_index, model.collected.size())
	sound.play_note(12)
	_show_modal("找到小考拉啦！", "穿过树篱，终于和小考拉碰面。\n发现 %d / 3 枚自然印记 · 走过 %d 格小路" % [model.collected.size(), model.steps], "下一座花园  ↗" if level_index < 2 else "回到花园", _next_level, "再探索一次", _restart)
	modal_pictures.visible = true
	stamp_summary.text = "★".repeat(1 + mini(model.collected.size(), 2)) + "☆".repeat(2 - mini(model.collected.size(), 2))
	if model.collected.size() < 3: stamp_summary.text = "★★☆" if model.collected.size() > 0 else "★☆☆"
	_update_ui()

func _next_level() -> void:
	load_level((level_index + 1) % 3)

func _restart() -> void:
	store.active.erase(str(level_index))
	state = "home" # prevents saving the abandoned run before rebuilding
	load_level(level_index, true)
	start_play()

func pause_play() -> void:
	if state != "playing": return
	state = "paused"
	world.active = false
	world.manual = Vector2.ZERO
	world.route.clear()
	touch_direction = Vector2.ZERO
	_persist()
	_show_modal("休息一下", "花园会在这里等你。\n不计时，按自己的节奏慢慢走。", "继续探险", resume_play, "重新开始", _confirm_restart)
	modal_third.visible = true
	modal_third.text = "回到花园首页"
	modal_third.pressed.connect(_return_home, CONNECT_ONE_SHOT)

func resume_play() -> void:
	modal.visible = false
	state = "playing"
	world.active = true
	_update_ui()

func _return_home() -> void:
	load_level(level_index)

func _confirm_restart() -> void:
	_show_modal("从入口重新出发？", "这一趟收集的印记会重置。\n已经完成的花园记录会保留。", "重新出发", _restart, "继续这一趟", resume_play)

func _header_action() -> void:
	if state == "playing":
		pause_play()
	else:
		_show_modal("慢慢走，慢慢发现", "点击浅色路面自动寻路，或用方向键 / WASD。\n触屏可按右下方方向盘；H 提示，Esc 暂停。\n自然印记为可选目标，抵达小考拉即可通关。\n\n角色原图复用自 pipi-maze，版权归原权利人。\n这是非官方兴趣原型；场景与关卡为原创适配。", "回到花园", func(): modal.visible = false, "查看素材来源", func(): OS.shell_open("https://github.com/azfiles/pipi-maze/blob/main/ASSET_SOURCES.md"))

func _toggle_sound() -> void:
	store.sound = not store.sound
	sound.enabled = store.sound
	if not testing: store.save_data()
	_update_ui()
	if store.sound: sound.play_note(0)

func _update_ui() -> void:
	primary.text = "给我一点提示  ✧" if state == "playing" else ("继续探险  ↗" if model.steps > 0 else "开始探险  ↗")
	pause_button.text = "Ⅱ  暂停" if state == "playing" else "操作与来源"
	sound_button.text = "♪  声音开启" if store.sound else "♪  声音关闭"
	status_label.text = "方向键 / WASD 移动 · H 提示 · Esc 暂停" if state == "playing" else "轻松探索   /   不计时   /   本机自动保存"
	for i in range(3):
		var found: bool = model.collected.has(model.stamps[i])
		stamp_labels[i].text = "✓  %02d" % (i + 1) if found else "✧  %02d" % (i + 1)
		stamp_labels[i].add_theme_stylebox_override("normal", _style(Color("e0e7d3") if found else Color("eae9de"), 10))
		var label: String = "%02d    %s" % [i + 1, levels[i].title]
		if store.records.has(str(i)): label += "    已找到 ✓"
		chapter_buttons[i].text = label
		chapter_buttons[i].add_theme_stylebox_override("normal", _style(Color("e1e6d7") if i == level_index else Color("f8f6ef"), 13, Color("bec9b2") if i == level_index else LINE))
		chapter_buttons[i].disabled = state in ["playing", "paused", "complete"]

func _build_controls() -> void:
	controls = Control.new()
	controls.position = Vector2(1032, 462)
	controls.size = Vector2(198, 198)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls)
	for item in [["↑", Vector2(66, 0), Vector2.UP], ["←", Vector2(0, 66), Vector2.LEFT], ["→", Vector2(132, 66), Vector2.RIGHT], ["↓", Vector2(66, 132), Vector2.DOWN]]:
		var direction: Vector2 = item[2]
		var button := _button(controls, item[0], Rect2(item[1], Vector2(60, 60)), func(): pass, false)
		button.add_theme_font_size_override("font_size", 24)
		button.button_down.connect(func(): touch_direction = direction)
		button.button_up.connect(func(): touch_direction = Vector2.ZERO)
	_label(controls, "步", Rect2(69, 80, 54, 30), 13, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_modal() -> void:
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.15, 0.22, 0.17, 0.53)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	modal_panel = _panel(modal, Rect2(370, 170, 540, 463), Color("f9f7ee"), 25)
	modal_title = _label(modal_panel, "", Rect2(28, 27, 484, 43), 30, INK, BOLD)
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body = _label(modal_panel, "", Rect2(32, 89, 476, 180), 15, Color("798372"))
	modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_theme_constant_override("line_spacing", 7)
	modal_pictures = Control.new()
	modal_pictures.position = Vector2(125, 158)
	modal_panel.add_child(modal_pictures)
	_picture(modal_pictures, "brown", Rect2(0, 0, 86, 100))
	_picture(modal_pictures, "koala", Rect2(150, 0, 95, 100))
	stamp_summary = _label(modal_pictures, "", Rect2(0, 110, 290, 36), 26, Color("bd9854"))
	stamp_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_main = _button(modal_panel, "", Rect2(48, 324, 444, 48), func(): pass, true)
	modal_second = _button(modal_panel, "", Rect2(48, 381, 444, 38), func(): pass, false)
	modal_third = _button(modal_panel, "", Rect2(48, 425, 444, 30), func(): pass, false)
	modal_third.add_theme_font_size_override("font_size", 13)
	modal.visible = false

func _show_modal(title: String, body: String, first: String, first_action: Callable, second: String, second_action: Callable) -> void:
	modal_title.text = title
	modal_body.text = body
	modal_pictures.visible = false
	modal_third.visible = false
	for button in [modal_main, modal_second, modal_third]:
		for connection in button.pressed.get_connections():
			button.pressed.disconnect(connection.callable)
	modal_main.text = first
	modal_second.text = second
	modal_main.pressed.connect(first_action)
	modal_second.pressed.connect(second_action)
	modal.visible = true

func _physics_process(_delta: float) -> void:
	if not world: return
	world.manual = touch_direction if touch_direction != Vector2.ZERO else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if state != "playing": world.manual = Vector2.ZERO

func _process(delta: float) -> void:
	if not world or not world.player: return
	var p: Vector2 = world.camera.unproject_position(world.player.position + Vector3(0, 1.32, 0))
	player_badge.position = map_container.position + p - Vector2(32, 22)
	var g: Vector2 = world.camera.unproject_position(world.cell_to_world(model.goal) + Vector3(0, 1.55, 0))
	goal_badge.position = map_container.position + g - Vector2(39, 22)
	toast_time -= delta
	if toast_time <= 0: toast_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE] and state == "home" and not modal.visible:
			start_play()
			get_viewport().set_input_as_handled()
		if event.physical_keycode in [KEY_ESCAPE, KEY_P] or event.keycode in [KEY_ESCAPE, KEY_P]:
			if state == "playing": pause_play()
			elif state == "paused": resume_play()
			get_viewport().set_input_as_handled()
		if (event.physical_keycode == KEY_H or event.keycode == KEY_H) and not modal.visible: show_hint()
	if state != "playing" or modal.visible: return
	if event is InputEventMouseMotion:
		var local: Vector2 = event.position - map_container.position
		if Rect2(Vector2.ZERO, map_container.size).has_point(local): world.hover(world.screen_cell(local))
		else: world.hover(Vector2i(-1, -1))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local: Vector2 = event.position - map_container.position
		if Rect2(Vector2.ZERO, map_container.size).has_point(local):
			if not world.navigate(world.screen_cell(local)):
				_toast("那边是树篱，试试点浅色的小路。")

func _notification(what: int) -> void:
	if not world: return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pause_play()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == "playing": pause_play()
		elif state == "paused": resume_play()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_persist()
		get_tree().quit()

func _persist() -> void:
	if testing or model.completed: return
	if state in ["playing", "paused"]:
		store.active[str(level_index)] = model.snapshot()
		store.save_data()

func _toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	toast_time = 4.2

func _setup_input() -> void:
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN]}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _style(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style

func _panel(parent: Node, rect: Rect2, color: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(color, radius))
	parent.add_child(panel)
	return panel

func _label(parent: Node, text_: String, rect: Rect2, font_size: int, color: Color = INK, font: Font = FONT) -> Label:
	var label := Label.new()
	label.text = text_
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text_: String, rect: Rect2, action: Callable, filled: bool = false) -> Button:
	var button := Button.new()
	button.text = text_
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("f5f1df") if filled else INK)
	button.add_theme_color_override("font_hover_color", Color("fff9e4") if filled else INK)
	button.add_theme_color_override("font_pressed_color", Color("fff9e4") if filled else INK)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _style(INK if filled else Color("faf8ef"), 13, Color.TRANSPARENT if filled else LINE))
	button.add_theme_stylebox_override("hover", _style(Color("46634f") if filled else Color("e7eadc"), 13))
	button.add_theme_stylebox_override("pressed", _style(Color("2b4234") if filled else Color("d8e0ce"), 13))
	button.add_theme_stylebox_override("disabled", _style(Color("e9eade"), 13))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _picture(parent: Node, key: String, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/characters/%s.png" % key)
	atlas.region = {"brown": Rect2(95, 168, 159, 257), "koala": Rect2(72, 48, 319, 361), "detective": Rect2(25, 33, 299, 392)}[key]
	picture.texture = atlas
	picture.position = rect.position
	picture.size = rect.size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture
