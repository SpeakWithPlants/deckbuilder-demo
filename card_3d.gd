extends Node3D

const camera_default_pos = Vector3(0.0, 0.2, 13.0)
const camera_examine_pos = Vector3(0.0, 0.0, 13.0)
const anim_trans_time = 0.45

var camera_tween: Tween


func enter_state(state: String) -> void:
	if state == "idle":
		_tween_camera_to(camera_default_pos, anim_trans_time)
		$AnimationPlayer.play("RESET")
	elif state == "examine":
		_tween_camera_to(camera_examine_pos, anim_trans_time)
		$AnimationPlayer.play("examine_oscillate")
	pass


func _tween_camera_to(pos: Vector3, delta_time: float) -> void:
	if camera_tween != null:
		camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.set_trans(Tween.TRANS_ELASTIC)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.tween_property($Camera, "position", pos, delta_time)
	pass
