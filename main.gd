extends Control

const card_scene = preload("res://card/card.tscn")


func _ready() -> void:
	_initialize_debug_deck()
	pass


func _process(_delta: float) -> void:
	$DebugLabel.text = SessionState.debug_text
	pass


func _initialize_debug_deck() -> void:
	GameState.deck = []
	for i in range(GameState.starting_draw * 2):
		GameState.deck.append(card_scene.instantiate())
	pass
