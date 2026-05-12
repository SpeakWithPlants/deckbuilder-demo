@tool
extends EditorPlugin

const MainPanel = preload("res://addons/card_studio/main_panel.tscn")

var main_panel_inst


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	main_panel_inst = MainPanel.instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_panel_inst)
	_make_visible(false)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	if main_panel_inst:
		main_panel_inst.queue_free()
	pass


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if main_panel_inst:
		main_panel_inst.visible = visible
	pass


func _get_plugin_name() -> String:
	return "CardStudio"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("CanvasLayer", "EditorIcons")
