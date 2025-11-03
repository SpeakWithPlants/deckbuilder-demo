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
const hover_scale = 1.2

@export var face_down: bool = false

var move_tween: Tween = null

var state: State = State.DRAW:
	set(value):
		if state == value:
			return
		state = value
		reposition()
		if card != null:
			card.enter_state(value)
var state_pos_data: Dictionary = {}

@onready var card = $SubViewport/Card3D
@onready var mouse_area = $MouseArea


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
		_tween_to_orientation(pos, rot, scl, z)
	pass


func _tween_to_orientation(pos: Vector2, rot = null, scl = null, z = null) -> void:
	if move_tween != null:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.set_trans(Tween.TRANS_EXPO)
	move_tween.set_parallel()
	if pos != null:
		move_tween.tween_property(self, "global_position", pos, move_duration)
	if rot != null:
		move_tween.tween_property(self, "global_rotation", rot, move_duration)
	if scl != null:
		move_tween.tween_property(self, "scale", Vector2.ONE * scl, move_duration)
	if z != null:
		move_tween.tween_property(self, "z_index", z, 0)
	pass
