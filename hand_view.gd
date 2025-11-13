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
const max_drift_dist = 20.0
const aim_hand_y = 540

const hover_up = preferred_arc_length / 5
const preferred_card_angle = preferred_arc_length / arc_radius
const max_arc_angle = max_hand_arc_length / arc_radius
const min_card_angle = min_card_arc_length / arc_radius

var state: State = State.WAIT_ANIM
var hovered_targets: Array[Node2D] = []
var valid_target: Node2D = null
var veil_tween: Tween = null
var hovered_cards: Array[CardView] = []
var aiming_card: CardView = null
var examining_card: CardView = null

var r = INF

@onready var hand_pile = $HandPile
@onready var hand_rect = $ReferenceRect


func _ready() -> void:
	SessionState.hand_view = self
	await get_tree().root.ready
	var i = 0
	for card in GameState.deck:
		card = _initialize_card(card)
		card.modulate = Color(i / (GameState.starting_draw - 1.0), 0.4, 0.6)
		if i % 2 == 0:
			card.modulate = Color.WHITE
			card.aiming_style = CardView.AimingStyle.ANYWHERE
		i += 1
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


func _update_debug() -> void:
	var str_state = "State: " + State.keys()[state]
	var str_hand = "Hand: " + str(hand_pile.size())
	var str_hovering = "Hovering: " + str(hovered_cards.size())
	var str_aiming = "Aiming Card: " + str(aiming_card)
	var str_examining = "Examining Card: " + str(examining_card)
	var str_target = "Valid Target: " + str(valid_target)
	var str_mouse_pos = "Mouse Position: " + str(get_global_mouse_position())
	if aiming_card != null:
		r = aiming_card.aim_velocity.x
	var str_card_debug = "Card Debug: (%.1f)" % [r]
	SessionState.debug_text = str_state + "\n" \
	+ str_hand + "\n" \
	+ str_hovering + "\n" \
	+ str_aiming + "\n" \
	+ str_examining + "\n" \
	+ str_target + "\n" \
	+ str_mouse_pos + "\n" \
	+ str_card_debug
	queue_redraw()
	pass


func _draw() -> void:
	if aiming_card != null:
		var aim_data = aiming_card.get_state_pos_data(CardView.State.AIM)
		var dot_pos = Vector2(aim_data.global_position.x, 20.0)
		draw_circle(dot_pos, 5.0, Color.RED, true, -1.0, true)
	pass


func _process(_delta: float) -> void:
	_update_debug()
	if state == State.WAIT_ANIM:
		return
	_update_valid_target()
	_update_hand()
	if Input.is_action_just_pressed("mouse_left"):
		if examining_card != null:
			stop_examine_card()
		elif not hovered_cards.is_empty():
			var recent_hovered_card = hovered_cards.back()
			if recent_hovered_card.state == CardView.State.HOVER:
				aiming_card = recent_hovered_card
				_reposition_aiming_card()
				aiming_card.state = CardView.State.AIM
	if Input.is_action_just_released("mouse_left"):
		if aiming_card != null:
			if valid_target != null:
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
	_reposition_aiming_card()
	pass


func register_target(target: Node2D, card_target: CardTarget) -> void:
	card_target.mouse_entered.connect(hovered_targets.append.bind(target))
	card_target.mouse_exited.connect(hovered_targets.erase.bind(target))
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
	hand_pile.add_to_bottom(card)
	card.state = CardView.State.HAND
	_reposition_hand()
	pass


func play_card(card: CardView) -> void:
	state = State.WAIT_ANIM
	var tween = create_tween()
	tween.set_parallel(false)
	card.activate(tween, valid_target)
	tween.tween_property(card, "state", CardView.State.DISCARD, 0)
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


func _update_valid_target() -> void:
	if aiming_card == null:
		valid_target = null
		return
	var mouse_pos = get_global_mouse_position()
	if aiming_card.aiming_style == CardView.AimingStyle.ANYWHERE:
		if not hand_rect.get_rect().has_point(mouse_pos):
			valid_target = SessionState.level_view
		else:
			valid_target = null
		return
	if not hovered_cards.is_empty() and hovered_cards.back() != aiming_card:
		var hovered_card = hovered_cards.back()
		if hovered_card.get_parent() == $HandPile and aiming_card.is_valid_target(hovered_card):
			valid_target = hovered_card
			return
	if not hovered_targets.is_empty():
		var hovered_target = hovered_targets.back()
		if aiming_card.is_valid_target(hovered_target):
			valid_target = hovered_target
			return
	valid_target = null
	pass


