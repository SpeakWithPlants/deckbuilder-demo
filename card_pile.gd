extends Marker2D
class_name CardPile

@export var pile: Array[CardView] = []
@export var face_down: bool = true


func add_to_top(card: CardView) -> void:
	pile.push_front(card)
	_reorder()
	pass


func add_to_bottom(card: CardView) -> void:
	pile.push_back(card)
	_reorder()
	pass


func draw_from_top() -> CardView:
	var card = pile.pop_front()
	_reorder()
	return card


func remove_card(card: CardView):
	pile.erase(card)
	_reorder()
	pass


func shuffle() -> void:
	pile.shuffle()
	_reorder()
	pass


func size() -> int:
	return pile.size()


func is_empty() -> bool:
	return pile.is_empty()


func reposition() -> void:
	for card in pile:
		card.reposition()
	pass


func _reorder() -> void:
	for i in range(pile.size()):
		var card = pile[i] as CardView
		card.face_down = self.face_down
		card.pile_idx = i
	pass
