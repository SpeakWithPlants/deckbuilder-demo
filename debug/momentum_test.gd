extends Node2D

const radius: float = 50.0
const gravity: float = 8000.0
const friction: float = 5.5
const dampening: float = 5.5#0.998

var mouse_pos: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var mouse_velocity: Vector2 = Vector2.ZERO
var last_mouse_velocity: Vector2 = Vector2.ZERO
var mouse_acceleration: Vector2 = Vector2.ZERO
var mass_pos: Vector2 = Vector2(1920, 1080) / 2
var last_mass_pos: Vector2 = Vector2.ZERO
var a_mass: Vector2 = Vector2.ZERO
var v_mass: Vector2 = Vector2.ZERO

var angle: float = randf() * TAU
var angular_velocity: float = 0
var angular_acceleration: float = 0

var vangle: Vector2 = Vector2.ZERO
var vangular_velocity: Vector2 = Vector2.ZERO
var vangular_acceleration: Vector2 = Vector2.ZERO

var acceleration: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

var velocity_queue: Array[Vector2] = []
var velocity_weights: Array[float] = [4, 3, 2, 1]

@onready var label = $Label


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("mouse_right"):
		angle = randf() * TAU
		angular_velocity = 0
		angular_acceleration = 0
		vangle = Vector2(0, -PI / 2)
		vangular_velocity = Vector2.ZERO
		vangular_acceleration = Vector2.ZERO
	last_mouse_pos = mouse_pos
	last_mass_pos = mass_pos
	mouse_pos = get_global_mouse_position()
	#mouse_velocity = Input.get_last_mouse_velocity()
	mouse_acceleration = (mouse_velocity - last_mouse_velocity) / delta
	last_mouse_velocity = mouse_velocity
	_update_mouse_velocity(delta)
	_update_physics6(delta)
	queue_redraw()
	pass


func _draw() -> void:
	var start = mouse_pos
	var end = mass_pos
	draw_line(start, end, Color.RED, -1.0, true)
	draw_circle(end, 5.0, Color.RED, true, -1.0, true)
	#draw_line(start, start + Vector2.RIGHT.rotated(vangle.x) * 40, Color.BLUE, -1.0, true)
	pass


func _update_label() -> void:
	var lines = [
		"A: (%.2f, %.2f)" % [mouse_acceleration.x, mouse_acceleration.y],
		"V: (%.2f, %.2f)" % [mouse_velocity.x, mouse_velocity.y],
		"P: (%.2f, %.2f)" % [mass_pos.x, mass_pos.y],
		"D: (%.2f)" % [mouse_acceleration.angle()]
	]
	label.text = "\n".join(lines)
	pass


func _update_physics6(delta) -> void:
	var local_mass_pos = mass_pos - Global.mouse_pos
	var a_direction = Global.mouse_pos.direction_to(mass_pos)
	var mass_distance = Global.mouse_pos.distance_to(mass_pos)
	var mass_z = 0.0
	var phi
	if mass_distance > radius:
		local_mass_pos = a_direction * radius
		phi = PI / 2
	else:
		mass_z = sqrt(pow(radius, 2) - pow(local_mass_pos.x, 2) - pow(local_mass_pos.y, 2))
		phi = acos(mass_z / radius)
	var half_clamp = PI * 0.5
	var clamp_precision = 6
	#var clamp_factor = pow(2, -pow(phi / half_clamp, 2 * clamp_precision))
	var clamp_factor = pow(phi / half_clamp, 2 * clamp_precision) + 1
	var a_gravity = -gravity * a_direction * sin(phi) * max(1, mass_distance / radius) * clamp_factor
	var a_friction = -friction * velocity
	
	acceleration = a_gravity + a_friction
	velocity += acceleration * delta
	mass_pos += velocity * delta
	pass


func _update_physics5(delta) -> void:
	var a_mouse = -mouse_acceleration / radius
	var a_gravity = -gravity * Vector2(sin(vangle.x), sin(vangle.y)) / radius
	var a_friction = -friction * vangular_velocity
	vangular_acceleration = a_gravity + a_friction + a_mouse
	vangular_velocity += vangular_acceleration * delta
	vangle += vangular_velocity * delta
	
	var clamp_factor_x = Vector2(1, pow(1.01, -pow(vangle.x, 6)))
	if sign(vangle.x) == sign(vangular_acceleration.x):
		vangular_acceleration *= clamp_factor_x
	if sign(vangle.x) == sign(vangular_velocity.x):
		vangular_velocity *= clamp_factor_x
	vangle.x = clamp(vangle.x, -PI / 2, PI / 2)
	
	var clamp_factor_y = Vector2(1, pow(1.01, -pow(vangle.y, 6)))
	if sign(vangle.y) == sign(vangular_acceleration.y):
		vangular_acceleration *= clamp_factor_y
	if sign(vangle.y) == sign(vangular_velocity.y):
		vangular_velocity *= clamp_factor_y
	vangle.y = clamp(vangle.y, -PI / 2, PI / 2)
	
	var x = radius * sin(vangle.x)
	var y = radius * sin(vangle.y)
	mass_pos = mouse_pos + Vector2(x, y)
	pass