func _update_hand() -> void:
	for card in hand_pile.get_children():
		if card == examining_card or card == aiming_card:
			continue
		if aiming_card != null and aiming_card.aiming_style == CardView.AimingStyle.ANYWHERE:
			continue
		if examining_card != null:
			card.state = CardView.State.HAND
		elif card in hovered_cards and (card == valid_target or aiming_card == null):
			card.state = CardView.State.HOVER
		else:
			card.state = CardView.State.HAND
	pass


func _initialize_card(card: CardView) -> CardView:
	card.global_position = $DrawPile.global_position
	add_child(card)
	card.set_state_pos_data(CardView.State.DRAW, {
		"global_position": $DrawPile.global_position,
		"global_rotation": $DrawPile.global_rotation,
		"scale": 1.0,
		"z_index": 0
	})
	card.set_state_pos_data(CardView.State.DISCARD, {
		"global_position": $DiscardPile.global_position,
		"global_rotation": $DiscardPile.global_rotation,
		"scale": 1.0,
		"z_index": 0
	})
	card.set_state_pos_data(CardView.State.EXAMINE, {
		"global_position": get_viewport_rect().get_center() + Vector2.UP * hover_up,
		"global_rotation": 0,
		"scale": 1.5,
		"z_index": 2
	})
	$DrawPile.add_to_top(card)
	card.state = CardView.State.DRAW
	card.z_index = $DrawPile.size()
	return card


func _reposition_aiming_card() -> void:
	if aiming_card == null:
		return
	var hover_data = aiming_card.get_state_pos_data(CardView.State.HOVER)
	var aim_data = hover_data.duplicate(true)
	var mouse_pos = get_global_mouse_position()
	var card_to_mouse = mouse_pos - hover_data.global_position
	var aim_dist = card_to_mouse.length()
	var card_drift = card_to_mouse.normalized() * min(max_drift_dist, aim_dist)
	aim_data.global_position = hover_data.global_position + card_drift
	if aiming_card.aiming_style == CardView.AimingStyle.ANYWHERE:
		if not hand_rect.get_rect().has_point(mouse_pos):
			aim_data.global_position = mouse_pos
	elif valid_target is CardView:
		aim_data.global_position += Vector2(card_to_mouse.x / 2, -aim_hand_y)
	aiming_card.set_state_pos_data(CardView.State.AIM, aim_data)
	aiming_card.reposition()
	pass


func _reposition_hand() -> void:
	var hand_size = hand_pile.size()
	var preferred_arc_angle = preferred_card_angle * hand_size
	var arc_angle = min(max_arc_angle, preferred_arc_angle)
	var card_angle = max(min_card_angle, arc_angle / hand_size)
	arc_angle = card_angle * (hand_size - 1.0)
	for i in range(hand_size):
		var card = hand_pile.get_child(i)
		var orientation = _get_card_orientation(i, hand_size, arc_angle)
		var hand_data = {
			"global_position": orientation.target_pos,
			"global_rotation": orientation.target_rot,
			"scale": 1.0,
			"z_index": 0
		}
		card.set_state_pos_data(CardView.State.HAND, hand_data)
		var hover_data = {
			"global_position": orientation.target_pos + Vector2.UP * hover_up,
			"global_rotation": 0,
			"scale": CardView.hover_scale,
			"z_index": 1
		}
		card.set_state_pos_data(CardView.State.HOVER, hover_data)
		card.set_state_pos_data(CardView.State.AIM, hover_data)
		card.reposition()
	pass


func _get_card_orientation(hand_idx: int, hand_size: int, arc_angle: float) -> Dictionary:
	var hand_pos = hand_pile.global_position
	if hand_size <= 1:
		return {
			"target_pos": Vector2(hand_pos.x, hand_pos.y),
			"target_rot": 0
		}
	var idx_weight = (hand_idx / (hand_size - 1.0)) * 2.0 - 1.0
	var idx_angle = -(arc_angle / 2) * idx_weight
	var idx_pos_x = arc_radius * sin(idx_angle)
	var idx_pos_y = arc_radius * (1 - cos(idx_angle))
	return {
		"target_pos": hand_pos + Vector2(idx_pos_x, idx_pos_y),
		"target_rot": idx_angle
	}
