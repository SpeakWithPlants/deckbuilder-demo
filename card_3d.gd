extends Node3D

const max_rotation = PI / 24
const hover_easing = -5.0
const hover_speed = 0.05
const camera_default_pos = Vector3(0.0, 0.2, 13.0)
const camera_examine_pos = Vector3(0.0, 0.0, 13.0)
const anim_trans_time = 0.45

var mouseover_tween: Tween

var hovering = false
var hover_pos = Vector2.ZERO
var corner_pos: Array[Vector2] = []
var proj_pos = Vector2.ZERO
var proj_size = Vector2.ZERO


func enter_state(state: String) -> void:
	if state == "idle":
		_tween_camera_to(camera_default_pos, anim_trans_time)
		$AnimationPlayer.play("RESET")
	elif state == "examine":
		_tween_camera_to(camera_examine_pos, anim_trans_time)
		$AnimationPlayer.play("examine_oscillate")
	pass


func _tween_camera_to(pos: Vector3, delta_time: float) -> void:
	if mouseover_tween != null:
		mouseover_tween.kill()
	mouseover_tween = create_tween()
	mouseover_tween.set_trans(Tween.TRANS_ELASTIC)
	mouseover_tween.set_ease(Tween.EASE_OUT)
	mouseover_tween.tween_property($Camera, "position", pos, delta_time)
	pass


#func _process_mouse_hover_rotation():
	#var mouse_pos = get_viewport().get_mouse_position()
	#var half_size = proj_size / 2
	#var hover_x = clamp(mouse_pos.x - proj_pos.x, -half_size.x, half_size.x)
	#var hover_y = clamp(mouse_pos.y - proj_pos.y, half_size.y, -half_size.y)
	#hover_pos = Vector2(hover_x, hover_y)
	#var tilt_factor_x = inverse_lerp(0, half_size.x, hover_x)
	#var tilt_factor_y = inverse_lerp(0, -half_size.y, hover_y)
	#$RotationContainer.rotation.y = _ease_tilt(tilt_factor_x) * max_rotation
	#$RotationContainer.rotation.x = _ease_tilt(tilt_factor_y) * max_rotation
	#pass


#func _set_corners_in_camera():
	#var pos = $MouseArea/CollisionShape3D.global_position
	#var unproj_pos = $Camera.unproject_position(pos)
	#proj_pos = Vector2(unproj_pos.x, unproj_pos.y)
	#
	#var size = ($MouseArea/CollisionShape3D.shape as BoxShape3D).size
	#var a = pos + size / 2
	#var b = Vector3(-a.x, a.y, a.z)
	#var c = Vector3(a.x, -a.y, a.z)
	#var top_right = $Camera.unproject_position(a)
	#var top_left = $Camera.unproject_position(b)
	#var bottom_right = $Camera.unproject_position(c)
	#proj_size = Vector2(top_right.x - top_left.x, top_right.y - bottom_right.y)
	#pass


#func _ease_tilt(tilt_factor: float) -> float:
	#var normalized = (tilt_factor * hover_speed + 1) / 2
	#var eased = ease(normalized, hover_easing)
	#return (eased * 2) - 1
