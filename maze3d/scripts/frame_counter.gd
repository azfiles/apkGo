extends PanelContainer
## Rendered FPS, sampled twice a second; independent of the game's physics timer.
var label: Label
var sample_time := 0.5
var frame_rate := 0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(132,30)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(.98,.99,.93,.94)
	style.border_color=Color(.25,.45,.34,.25)
	style.set_border_width_all(1);style.set_corner_radius_all(10)
	style.content_margin_left=12;style.content_margin_right=12
	add_theme_stylebox_override("panel",style)
	label=Label.new();label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",preload("res://assets/latin-font.otf"))
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",Color("344d48"))
	label.text="-- FPS";label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

func _process(dt: float) -> void:
	if not visible:return
	sample_time+=dt
	if sample_time<.5:return
	sample_time=0
	frame_rate=Engine.get_frames_per_second()
	label.text="%d FPS"%frame_rate if frame_rate>0 else "-- FPS"

func place(page: String, viewport_size: Vector2) -> void:
	var scale_factor:=viewport_size.y/720.0
	scale=Vector2.ONE*scale_factor
	position=Vector2(viewport_size.x-164*scale_factor,277*scale_factor)
	if page=="home":position=Vector2(viewport_size.x-380*scale_factor,31*scale_factor)
	elif page=="map":position.y=103*scale_factor
	elif page!="play":position.y=28*scale_factor
