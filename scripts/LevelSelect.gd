extends Control

const LEVEL_PATHS := [
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
	"res://scenes/levels/Level03.tscn",
	"res://scenes/levels/Level04.tscn",
	"res://scenes/levels/Level05.tscn",
]


func _ready() -> void:
	var heading := "SELECT LEVEL"
	if GameState.current_mode == "versus_bot":
		heading = "SELECT BOT DIFFICULTY"
	_add_label(heading, Vector2(0, 70), Vector2(size.x, 60), 40)

	var card_width := minf(200.0, (size.x - 100.0) / LEVEL_PATHS.size())
	var gap := 16.0
	var total_width := card_width * LEVEL_PATHS.size() + gap * (LEVEL_PATHS.size() - 1)
	var start_x := (size.x - total_width) * 0.5

	for index in range(LEVEL_PATHS.size()):
		var level_number := index + 1
		var unlocked := (
			GameState.current_mode == "versus_bot"
			or GameState.is_level_unlocked(level_number)
		)
		var button := Button.new()
		if unlocked:
			if GameState.current_mode == "versus_bot":
				button.text = "Level %d\nBot difficulty" % level_number
			else:
				var stars := GameState.get_level_stars(level_number)
				var star_text := "★".repeat(stars) if stars > 0 else "No stars yet"
				button.text = "Level %d\n%s" % [level_number, star_text]
			button.pressed.connect(_open_level.bind(LEVEL_PATHS[index]))
		else:
			button.text = "[LOCKED]\nLevel %d" % level_number
			button.disabled = true
		button.position = Vector2(start_x + index * (card_width + gap), 280)
		button.size = Vector2(card_width, 150)
		button.add_theme_font_size_override("font_size", 28)
		add_child(button)

	var footer := "Clear a level to unlock the next one."
	if GameState.current_mode == "versus_bot":
		footer = "Bot delay and accuracy increase with each level."
	_add_label(footer, Vector2(0, 480), Vector2(size.x, 48), 28)
	var back_button := Button.new()
	back_button.text = "Back"
	back_button.position = Vector2(24, 24)
	back_button.size = Vector2(140, 56)
	back_button.add_theme_font_size_override("font_size", 28)
	back_button.pressed.connect(_return_to_mode_select)
	add_child(back_button)


func _open_level(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not open level scene %s: %s" % [path, error_string(error)])


func _add_label(text: String, position_value: Vector2, size_value: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_mode_select()


func _return_to_mode_select() -> void:
	GameState.current_mode = "campaign"
	var error := get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")
	if error != OK:
		push_error("Could not open mode select: %s" % error_string(error))
