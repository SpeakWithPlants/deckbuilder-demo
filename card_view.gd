extends Node2D
class_name CardView

# 'FIELD' is the current passive position of the card, usually a card pile (hand, draw, or discard)
# 'HOVER' is the card's position while the mouse is hovering over it
# 'HOLD' is the card's position while the mouse is dragging it (highest priority)
enum CardState {
	FIELD,
	HOVER,
	HOLD,
	EXAMINE
}

const move_duration = 0.7
const rotate_duration = move_duration
const hover_scale = 1.2

@export var interactable: bool = false
@export var face_down: bool = false

var pile_idx: int = 0
var move_tween: Tween = null
var hover_pos: Vector2
var target_pos: Vector2
var target_rot: float
var previous_z_index: int = z_index

var state: CardState = CardState.FIELD:
	set(value):
		state = value
		reposition()
var pos_queue: Dictionary = {}

@onready var card = $SubViewport/Card3D
@onready var mouse_area = $MouseArea


func reposition() -> void:
	var pos_data = pos_queue[state]
	if pos_data != null:
		var pos = pos_data.get("global_position")
		var rot = pos_data.get("global_rotation")
		var scl = pos_data.get("scale")
		_tween_to_orientation(pos, rot, scl)
	pass


func set_state_pos_data(card_state: CardState, pos_data: Dictionary):
	pos_queue[card_state] = pos_data
	pass


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
