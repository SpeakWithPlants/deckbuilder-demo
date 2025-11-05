extends Component2D
class_name CardTarget

signal mouse_entered(object)
signal mouse_exited(object)

@export var sprites: Array[Sprite2D] = []

var hovered_last_frame: bool = false


func _ready() -> void:
	if not get_tree().root.is_node_ready():
		await get_tree().root.ready
	SessionState.hand_view.register_target(get_parent(), self)
	pass


func _process(_delta: float) -> void:
	var hovered_this_frame = false
	for sprite in sprites:
		if sprite == null:
			continue
		var mouse_pos = sprite.get_local_mouse_position()
		var rect = sprite.get_rect()
		if rect.has_point(mouse_pos) and sprite.is_pixel_opaque(mouse_pos):
			hovered_this_frame = true
			break
	if hovered_this_frame and not hovered_last_frame:
		emit_signal("mouse_entered")
	elif not hovered_this_frame and hovered_last_frame:
		emit_signal("mouse_exited")
	hovered_last_frame = hovered_this_frame
	pass
