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


func shuffle() -> void:
	pile.shuffle()
	_reorder()
	pass


func size() -> int:
	return pile.size()


func _reorder() -> void:
	for i in range(pile.size()):
		var card = pile[i] as CardView
		card.face_down = self.face_down
		var pos_data = {
			"global_position": global_position,
			"global_rotation": global_rotation,
			"scale": 0.6
		}
		card.set_state_pos_data(CardView.CardState.FIELD, pos_data)
		card.pile_idx = i
		card.z_index = GameState.deck.size() * z_index - i
	pass
