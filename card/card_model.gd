@tool
extends Node3D
class_name CardModel

const anim_trans_time = 0.45
const radius: float = 50.0
const gravity: float = 8000.0
const friction: float = 5.5

@export var title: String = "":
	set(value):
		title = value
		if has_node("%Title"):
			%Title.text = value
@export var cost: int = 0:
	set(value):
		cost = value
		if has_node("%Cost"):
			%Cost.text = str(value)
@export var health: int = 0:
	set(value):
		health = value
		if has_node("%Health"):
			%Health.text = str(value)

@export var aim_diff_vector: Vector2 = Vector2.ZERO

var rotation_scale: Vector3 = Vector3(PI, PI, PI / 2) / 100
var angular_velocity: Vector3 = Vector3.ONE * 0.1
var angular_acceleration: float = 100.0
var clamp_rotation: Vector3 = Vector3.ONE * PI / 2
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
	if Engine.is_editor_hint():
		return
	camera_default_pos.z = $Camera.position.z
	camera_examine_pos.z = $Camera.position.z
	pass


func enter_state(state: Card.State) -> void:
	if state == Card.State.EXAMINE:
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
