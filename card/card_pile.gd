extends Marker2D
class_name CardPile

@export var face_down: bool = true


func add_to_top(card: CardView) -> void:
	card.reparent(self)
	card.face_down = self.face_down
	pass


func add_to_bottom(card: CardView) -> void:
	card.reparent(self)
	move_child(card, 0)
	card.face_down = self.face_down
	pass


func draw_from_top() -> CardView:
	return get_children().back()


func shuffle() -> void:
	var indices = range(get_child_count())
	indices.shuffle()
	var original_children = get_children()
	for i in indices:
		var child = original_children[i]
		move_child(child, 0)
	pass


func size() -> int:
	return get_child_count()


func is_empty() -> bool:
	return get_child_count() == 0


func reposition() -> void:
	for card in get_children():
		card.reposition()
	pass
