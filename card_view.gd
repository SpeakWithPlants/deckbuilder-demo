extends Node2D
class_name CardView

const move_duration = 0.7
const rotate_duration = move_duration

@onready var card = $SubViewport/Card3D
@onready var click_drag_component = $ClickAndDraggable

var move_tween: Tween = null
var target_pos: Vector2
var target_rot: float

var examine_mode: bool = false


func _ready() -> void:
	$MouseArea.mouse_entered.connect(_on_mouse_entered)
	$MouseArea.mouse_exited.connect(_on_mouse_exited)
	pass


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse_right"):
		if click_drag_component.mouse_hovered:
			examine_mode = true
			click_drag_component.set_enabled(false)
			card.enter_state("examine")
		else:
			examine_mode = false
			card.enter_state("idle")
			click_drag_component.set_enabled(true)
	pass


func tween_to_target_orientation() -> void:
	if move_tween != null:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.set_trans(Tween.TRANS_EXPO)
	if target_pos != null:
		move_tween.tween_property(self, "global_position", target_pos, move_duration)
	if target_rot != null:
		move_tween.set_parallel()
		move_tween.tween_property(self, "rotation", target_rot, move_duration)
	pass


func _on_mouse_entered():
	if SessionState.drag_target != null:
		return # ignore mouse signals if something is being dragged
	card.enter_state("mouseover")
	pass


func _on_mouse_exited():
	if SessionState.drag_target != null or examine_mode:
		return # ignore mouse signals if something is being dragged
	card.enter_state("idle")
	pass