func _update_physics4(delta) -> void:
	var mangle = mouse_acceleration.angle()
	var d_theta = mangle - vangle.x
	var a_mouse_direction = Vector2(0, cos(vangle.y) * cos(d_theta))
	var a_mouse = -mouse_acceleration.length() * a_mouse_direction / radius
	var a_gravity = -gravity * Vector2(0, sin(vangle.y)) / radius
	var a_friction = -friction * vangular_velocity
	vangular_acceleration = a_gravity + a_friction + a_mouse
	vangular_velocity += vangular_acceleration * delta
	vangle += vangular_velocity * delta
	
	var clamp_factor = Vector2(1, pow(1.01, -pow(vangle.y, 6)))
	if sign(vangle.y) == sign(vangular_acceleration.y):
		vangular_acceleration *= clamp_factor
	if sign(vangle.y) == sign(vangular_velocity.y):
		vangular_velocity *= clamp_factor
	vangle.y = clamp(vangle.y, -PI / 2, PI / 2)
	
	var x = radius * cos(vangle.x) * sin(vangle.y)
	var y = radius * sin(vangle.x) * sin(vangle.y)
	mass_pos = mouse_pos + Vector2(x, y)
	pass


func _update_physics3(delta) -> void:
	var a_mouse = mouse_acceleration.x * cos(angle) / radius
	var a_gravity = -gravity * sin(angle) / radius
	var a_friction = -friction * angular_velocity
	angular_acceleration = a_gravity + a_friction + a_mouse
	angular_velocity += angular_acceleration * delta
	angle = clamp(angle + angular_velocity * delta, -PI / 2, PI / 2)
	
	#var clamp_factor = max(0, -pow(abs(PI * angle / 4), 10) + 1)
	var clamp_factor = pow(1.01, -pow(angle, 6))
	#var clamp_factor = clamp(-abs(angle) + 2, 0, 1)
	if sign(angle) == sign(angular_acceleration):
		angular_acceleration *= clamp_factor
	if sign(angle) == sign(angular_velocity):
		angular_velocity *= clamp_factor
	
	mass_pos = mouse_pos + Vector2.DOWN.rotated(angle) * radius
	pass


func _update_physics2(delta) -> void:
	var direction = mass_pos.direction_to(mouse_pos)
	var gravitation = direction * gravity
	a_mass = gravitation - v_mass * dampening
	v_mass = v_mass + a_mass * delta
	mass_pos = mass_pos + v_mass * delta
	var distance = mass_pos.distance_to(mouse_pos)
	if distance > radius:
		var last_direction = last_mass_pos.direction_to(mouse_pos)
		mass_pos = mouse_pos - last_direction * radius
		v_mass = Input.get_last_mouse_velocity()
	if distance < 0.5 and v_mass.length() < 100.0:
		mass_pos = mouse_pos
	pass


func _update_physics(delta) -> void:
	if not mouse_pos.is_equal_approx(last_mouse_pos):
		angular_velocity -= (mouse_pos.x - last_mouse_pos.x) / radius
	angular_acceleration = -gravity * sin(angle) / radius
	angular_velocity += angular_acceleration * delta
	angle += angular_velocity * delta
	mass_pos.x = radius * sin(angle)
	mass_pos.y = radius * cos(angle)
	pass


func _update_mouse_velocity(delta) -> void:
	var frame_velocity = (mouse_pos - last_mouse_pos) / delta # pixels/second
	velocity_queue.push_front(frame_velocity)
	while velocity_queue.size() > velocity_weights.size():
		velocity_queue.pop_back()
	var total_weight = 0.0
	var total_velocity = Vector2.ZERO
	for i in range(velocity_queue.size()):
		var weight = velocity_weights.get(i)
		total_velocity += velocity_queue.get(i) * weight
		total_weight += weight
	mouse_velocity = total_velocity / total_weight
	pass


func _on_timer_timeout() -> void:
	_update_label()
	pass
