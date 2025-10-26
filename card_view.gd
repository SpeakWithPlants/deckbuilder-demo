extends Control


@onready var card = $SubViewportContainer/SubViewport/Card3D


func _process(_delta: float) -> void:
	queue_redraw()
	pass


func _draw() -> void:
	#draw_circle(Vector2.ZERO, 5.0, Color.RED, true, -1.0, true)
	#var half_size = card.proj_size / 2
	#draw_circle(Vector2(-half_size.x, half_size.y), 5.0, Color.RED, true, -1.0, true)
	#draw_circle(Vector2(half_size.x, -half_size.y), 5.0, Color.RED, true, -1.0, true)
	#draw_circle(Vector2(-half_size.x, -half_size.y), 5.0, Color.RED, true, -1.0, true)
	#draw_circle(Vector2(half_size.x, half_size.y), 5.0, Color.RED, true, -1.0, true)
	#draw_circle(card.hover_pos, 5.0, Color.RED, true, -1.0, true)
	pass
