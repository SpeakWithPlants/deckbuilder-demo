extends Node2D

var mouse_pos: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var mouse_velocity: Vector2 = Vector2.ZERO
var last_mouse_velocity: Vector2 = Vector2.ZERO
var mouse_acceleration: Vector2 = Vector2.ZERO

var _mouse_velocity_queue: Array[Vector2] = []
var _mouse_velocity_weights: Array[float] = [4, 3, 2, 1]


func _process(delta: float) -> void:
	_update_mouse_motion(delta)
	pass


func _update_mouse_motion(delta: float) -> void:
	last_mouse_pos = mouse_pos
	mouse_pos = get_global_mouse_position()
	mouse_acceleration = (mouse_velocity - last_mouse_velocity) / delta
	last_mouse_velocity = mouse_velocity
	var frame_velocity = (mouse_pos - last_mouse_pos) / delta # pixels/second
	_mouse_velocity_queue.push_front(frame_velocity)
	while _mouse_velocity_queue.size() > _mouse_velocity_weights.size():
		_mouse_velocity_queue.pop_back()
	var total_weight = 0.0
	var total_velocity = Vector2.ZERO
	for i in range(_mouse_velocity_queue.size()):
		var weight = _mouse_velocity_weights.get(i)
		total_velocity += _mouse_velocity_queue.get(i) * weight
		total_weight += weight
	mouse_velocity = total_velocity / total_weight
	pass
