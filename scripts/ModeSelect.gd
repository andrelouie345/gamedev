extends Control


func _ready() -> void:
	_add_label("ARENA SHOOTER", Vector2(0, 100), Vector2(size.x, 70), 48)
	_add_label("Choose a game mode", Vector2(0, 175), Vector2(size.x, 50), 32)
	_add_button("Campaign", Vector2(size.x * 0.5 - 170, 270), _open_campaign)
	_add_button("Versus Bot", Vector2(size.x * 0.5 - 170, 355), _open_versus_bot)
	_add_button("Online (Same Wi-Fi)", Vector2(size.x * 0.5 - 170, 440), _open_lobby)
	if not GameState.menu_message.is_empty():
		_add_label(GameState.menu_message, Vector2(80, 530), Vector2(size.x - 160, 64), 28)
		GameState.menu_message = ""
	_add_button(
		"Title Screen",
		Vector2(size.x * 0.5 - 260, 625),
		_open_title_screen,
		Vector2(240, 56)
	)
	_add_button(
		"Credits",
		Vector2(size.x * 0.5 + 20, 625),
		_open_credits,
		Vector2(240, 56)
	)


func _open_campaign() -> void:
	GameState.current_mode = "campaign"
	_change_scene("res://scenes/ui/LevelSelect.tscn")


func _open_versus_bot() -> void:
	GameState.current_mode = "versus_bot"
	_change_scene("res://scenes/ui/LevelSelect.tscn")


func _open_lobby() -> void:
	GameState.current_mode = "online"
	_change_scene("res://scenes/ui/Lobby.tscn")


func _open_title_screen() -> void:
	_change_scene("res://scenes/ui/TitleScreen.tscn")


func _open_credits() -> void:
	GameState.credits_return_scene = "res://scenes/ui/ModeSelect.tscn"
	_change_scene("res://scenes/ui/Credits.tscn")


func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not open scene %s: %s" % [path, error_string(error)])


func _add_button(
	text: String,
	position_value: Vector2,
	callback: Callable,
	button_size := Vector2(340, 72)
) -> void:
	var button := Button.new()
	button.text = text
	button.position = position_value
	button.size = button_size
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(callback)
	add_child(button)


func _add_label(text: String, position_value: Vector2, size_value: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
