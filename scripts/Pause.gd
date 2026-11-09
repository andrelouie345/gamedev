extends Control

var _sound_button: Button
var _leave_confirmation: ConfirmationDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	var panel := PanelContainer.new()
	panel.position = Vector2(390, 105)
	panel.size = Vector2(500, 510)
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	content.add_child(title)

	_add_button(content, "Resume", _resume)
	_add_button(content, "Restart", _restart)
	_sound_button = _add_button(content, "", _toggle_sound)
	_update_sound_button()
	_add_button(content, "Quit to Menu", _quit_to_menu)
	if GameState.current_mode == "online":
		_leave_confirmation = ConfirmationDialog.new()
		_leave_confirmation.dialog_text = "Leave the online match and return to the menu?"
		_leave_confirmation.confirmed.connect(_leave_online_match)
		add_child(_leave_confirmation)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_resume()
		get_viewport().set_input_as_handled()


func _resume() -> void:
	get_tree().paused = false
	queue_free()


func _restart() -> void:
	if GameState.current_mode == "online":
		get_tree().paused = false
		Net.restart_match()
		return

	var scene_path := get_tree().current_scene.scene_file_path
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not restart level %s: %s" % [scene_path, error_string(error)])


func _toggle_sound() -> void:
	GameState.set_sound_enabled(not GameState.sound_enabled)
	_update_sound_button()


func _update_sound_button() -> void:
	_sound_button.text = "Sound: On" if GameState.sound_enabled else "Sound: Off"


func _quit_to_menu() -> void:
	if GameState.current_mode == "online":
		_leave_confirmation.popup_centered()
		return
	_leave_to_mode_select()


func _leave_online_match() -> void:
	Net.leave_match()
	GameState.current_mode = "campaign"
	_leave_to_mode_select()


func _leave_to_mode_select() -> void:
	get_tree().paused = false
	var error := get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")
	if error != OK:
		push_error("Could not return to mode select: %s" % error_string(error))


func _add_button(container: VBoxContainer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 68)
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(callback)
	container.add_child(button)
	return button
