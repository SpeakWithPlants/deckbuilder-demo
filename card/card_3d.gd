extends Node3D

const anim_trans_time = 0.45
const radius: float = 50.0
const gravity: float = 8000.0
const friction: float = 5.5

@export var aim_diff_vector: Vector2 = Vector2.ZERO

var rotation_scale: Vector3 = Vector3(PI, PI, PI / 2) / 100
var angular_velocity: Vector3 = Vector3.ONE * 0.1
var angular_acceleration: float = 100.0
var clamp_rotation: Vector3 = Vector3.ONE * PI / 2
var rotation_tween: Tween
var last_target_rotation: Vector3 = Vector3.ZERO
var camera_tween: Tween
var camera_default_pos = Vector3(0.0, 0.2, 0.0)
var camera_examine_pos = Vector3(0.0, 0.0, 0.0)
var velocity_2d: Vector2 = Vector2.ZERO

var target_rotation: Vector3 = Vector3.ZERO

var mass_pos: Vector2 = Vector2(1920, 1080) / 2
var last_mass_pos: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	get_parent().own_world_3d = true
	camera_default_pos.z = $Camera.position.z
	camera_examine_pos.z = $Camera.position.z
	pass


func _process(delta: float) -> void:
	if rotation_tween != null:
		rotation_tween.kill()
	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_OUT)
	rotation_tween.set_trans(Tween.TRANS_ELASTIC)
	rotation_tween.tween_property($RotationContainer, "global_rotation", target_rotation, 0.5)
	pass


func enter_state(state: CardView.State) -> void:
	if state == CardView.State.EXAMINE:
		_tween_camera_to(camera_examine_pos, anim_trans_time)
		$AnimationPlayer.play("examine_oscillate")
	else:
		_tween_camera_to(camera_default_pos, anim_trans_time)
		$AnimationPlayer.play("RESET")
	pass


func _tween_camera_to(pos: Vector3, delta_time: float) -> void:
	if camera_tween != null:
		camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.set_trans(Tween.TRANS_ELASTIC)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.tween_property($Camera, "position", pos, delta_time)
	pass
