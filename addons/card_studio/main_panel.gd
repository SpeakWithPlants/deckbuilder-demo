@tool
extends HSplitContainer


var active_card: CardModel


func _ready() -> void:
	active_card = %CardModel
	active_card.title = %TitleEdit.text
	active_card.cost = int(%CostEdit.get_line_edit().text)
	active_card.health = int(%HealthEdit.get_line_edit().text)
	active_card.enter_state(CardView.State.EXAMINE)
	pass


func _on_title_edit_text_changed(new_text: String) -> void:
	active_card.title = new_text
	pass


func _on_cost_edit_value_changed(value: float) -> void:
	active_card.cost = round(value)
	pass


func _on_health_edit_value_changed(value: float) -> void:
	active_card.health = round(value)
	pass
