@tool
extends HSplitContainer

const card_scene = preload("res://card/card.tscn")


var active_card: Card
var file_name: String = "card_new_card.tscn"
var save_path: String = "res://"
var edited: bool = true:
	set(value):
		if value:
			%FileNameLabel.text = file_name + "(*)"
		else:
			%FileNameLabel.text = file_name

@onready var file_dialog = $FileDialog


func _ready() -> void:
	file_name = _format_file_name(%TitleEdit.text) + ".tscn"
	%FileNameLabel.text = file_name + "(*)"
	
	var new_card = card_scene.instantiate()
	
	active_card = new_card
	active_card.title = %TitleEdit.text
	active_card.cost = int(%CostEdit.get_line_edit().text)
	active_card.health = int(%HealthEdit.get_line_edit().text)
	active_card.state = Card.State.EXAMINE
	pass


func reset_editor() -> void:
	edited = true
	pass


func save_active_card() -> void:
	var full_path = save_path.path_join(file_name)
	var packed = PackedScene.new()
	packed.pack(active_card)
	ResourceSaver.save(packed, full_path)
	edited = false
	pass


func open_save_as_dialog() -> void:
	file_dialog.visible = true
	file_dialog.current_dir = save_path
	file_name = _format_file_name(%TitleEdit.text) + ".tscn"
	file_dialog.current_file = file_name
	pass


func _format_file_name(card_title: String) -> String:
	return "card_" + card_title.to_lower().to_snake_case()


func _on_title_edit_text_changed(new_text: String) -> void:
	active_card.title = new_text
	edited = true
	pass


func _on_cost_edit_value_changed(value: float) -> void:
	active_card.cost = round(value)
	edited = true
	pass


func _on_health_edit_value_changed(value: float) -> void:
	active_card.health = round(value)
	edited = true
	pass


func _on_file_dialog_file_selected(path: String) -> void:
	var last_separator_index = path.rfind("/")
	save_path = path.substr(0, last_separator_index)
	file_name = path.substr(last_separator_index + 1, -1)
	save_active_card()
	pass


func _on_save_button_pressed() -> void:
	var full_path = save_path.path_join(file_name)
	if ResourceLoader.exists(full_path):
		save_active_card()
	else:
		open_save_as_dialog()
