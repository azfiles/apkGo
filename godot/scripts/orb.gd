extends RigidBody2D

signal bumped(at: Vector2)
var number: int = 1
var radius: float = 60.0
var done: bool = false
var flash: float = 0.0
var cooldown: float = 0.0
var speed: float = 20.0
var font: Font

func _ready() -> void:
	gravity_scale = 0.0
	lock_rotation = true
	can_sleep = false
	linear_damp = 0.12
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 4
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.92
	physics_material_override.friction = 0.0
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = radius
	add_child(shape)
	body_entered.connect(_collided)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var velocity: Vector2 = state.linear_velocity
	if velocity.length() < speed * 0.7:
		velocity = velocity.normalized() * speed if velocity.length() > 0.1 else Vector2(speed, 0)
	state.linear_velocity = velocity.limit_length(150.0)

func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta * 3.0)
	cooldown = maxf(0.0, cooldown - delta)
	queue_redraw()

func _collided(_body: Node) -> void:
	if cooldown <= 0.0 and linear_velocity.length() > 15.0:
		cooldown = 0.4
		bumped.emit(position)

func _draw() -> void:
	var fill := Color("173238") if not done else Color("203c33")
	var edge := Color("426066") if not done else Color("688b4a")
	fill = fill.lerp(Color("803c48"), flash)
	draw_circle(Vector2(0, 6), radius + 3, Color(0, 0, 0, 0.18))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius - 1, 0, TAU, 64, edge, 2.0, true)
	draw_arc(Vector2.ZERO, radius - 8, PI * 1.12, PI * 1.72, 24, Color(0.8, 0.95, 0.9, 0.13), 2, true)
	var text := str(number) if not done else "·"
	var font_size := int(radius * 0.66)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(-width / 2, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size, Color("ecf5ed") if not done else Color("c8f77a"))
