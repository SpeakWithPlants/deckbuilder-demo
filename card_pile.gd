extends Marker2D
class_name CardPile

@export var pile: Array[CardView] = []
@export var face_down: bool = true


func add_to_top(card: CardView) -> void:
	pile.push_front(card)
	card.face_down = self.face_down
	pass


func add_to_bottom(card: CardView) -> void:
	pile.push_back(card)
	card.face_down = self.face_down
	pass


func draw_from_top() -> CardView:
	return pile.pop_front()


func remove_card(card: CardView) -> void:
	pile.erase(card)
	pass


func shuffle() -> void:
	pile.shuffle()
	pass


func size() -> int:
	return pile.size()


func is_empty() -> bool:
	return pile.is_empty()


func reposition() -> void:
	for card in pile:
		card.reposition()
	pass
