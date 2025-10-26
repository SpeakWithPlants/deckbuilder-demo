extends Component2D
class_name ClickAndDraggable

@export var mouse_area: Area2D
@export var center_on_pivot: bool = true
@export var drag_pivot: Marker2D

var mouse_hovered
var mouse_offset 

func _ready():
	mouse_area.mouse_entered.connect(_mouse_entered)
	mouse_area.mouse_exited.connect(_mouse_exited)
	pass

func _physics_process(_delta: float) -> void:
	if mouse_hovered and Input.is_action_just_pressed("mouse_left"):
		SessionState.drag_target = get_parent()
		mouse_offset = get_local_mouse_position()
	if SessionState.drag_target == get_parent():
		var mouse_pos = get_global_mouse_position()
		var new_pos
		if center_on_pivot:
			var pivot_pos = _get_pivot_position()
			new_pos = mouse_pos - pivot_pos
		else:
			new_pos = mouse_pos - mouse_offset
		get_parent().global_position = new_pos
	pass


func _get_pivot_position() -> Vector2:
	if drag_pivot != null:
		return drag_pivot.position
	return Vector2.ZERO


func _mouse_entered():
	mouse_hovered = true
	pass

func _mouse_exited():
	mouse_hovered = false
	pass
