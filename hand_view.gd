extends Node2D

const max_separation = Vector2(130.0, 10.0)
const max_hand_size = Vector2(1500.0, 50.0)
const max_card_rotation = PI / 8

var track_this_card = null

func _ready() -> void:
	await get_tree().physics_frame
	var i = 0
	for card in GameState.deck:
		card.global_position = $DrawPile.global_position
		card.modulate = Color(i / (GameState.starting_draw - 1.0), 0.5, 0.5)
		add_child(card)
		$DrawPile.add_to_front(card)
		i += 1
	track_this_card = GameState.deck[GameState.deck.size() - 1]
	await get_tree().create_timer(1.0).timeout
	do_starting_draw()
	await get_tree().create_timer(15.0).timeout
	discard_hand()
	pass


func _process(_delta: float) -> void:
	SessionState.debug_text = str(Time.get_ticks_msec())
	if $DrawPile.size() < 1:
		return
	pass


func do_starting_draw() -> void:
	var draw_tween = create_tween()
	draw_tween.pause()
	draw_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		draw_tween.tween_callback(draw_card).set_delay(1.0)
	draw_tween.play()
	pass


func discard_hand() -> void:
	var discard_tween = create_tween()
	discard_tween.pause()
	discard_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		discard_tween.tween_callback(discard_card).set_delay(0.2)
	discard_tween.play()
	pass


func draw_card() -> void:
	var card = $DrawPile.draw_from_top()
	$HandPile.add_to_back(card)
	_reposition_hand()
	pass


func discard_card() -> void:
	var card = $HandPile.draw_from_top()
	$DiscardPile.add_to_front(card)
	card.target_pos = $DiscardPile.global_position
	card.target_rot = 0
	card.tween_to_target_orientation()
	_reposition_hand()
	pass


func _reposition_hand() -> void:
	var hand_size = $HandPile.size()
	for i in range(hand_size):
		var orientation = _get_card_orientation(i, hand_size)
		$HandPile.pile[i].target_pos = orientation.target_pos
		$HandPile.pile[i].target_rot = orientation.target_rot
	for card in $HandPile.pile:
		card.tween_to_target_orientation()
	pass


func _get_card_orientation(hand_idx: int, hand_size: int) -> Dictionary:
	var hand_pos = $HandPile.global_position
	if hand_size == 1:
		return {
			"target_pos": Vector2(hand_pos.x, hand_pos.y),
			"target_rot": 0
		}
	var idx_weight = (hand_idx / (hand_size - 1.0)) * 2.0 - 1.0
	var hand_width = min(max_hand_size.x, max_separation.x * hand_size)
	var hand_height = min(max_hand_size.y, max_separation.y * hand_size)
	var card_x = idx_weight * hand_width / 2.0
	var card_y = (1.0 - cos(idx_weight * PI / 2.0)) * hand_height
	var card_rot = max_card_rotation * card_x / (max_hand_size.x / 2.0)
	var card_pos = Vector2(card_x + hand_pos.x, card_y + hand_pos.y)
	return {
		"target_pos": card_pos,
		"target_rot": card_rot
	}
