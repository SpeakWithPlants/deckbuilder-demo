extends Node2D
class_name HandView

enum State {
	WAIT_ANIM,
	WAIT_PLAYER,
	AIMING,
}

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

var state: State = State.WAIT_ANIM
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
	var str_state = "State: " + State.keys()[state]
	var str_hand = "Hand: " + str($HandPile.size())
	var str_hovering = "Hovering: " + str(hovered_cards.size())
	var str_aiming = "Aiming Card: " + str(aiming_card)
	SessionState.debug_text = str_state + "\n" \
	+ str_hand + "\n" \
	+ str_hovering + "\n" \
	+ str_aiming
	pass


func _physics_process(_delta: float) -> void:
	if state == State.WAIT_ANIM:
		return
	for card in $HandPile.pile:
		if card == aiming_card:
			_reposition_aiming_card()
			continue
		if card in hovered_cards:
			card.state = CardView.State.HOVER
		else:
			card.state = CardView.State.HAND
	if Input.is_action_just_pressed("mouse_left"):
		if not hovered_cards.is_empty():
			var recent_hovered_card = hovered_cards.back()
			if recent_hovered_card.state == CardView.State.HOVER:
				aiming_card = recent_hovered_card
				aiming_card.state = CardView.State.AIM
	if Input.is_action_just_released("mouse_left"):
		if aiming_card != null and aim_dist > aim_dist_threshold:
			play_card(aiming_card)
		aiming_card = null
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


func play_card(card: CardView) -> void:
	state = State.WAIT_ANIM
	# TODO need to run the card's "activation" animation here, for now just discard after a
	# short delay
	var play_tween = create_tween()
	play_tween.set_parallel(false)
	play_tween.tween_callback($HandPile.remove_card.bind(card))
	play_tween.tween_property(card, "state", CardView.State.DISCARD, 0).set_delay(0.7)
	play_tween.tween_callback($DiscardPile.add_to_top.bind(card))
	play_tween.tween_callback(_reposition_hand)
	play_tween.tween_property(self, "state", State.WAIT_PLAYER, 0)
	pass


func do_starting_draw() -> void:
	state = State.WAIT_ANIM
	var draw_tween = create_tween()
	draw_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		draw_tween.tween_callback(draw_card).set_delay(0.1)
	draw_tween.tween_property(self, "state", State.WAIT_PLAYER, 0)
	pass


func _on_mouse_entered_card(card: CardView) -> void:
	if state == State.WAIT_ANIM:
		return
	hovered_cards.append(card)
	pass


func _on_mouse_exited_card(card: CardView) -> void:
	hovered_cards.erase(card)
	pass


func _initialize_card(card: CardView) -> CardView:
	card.global_position = $DrawPile.global_position
	add_child(card)
	card.set_state_pos_data(CardView.State.DRAW, {
		"global_position": $DrawPile.global_position,
		"global_rotation": $DrawPile.global_rotation,
		"scale": 1.0,
		"z_index": $DrawPile.z_index
	})
	card.set_state_pos_data(CardView.State.DISCARD, {
		"global_position": $DiscardPile.global_position,
		"global_rotation": $DiscardPile.global_rotation,
		"scale": 1.0,
		"z_index": $DiscardPile.z_index
	})
	card.set_state_pos_data(CardView.State.EXAMINE, {
		"global_position": get_viewport_rect().get_center(),
		"global_rotation": 0,
		"scale": 1.0,
		"z_index": GameState.deck.size() * 3
	})
	$DrawPile.add_to_top(card)
	card.state = CardView.State.DRAW
	card.z_index = $DrawPile.size()
	return card


func _reposition_aiming_card() -> void:
	if aiming_card == null:
		aim_dist = 0.0
		return
	# TODO raise AIM position higher when hovering over another card
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
		var hand_data = {
			"global_position": orientation.target_pos,
			"global_rotation": orientation.target_rot,
			"scale": 1.0,
			"z_index": GameState.deck.size() * $HandPile.z_index - i
		}
		card.set_state_pos_data(CardView.State.HAND, hand_data)
		var hover_data = {
			"global_position": orientation.target_pos + Vector2.UP * hover_up,
			"global_rotation": 0,
			"scale": CardView.hover_scale,
			"z_index": GameState.deck.size() * 2 - i
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
