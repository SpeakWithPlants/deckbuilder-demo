extends Marker2D
class_name CardPile

@export var pile: Array[CardView] = []


func add_to_front(card: CardView) -> void:
	pile.push_front(card)
	pass


func add_to_back(card: CardView) -> void:
	pile.push_back(card)
	pass


func draw_from_top() -> CardView:
	return pile.pop_front()


func pull_card(hand_idx: int) -> CardView:
	return pile.pop_at(hand_idx)


func size() -> int:
	return pile.size()
