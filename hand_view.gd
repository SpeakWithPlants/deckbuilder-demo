extends Node2D

const preferred_arc_length = PI * 60
const min_card_arc_length = PI * 11
const max_hand_arc_length = PI * 330
const arc_radius = 4000.0

const preferred_card_angle = preferred_arc_length / arc_radius
const max_arc_angle = max_hand_arc_length / arc_radius
const min_card_angle = min_card_arc_length / arc_radius


func _ready() -> void:
	await get_tree().root.ready
	var i = 0
	for card in GameState.deck:
		card.global_position = $DrawPile.global_position
		card.modulate = Color(i / (GameState.starting_draw - 1.0), 0.5, 0.5)
		add_child(card)
		$DrawPile.add_to_top(card)
		i += 1
	$DrawPile.shuffle()
	await get_tree().create_timer(1.0).timeout
	do_starting_draw()
	pass


func _process(_delta: float) -> void:
	SessionState.debug_text = str(Time.get_ticks_msec())
	if $DrawPile.size() < 1:
		return
	pass


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		discard_hand()
		await get_tree().create_timer(3.0).timeout
		do_starting_draw()
	pass


func do_starting_draw() -> void:
	var draw_tween = create_tween()
	draw_tween.pause()
	draw_tween.set_parallel(false)
	for i in range(GameState.starting_draw):
		draw_tween.tween_callback(draw_card).set_delay(0.2)
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
	card.target_pos = $DiscardPile.global_position
	card.target_rot = 0
	card.tween_to_target_orientation()
	_reposition_hand()
	pass


func _reposition_hand() -> void:
	var hand_size = $HandPile.size()
	var preferred_arc_angle = preferred_card_angle * hand_size
	var arc_angle = min(max_arc_angle, preferred_arc_angle)
	var card_angle = max(min_card_angle, arc_angle / hand_size)
	arc_angle = card_angle * (hand_size - 1.0)
	for i in range(hand_size):
		var orientation = _get_card_orientation(i, hand_size, arc_angle)
		$HandPile.pile[i].target_pos = orientation.target_pos
		$HandPile.pile[i].target_rot = orientation.target_rot
	for card in $HandPile.pile:
		card.tween_to_target_orientation()
	pass


func _get_card_orientation(hand_idx: int, hand_size: int, arc_angle: float) -> Dictionary:
	var hand_pos = $HandPile.global_position
	if hand_size == 1:
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
