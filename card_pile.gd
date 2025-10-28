extends Marker2D
class_name CardPile

@export var pile: Array[CardView] = []


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


func pull_card(hand_idx: int) -> CardView:
	var card = pile.pop_at(hand_idx)
	_reorder()
	return card


func shuffle() -> void:
	pile.shuffle()
	_reorder()
	pass


func size() -> int:
	return pile.size()


func _reorder() -> void:
	for i in range(pile.size()):
		pile[i].z_index = GameState.deck.size() * z_index - i
	pass
