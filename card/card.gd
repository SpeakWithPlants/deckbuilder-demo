@tool
@icon("res://card.png")
extends Node2D
class_name Card

enum State {
	DRAW,
	HAND,
	HOVER,
	AIM,
	ACTIVATE,
	DISCARD,
	EXAMINE
}

enum AimingStyle {
	FROM_HAND,
	ANYWHERE
}

const move_duration = 0.5
const aim_move_duration = 0.3
const hover_scale = 1.2
const anim_trans_time = 0.45

const radius: float = 300.0
const gravity: float = 50000.0
const friction: float = 5.0
const time_constant: float = 0.2
const max_rotation: Vector2 = Vector2(0.6, 1.0) * PI / 3

@export var aiming_style: AimingStyle = AimingStyle.FROM_HAND
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

var face_down: bool = false
var move_tween: Tween = null
var state: State = State.DRAW:
	set(value):
		if state == value:
			return
		if value == State.AIM:
			var pos_data = get_state_pos_data(State.AIM)
			destination_pos = pos_data.global_position
			mass_pos = pos_data.global_position
		state = value
		reposition()
		enter_state(value)
var state_pos_data: Dictionary = {}

var destination_pos = null
var mass_pos: Vector2 = Vector2(1920, 1080) / 2
var acceleration: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var rotation_tween: Tween = null
var rotation_scale: Vector3 = Vector3(PI, PI, PI / 2) / 100
var angular_velocity: Vector3 = Vector3.ONE * 0.1
var angular_acceleration: float = 100.0
var clamp_rotation: Vector3 = Vector3.ONE * PI / 2
var camera_tween: Tween
var camera_default_pos = Vector3(0.0, 0.2, 0.0)
var camera_examine_pos = Vector3(0.0, 0.0, 0.0)
var velocity_2d: Vector2 = Vector2.ZERO
var last_target_rotation: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO

@onready var rotator_3d = %RotationContainer
@onready var mouse_area = $MouseArea


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	camera_default_pos.z = %Camera3D.position.z
	camera_examine_pos.z = %Camera3D.position.z
	pass


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_physics_sim(delta)
	pass


func is_valid_target(target: Node2D) -> bool:
	if aiming_style == AimingStyle.ANYWHERE:
		return true
	return _validate_target(target)


func activate(tween: Tween, target: Node2D) -> void:
	_play_activate_animation(tween, target)
	pass


func get_state_pos_data(card_state: State) -> Dictionary:
	return state_pos_data.get(card_state)


func set_state_pos_data(card_state: State, pos_data: Dictionary):
	state_pos_data[card_state] = pos_data
	pass


func reposition() -> void:
	var pos_data = state_pos_data.get(state)
	if pos_data != null:
		var pos = pos_data.get("global_position")
		var rot = pos_data.get("global_rotation")
		var scl = pos_data.get("scale")
		var z = pos_data.get("z_index")
		_tween_to(pos, rot, scl, z)
	pass


func enter_state(new_state: Card.State) -> void:
	if new_state == Card.State.EXAMINE:
		_tween_camera_to(camera_examine_pos, anim_trans_time)
		%AnimationPlayer.play("examine_oscillate")
	else:
		_tween_camera_to(camera_default_pos, anim_trans_time)
		%AnimationPlayer.play("RESET")
	pass


func _tween_camera_to(pos: Vector3, delta_time: float) -> void:
	if camera_tween != null:
		camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.set_trans(Tween.TRANS_ELASTIC)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(%Camera3D, "position", pos, delta_time)
	pass


func _tween_to(pos: Vector2, rot = null, scl = null, z = null) -> void:
	if move_tween != null:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.set_trans(Tween.TRANS_EXPO)
	move_tween.set_parallel()
	var duration = move_duration
	if state == State.AIM:
		duration = aim_move_duration
	if pos != null:
		destination_pos = pos
		move_tween.tween_property(self, "global_position", pos, duration)
	if rot != null:
		move_tween.tween_property(self, "global_rotation", rot, duration)
	if z != null:
		move_tween.tween_property(self, "z_index", z, 0)
	if scl != null:
		if scale.x < scl:
			move_tween.set_trans(Tween.TRANS_ELASTIC)
		move_tween.tween_property(self, "scale", Vector2.ONE * scl, duration * 1.5)
	pass


func _update_physics_sim(delta) -> void:
	if not (state in [State.AIM, State.EXAMINE]):
		# soft-reset physics if the card is not being moved by the player
		mass_pos = destination_pos
	if destination_pos == null:
		return
	
	# update simulated pendulum physics
	var local_mass_pos = mass_pos - destination_pos
	var a_direction = local_mass_pos.normalized()
	var mass_distance = local_mass_pos.length()
	var mass_z = 0.0
	var phi
	if mass_distance >= radius:
		local_mass_pos = a_direction * radius
		phi = PI / 2
	else:
		mass_z = sqrt(pow(radius, 2) - pow(local_mass_pos.x, 2) - pow(local_mass_pos.y, 2))
		phi = acos(mass_z / radius)
	var a_gravity = -gravity * a_direction * sin(phi) * max(1, mass_distance / radius)
	var a_friction = -friction * velocity
	
	acceleration = a_gravity + a_friction
	velocity += acceleration * delta
	mass_pos += velocity * delta
	
	var new_local_mass_pos = mass_pos - destination_pos
	var new_distance = new_local_mass_pos.length()
	if new_distance >= radius:
		mass_pos = destination_pos + new_local_mass_pos.limit_length(radius)

	# update 3D rotation
	var pos = mass_pos - destination_pos
	var rot = Vector3.ZERO
	rot.x = max_rotation.x * _smooth_rotation(pos.y / radius)
	rot.y = max_rotation.y * _smooth_rotation(pos.x / radius)
	rot.z = -rot.y / 3
	if rotation_tween != null:
		rotation_tween.kill()
	rotation_tween = create_tween()
	rotation_tween.tween_property(rotator_3d, "rotation", rot, time_constant)
	pass


func _smooth_rotation(rot: float) -> float:
	return (2 / (1 + pow(2, 4 * rot)) - 1)


func _validate_target(target: Node2D) -> bool:
	# Default behavior, this should be overridden depending on the card
	return target != null


func _play_activate_animation(tween: Tween, _target: Node2D) -> void:
	# Default behavior, this should be overridden depending on the card
	tween.tween_interval(0.7)
	pass
