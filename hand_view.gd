extends Node2D

const preferred_arc_length = PI * 60
const min_card_arc_length = PI * 15
const max_hand_arc_length = PI * 330
const arc_radius = 4000.0

const hover_up = preferred_arc_length / 5
const preferred_card_angle = preferred_arc_length / arc_radius
const max_arc_angle = max_hand_arc_length / arc_radius
const min_card_angle = min_card_arc_length / arc_radius

var hand_motion: Tween = null
var hovered_cards: Array[CardView] = []
var dragging_card: CardView = null


func _ready() -> void:
	$ColorRect.z_index = GameState.deck.size() + 2
	$ColorRect.modulate.a = 0
	await get_tree().root.ready
	var i = 0
	for card in GameState.deck:
		card.global_position = $DrawPile.global_position
		card.modulate = Color(i / (GameState.starting_draw - 1.0), 0.5, 0.5)
		add_child(card)
		$DrawPile.add_to_top(card)
		i += 1
	await get_tree().physics_frame
	for card in GameState.deck:
		card.mouse_area.connect("mouse_entered", _on_mouse_entered_card.bind(card))
		card.mouse_area.connect("mouse_exited", _on_mouse_exited_card.bind(card))
	$DrawPile.shuffle()
	await get_tree().create_timer(1.0).timeout
	do_starting_draw()
	pass


func _process(_delta: float) -> void:
	queue_redraw()
	SessionState.debug_text = str(Time.get_ticks_msec())
	if $DrawPile.size() < 1:
		return
	pass


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse_left"):
		if not hovered_cards.is_empty():
			dragging_card = hovered_cards.back()
	if Input.is_action_just_released("mouse_left"):
		dragging_card = null
	if Input.is_action_just_pressed("ui_accept"):
		if hand_motion != null:
			await hand_motion.finished
			hand_motion.kill()
		hand_motion = create_tween()
		hand_motion.set_parallel(false)
		hand_motion.tween_callback(discard_hand)
		hand_motion.tween_callback(do_starting_draw).set_delay(1.0)
	pass


func _draw() -> void:
	if dragging_card != null:
		var mouse_pos = get_local_mouse_position()
		draw_circle(mouse_pos, 5.0, Color.RED, true, -1.0, true)
	pass


func do_starting_draw() -> void:
	var draw_tween = create_tween()
	draw_tween.pause()
	draw_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		draw_tween.tween_callback(draw_card).set_delay(0.1)
	draw_tween.tween_callback(_set_interactable.bind($HandPile.pile, true))
	draw_tween.play()
	pass


func discard_hand() -> void:
	var discard_tween = create_tween()
	discard_tween.pause()
	discard_tween.set_parallel(false)
	discard_tween.tween_callback(_set_interactable.bind($HandPile.pile, false))
	for i in range(GameState.starting_draw):
		discard_tween.tween_callback(discard_card).set_delay(0.1)
	discard_tween.play()
	pass


func draw_card() -> void:
	var card = $DrawPile.draw_from_top()
	if card == null:
		return
	$HandPile.add_to_bottom(card)
	_reposition_hand()
	pass


func discard_card() -> void:
	var card = $HandPile.draw_from_top()
	$DiscardPile.add_to_top(card)
	_reposition_hand()
	pass


func _on_mouse_entered_card(card: CardView) -> void:
	if not card.interactable:
		return
	hovered_cards.append(card)
	card.state = CardView.CardState.HOVER
	card.previous_z_index = card.z_index
	card.z_index = GameState.deck.size() + 1
	pass


func _on_mouse_exited_card(card: CardView) -> void:
	if not card.interactable:
		return
	hovered_cards.erase(card)
	card.state = CardView.CardState.FIELD
	card.z_index = card.previous_z_index
	pass


func _set_interactable(cards: Array[CardView], interactable: bool = true):
	for card in cards:
		card.interactable = interactable
	pass


func _reposition_hand() -> void:
	var hand_size = $HandPile.size()
	var preferred_arc_angle = preferred_card_angle * hand_size
	var arc_angle = min(max_arc_angle, preferred_arc_angle)
	var card_angle = max(min_card_angle, arc_angle / hand_size)
	arc_angle = card_angle * (hand_size - 1.0)
	for i in range(hand_size):
		var card = $HandPile.pile[i]
		var orientation = _get_card_orientation(i, hand_size, arc_angle)
		var field_data = {
			"global_position": orientation.target_pos,
			"global_rotation": orientation.target_rot,
			"scale": 1.0
		}
		card.set_state_pos_data(CardView.CardState.FIELD, field_data)
		var hover_data = {
			"global_position": orientation.target_pos + Vector2.UP * hover_up,
			"global_rotation": 0,
			"scale": CardView.hover_scale
		}
		card.set_state_pos_data(CardView.CardState.HOVER, hover_data)
		card.reposition()
	pass


func _get_card_orientation(hand_idx: int, hand_size: int, arc_angle: float) -> Dictionary:
	var hand_pos = $HandPile.global_position
	if hand_size <= 1:
		return {
			"target_pos": Vector2(hand_pos.x, hand_pos.y),
			"target_rot": 0
		}
	var idx_weight = (hand_idx / (hand_size - 1.0)) * 2.0 - 1.0
	var idx_angle = (arc_angle / 2) * idx_weight
	var idx_pos_x = arc_radius * sin(idx_angle)
	var idx_pos_y = arc_radius * (1 - cos(idx_angle))
	return {
		"target_pos": hand_pos + Vector2(idx_pos_x, idx_pos_y),
		"target_rot": idx_angle
	}
