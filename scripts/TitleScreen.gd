extends Control


func _ready() -> void:
	_add_label("ARENA SHOOTER", Vector2(0, 130), Vector2(size.x, 80), 52)
	_add_label(
		"A first-person arena shooter",
		Vector2(0, 215),
		Vector2(size.x, 48),
		30
	)
	_add_button("Play", Vector2(size.x * 0.5 - 160, 300), _open_mode_select)
	_add_button("Credits", Vector2(size.x * 0.5 - 160, 390), _open_credits)
	_add_button("Quit", Vector2(size.x * 0.5 - 160, 480), _quit_game)


func _open_mode_select() -> void:
	_change_scene("res://scenes/ui/ModeSelect.tscn")


func _open_credits() -> void:
	GameState.credits_return_scene = "res://scenes/ui/TitleScreen.tscn"
	_change_scene("res://scenes/ui/Credits.tscn")


func _quit_game() -> void:
	get_tree().quit()


func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not open scene %s: %s" % [path, error_string(error)])


func _add_button(text: String, position_value: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = position_value
	button.size = Vector2(320, 72)
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(callback)
	add_child(button)


func _add_label(
	text: String,
	position_value: Vector2,
	size_value: Vector2,
	font_size: int
) -> void:
	var label := Label.new()
	label.text = text
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
