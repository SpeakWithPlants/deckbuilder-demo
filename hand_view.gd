extends Node2D

const preferred_arc_length = PI * 60
const min_card_arc_length = PI * 15
const max_hand_arc_length = PI * 330
const arc_radius = 4000.0
const max_drift_dist = 50.0
const aim_dist_threshold = 300.0

const hover_up = preferred_arc_length / 5
const preferred_card_angle = preferred_arc_length / arc_radius
const max_arc_angle = max_hand_arc_length / arc_radius
const min_card_angle = min_card_arc_length / arc_radius

var field_tween: Tween = null
var hovered_cards: Array[CardView] = []
var aiming_card: CardView = null
var aim_dist: float = 0.0


func _ready() -> void:
	$ColorRect.z_index = GameState.deck.size() + 2
	$ColorRect.modulate.a = 0
	await get_tree().root.ready
	var i = 0
	for card in GameState.deck:
		card = _initialize_card(card)
		card.modulate = Color(i / (GameState.starting_draw - 1.0), 0.4, 0.6)
		i += 1
	$DrawPile.shuffle()
	await get_tree().physics_frame
	for card in GameState.deck:
		card.reposition()
		card.mouse_area.connect("mouse_entered", _on_mouse_entered_card.bind(card))
		card.mouse_area.connect("mouse_exited", _on_mouse_exited_card.bind(card))
	await get_tree().create_timer(1.0).timeout
	do_starting_draw()
	pass


func _process(_delta: float) -> void:
	queue_redraw()
	SessionState.debug_text = str(Time.get_ticks_msec())
	pass


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse_left"):
		if not hovered_cards.is_empty():
			aiming_card = hovered_cards.back()
			aiming_card.state = CardView.State.AIM
	if Input.is_action_just_released("mouse_left"):
		if aiming_card != null and aim_dist > aim_dist_threshold:
			play_card(aiming_card)
		else:
			aiming_card.state = CardView.State.HAND
		aiming_card = null
	if Input.is_action_just_pressed("ui_accept"):
		if field_tween != null:
			await field_tween.finished
			field_tween.kill()
		field_tween = create_tween()
		field_tween.set_parallel(false)
		field_tween.tween_callback(discard_hand)
		field_tween.tween_callback(do_starting_draw).set_delay(1.0)
	_reposition_aiming_card()
	pass


func _draw() -> void:
	if aiming_card != null and aim_dist > aim_dist_threshold:
		var mouse_pos = get_local_mouse_position()
		draw_circle(mouse_pos, 5.0, Color.RED, true, -1.0, true)
	pass


func draw_card() -> void:
	if $DrawPile.is_empty():
		return
	var card = $DrawPile.draw_from_top()
	$HandPile.add_to_bottom(card)
	card.state = CardView.State.HAND
	_reposition_hand()
	pass


func discard_card() -> void:
	if $HandPile.is_empty():
		return
	var card = $HandPile.draw_from_top()
	$DiscardPile.add_to_top(card)
	card.state = CardView.State.DISCARD
	_reposition_hand()
	pass


func play_card(card: CardView) -> void:
	# TODO need to run the card's "activation" animation here, for now just discard
	var play_tween = create_tween()
	play_tween.tween_callback($HandPile.remove_card.bind(card))
	play_tween.tween_property(card, "state", CardView.State.DISCARD, 0).set_delay(0.7)
	play_tween.tween_callback($DiscardPile.add_to_top.bind(card))
	play_tween.tween_callback(_reposition_hand)
	pass


func do_starting_draw() -> void:
	var draw_tween = create_tween()
	draw_tween.pause()
	draw_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		draw_tween.tween_callback(draw_card).set_delay(0.1)
	draw_tween.play()
	pass


func discard_hand() -> void:
	var discard_tween = create_tween()
	discard_tween.pause()
	discard_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		discard_tween.tween_callback(discard_card).set_delay(0.1)
	discard_tween.play()
	pass


func _on_mouse_entered_card(card: CardView) -> void:
	if not card.is_interactable():
		return
	hovered_cards.append(card)
	card.state = CardView.State.HOVER
	card.previous_z_index = card.z_index
	card.z_index = GameState.deck.size() + 1
	pass


func _on_mouse_exited_card(card: CardView) -> void:
	if not card.is_interactable():
		return
	hovered_cards.erase(card)
	card.state = CardView.State.HAND
	card.z_index = card.previous_z_index
	pass


func _initialize_card(card: CardView) -> CardView:
	card.global_position = $DrawPile.global_position
	add_child(card)
	card.set_state_pos_data(CardView.State.DRAW, {
		"global_position": $DrawPile.global_position,
		"global_rotation": $DrawPile.global_rotation,
		"scale": 1.0
	})
	card.set_state_pos_data(CardView.State.DISCARD, {
		"global_position": $DiscardPile.global_position,
		"global_rotation": $DiscardPile.global_rotation,
		"scale": 1.0
	})
	card.set_state_pos_data(CardView.State.EXAMINE, {
		"global_position": get_viewport_rect().get_center(),
		"global_rotation": 0,
		"scale": 1.0
	})
	$DrawPile.add_to_top(card)
	card.state = CardView.State.DRAW
	return card


func _reposition_aiming_card() -> void:
	if aiming_card == null:
		aim_dist = 0.0
		return
	var pos_data = aiming_card.get_state_pos_data(CardView.State.HOVER).duplicate(true)
	var mouse_drift = get_global_mouse_position() - pos_data.global_position
	aim_dist = mouse_drift.length()
	mouse_drift = mouse_drift.normalized() * min(max_drift_dist, aim_dist)
	pos_data.global_position = pos_data.global_position + mouse_drift
	aiming_card.set_state_pos_data(CardView.State.AIM, pos_data)
	aiming_card.reposition()
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
		card.set_state_pos_data(CardView.State.HAND, field_data)
		var hover_data = {
			"global_position": orientation.target_pos + Vector2.UP * hover_up,
			"global_rotation": 0,
			"scale": CardView.hover_scale
		}
		card.set_state_pos_data(CardView.State.HOVER, hover_data)
		card.set_state_pos_data(CardView.State.AIM, hover_data)
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
