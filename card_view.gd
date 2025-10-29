extends Node2D
class_name CardView

const move_duration = 0.7
const rotate_duration = move_duration
const hover_scale = 1.2

@export var face_down: bool = false

var pile_idx: int = 0
var hovered: bool = false
var move_tween: Tween = null
var hover_pos: Vector2
var target_pos: Vector2
var target_rot: float
var previous_z_index: int = z_index

#var examine_mode: bool = false

@onready var card = $SubViewport/Card3D
@onready var mouse_area = $MouseArea
@onready var click_drag_component = $ClickAndDraggable


func _ready() -> void:
	$MouseArea.mouse_entered.connect(_on_mouse_entered)
	$MouseArea.mouse_exited.connect(_on_mouse_exited)
	pass


#func _process(_delta: float) -> void:
	#if Input.is_action_just_pressed("mouse_right"):
		#if click_drag_component.mouse_hovered:
			#examine_mode = true
			#click_drag_component.set_enabled(false)
			#card.enter_state("examine")
		#else:
			#examine_mode = false
			#card.enter_state("idle")
			#click_drag_component.set_enabled(true)
	#pass


func tween_to_target_orientation() -> void:
	_tween_to_orientation(target_pos, target_rot, 1.0)
	pass


func tween_to_hover_orientation() -> void:
	_tween_to_orientation(hover_pos, 0, hover_scale)
	pass


func _on_mouse_entered():
	if SessionState.drag_target != null or face_down:
		return # ignore mouse signals if something is being dragged
	hovered = true
	pass


func _on_mouse_exited():
	if SessionState.drag_target != null or face_down:
		return # ignore mouse signals if something is being dragged
	hovered = false
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
		move_tween.tween_property(self, "rotation", rot, move_duration)
	if scl != null:
		move_tween.set_parallel()
		move_tween.tween_property(self, "scale", Vector2.ONE * scl, move_duration)
	pass
