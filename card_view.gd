extends Node2D


@onready var card = $SubViewport/Card3D
@onready var click_drag_component = $ClickAndDraggable


func _ready() -> void:
	$MouseArea.mouse_entered.connect(_on_mouse_entered)
	$MouseArea.mouse_exited.connect(_on_mouse_exited)
	pass


func _on_mouse_entered():
	if SessionState.drag_target != null:
		return # ignore mouse signals if something is being dragged
	card.on_mouse_entered_anim()
	pass


func _on_mouse_exited():
	if SessionState.drag_target != null:
		return # ignore mouse signals if something is being dragged
	card.on_mouse_exited_anim()
	pass
