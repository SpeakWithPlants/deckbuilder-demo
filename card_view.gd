extends Node2D


@onready var card = $SubViewport/Card3D
@onready var click_drag_component = $ClickAndDraggable

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
