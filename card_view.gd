extends Node2D
class_name CardView

enum State {
	DRAW,
	HAND,
	HOVER,
	AIM,
	ACTIVATE,
	DISCARD,
	EXAMINE
}

const move_duration = 0.7
const rotate_duration = move_duration
const hover_scale = 1.2

@export var face_down: bool = false

var pile_idx: int = 0
var move_tween: Tween = null
var hover_pos: Vector2
var target_pos: Vector2
var target_rot: float
var previous_z_index: int = z_index

var state: State = State.DRAW:
	set(value):
		state = value
		reposition()
var pos_queue: Dictionary = {}

@onready var card = $SubViewport/Card3D
@onready var mouse_area = $MouseArea


func reposition() -> void:
	var pos_data = pos_queue.get(state)
	if pos_data != null:
		var pos = pos_data.get("global_position")
		var rot = pos_data.get("global_rotation")
		var scl = pos_data.get("scale")
		_tween_to_orientation(pos, rot, scl)
	pass


func get_state_pos_data(card_state: State) -> Dictionary:
	return pos_queue.get(card_state)


func set_state_pos_data(card_state: State, pos_data: Dictionary):
	pos_queue[card_state] = pos_data
	pass


func is_interactable() -> bool:
	return state in [State.HAND, State.HOVER]


func tween_to_target_orientation() -> void:
	_tween_to_orientation(target_pos, target_rot, 1.0)
	pass


func tween_to_hover_orientation() -> void:
	_tween_to_orientation(hover_pos, 0, hover_scale)
	pass


func _tween_to_orientation(pos: Vector2, rot = null, scl = null) -> void:
	if move_tween != null:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.set_trans(Tween.TRANS_EXPO)
	if pos != null:
		move_tween.tween_property(self, "global_position", pos, move_duration)
	if rot != null:
		move_tween.set_parallel()
		move_tween.tween_property(self, "global_rotation", rot, move_duration)
	if scl != null:
		move_tween.set_parallel()
		move_tween.tween_property(self, "scale", Vector2.ONE * scl, move_duration)
	pass
