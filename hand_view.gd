extends Node2D
class_name HandView

enum State {
	WAIT_ANIM,
	WAIT_PLAYER
}

const preferred_arc_length = PI * 60
const min_card_arc_length = PI * 15
const max_hand_arc_length = PI * 330
const arc_radius = 4000.0
const max_drift_dist = 30.0
const aim_dist_threshold = 300.0
const aim_hand_y = 540
const field_aim_y = 1080.0 * 3 / 5

const hover_up = preferred_arc_length / 5
const preferred_card_angle = preferred_arc_length / arc_radius
const max_arc_angle = max_hand_arc_length / arc_radius
const min_card_angle = min_card_arc_length / arc_radius

var state: State = State.WAIT_ANIM
var valid_target: bool = false
var veil_tween: Tween = null
var hovered_cards: Array[CardView] = []
var aiming_card: CardView = null
var examining_card: CardView = null
var aim_dist: float = 0.0


func _ready() -> void:
	await get_tree().root.ready
	var i = 0
	for card in GameState.deck:
		card = _initialize_card(card)
		card.modulate = Color(i / (GameState.starting_draw - 1.0), 0.4, 0.6)
		i += 1
	$Veil.z_index = GameState.deck.size() * 3 + 1
	$Veil.color = Color(Color.BLACK, 0.0)
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
	var str_examining = "Examining Card: " + str(examining_card)
	var str_veil_z = "Veil Z: " + str($Veil.z_index)
	var max_card_z = 0
	for card in GameState.deck:
		max_card_z = max(max_card_z, card.z_index)
	var str_max_card_z = "Max Card Z: " + str(max_card_z)
	SessionState.debug_text = str_state + "\n" \
	+ str_hand + "\n" \
	+ str_hovering + "\n" \
	+ str_aiming + "\n" \
	+ str_examining + "\n" \
	+ str_veil_z + ", " + str_max_card_z
	pass


func _physics_process(_delta: float) -> void:
	if state == State.WAIT_ANIM:
		return
	_reposition_aiming_card()
	for card in $HandPile.pile:
		if card == examining_card or card == aiming_card:
			continue
		if card in hovered_cards:
			card.state = CardView.State.HOVER
		else:
			card.state = CardView.State.HAND
	if Input.is_action_just_pressed("mouse_left"):
		if examining_card != null:
			stop_examine_card()
		elif not hovered_cards.is_empty():
			var recent_hovered_card = hovered_cards.back()
			if recent_hovered_card.state == CardView.State.HOVER:
				aiming_card = recent_hovered_card
				aiming_card.state = CardView.State.AIM
	if Input.is_action_just_released("mouse_left"):
		if aiming_card != null:
			if valid_target:
				play_card(aiming_card)
			else:
				state = State.WAIT_PLAYER
			aiming_card = null
	if Input.is_action_just_pressed("mouse_right"):
		if examining_card != null:
			stop_examine_card()
		elif aiming_card != null:
			aiming_card = null
			state = State.WAIT_PLAYER
		elif state == State.WAIT_PLAYER:
			if not hovered_cards.is_empty():
				var recent_hovered_card = hovered_cards.back()
				if recent_hovered_card.state == CardView.State.HOVER:
					start_examine_card(recent_hovered_card)
	valid_target = _get_valid_target()
	pass


func _draw() -> void:
	if aiming_card != null:
		var mouse_pos = get_local_mouse_position()
		draw_circle(mouse_pos, 5.0, Color.RED, true, -1.0, true)
		draw_line(Vector2(0, field_aim_y), Vector2(1920, field_aim_y), Color.RED, -1.0, true)
	pass


func do_starting_draw() -> void:
	state = State.WAIT_ANIM
	var draw_tween = create_tween()
	draw_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		draw_tween.tween_callback(draw_card).set_delay(0.1)
	draw_tween.tween_property(self, "state", State.WAIT_PLAYER, 0)
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
	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_callback($HandPile.remove_card.bind(card))
	tween.tween_property(card, "state", CardView.State.DISCARD, 0).set_delay(0.7)
	tween.tween_callback($DiscardPile.add_to_top.bind(card))
	tween.tween_callback(_reposition_hand)
	tween.tween_property(self, "state", State.WAIT_PLAYER, 0)
	pass


func start_examine_card(card: CardView) -> void:
	examining_card = card
	card.state = CardView.State.EXAMINE
	$Veil.mouse_filter = Control.MouseFilter.MOUSE_FILTER_STOP
	veil_tween = create_tween()
	veil_tween.tween_property($Veil, "color", Color(Color.BLACK, 0.8), 0.2)
	pass


func stop_examine_card() -> void:
	examining_card = null
	veil_tween = create_tween()
	veil_tween.tween_property($Veil, "color", Color(Color.BLACK, 0.0), 0.2)
	veil_tween.set_parallel(false)
	veil_tween.tween_property($Veil, "mouse_filter", Control.MouseFilter.MOUSE_FILTER_IGNORE, 0)
	pass


func _on_mouse_entered_card(card: CardView) -> void:
	if state == State.WAIT_ANIM:
		return
	hovered_cards.append(card)
	pass


func _on_mouse_exited_card(card: CardView) -> void:
	hovered_cards.erase(card)
	pass


func _get_valid_target() -> bool:
	if not hovered_cards.is_empty() and hovered_cards.back() != aiming_card:
		return true
	if get_global_mouse_position().y < field_aim_y:
		return true
	return false


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
		"global_position": get_viewport_rect().get_center() + Vector2.UP * hover_up,
		"global_rotation": 0,
		"scale": 1.5,
		"z_index": GameState.deck.size() * 3 + 2
	})
	$DrawPile.add_to_top(card)
	card.state = CardView.State.DRAW
	card.z_index = $DrawPile.size()
	return card


func _reposition_aiming_card() -> void:
	if aiming_card == null:
		aim_dist = 0.0
		return
	var hover_data = aiming_card.get_state_pos_data(CardView.State.HOVER)
	var aim_data = hover_data.duplicate(true)
	var card_to_mouse = get_global_mouse_position() - hover_data.global_position
	aim_dist = card_to_mouse.length()
	if not hovered_cards.is_empty() and hovered_cards.back() != aiming_card:
		aim_data.global_position += Vector2(card_to_mouse.x / 2, -aim_hand_y)
	else:
		var card_drift = card_to_mouse.normalized() * min(max_drift_dist, aim_dist)
		aim_data.global_position = hover_data.global_position + card_drift
	aiming_card.set_state_pos_data(CardView.State.AIM, aim_data)
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
