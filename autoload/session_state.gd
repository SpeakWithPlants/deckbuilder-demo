extends Node


var debug_text: String = ""

var drag_target = null


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_released("mouse_left"):
		drag_target = null
