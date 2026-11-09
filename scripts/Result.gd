extends Control

const LEVEL_PATHS := [
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
	"res://scenes/levels/Level03.tscn",
	"res://scenes/levels/Level04.tscn",
	"res://scenes/levels/Level05.tscn",
]


func _ready() -> void:
	var result := GameState.last_level_result
	var outcome: String = result.result_text
	if outcome.is_empty():
		outcome = "LEVEL CLEAR!" if result.won else "LEVEL FAILED"
	_add_label(outcome, Vector2(0, 90), Vector2(size.x, 64), 44)

	if result.mode == "campaign" and result.won:
		_add_label("Stars: %s" % ("★".repeat(result.stars)), Vector2(0, 180), Vector2(size.x, 50), 36)
	elif result.mode == "campaign":
		_add_label("Stars: 0", Vector2(0, 180), Vector2(size.x, 50), 36)
	else:
		var opponent_name := "Opponent" if result.mode == "online" else "Bot"
		_add_label("You: %d     %s: %d" % [
			result.score,
			opponent_name,
			result.opponent_score
		],
			Vector2(0, 180), Vector2(size.x, 50), 36)
	_add_label("Score: %d     Time left: %d s" % [result.score, ceili(result.time_left)],
		Vector2(0, 250), Vector2(size.x, 50), 30)

	var buttons := HBoxContainer.new()
	buttons.position = Vector2(0, 380)
	buttons.size = Vector2(size.x, 80)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	add_child(buttons)
	var retry_button := _add_button(buttons, "Retry", _retry_level)
	var next_button := _add_button(buttons, "Next", _next_level)
	if result.mode == "online":
		retry_button.disabled = true
		next_button.disabled = true
	next_button.disabled = result.mode == "online" or not result.won
	if result.mode == "campaign":
		next_button.disabled = (
			next_button.disabled
			or result.level_number >= LEVEL_PATHS.size()
			or not GameState.is_level_unlocked(result.level_number + 1)
		)
	elif result.mode == "versus_bot":
		next_button.disabled = next_button.disabled or result.level_number >= LEVEL_PATHS.size()
	_add_button(buttons, "Menu", _open_level_select)

	if result.won and result.level_number == LEVEL_PATHS.size():
		_add_label("Campaign complete!", Vector2(0, 320), Vector2(size.x, 44), 28)


func _retry_level() -> void:
	if GameState.last_level_result.mode == "online":
		return
	var level_number: int = GameState.last_level_result.level_number
	GameState.current_mode = GameState.last_level_result.mode
	_change_scene(LEVEL_PATHS[level_number - 1])


func _next_level() -> void:
	var level_number: int = GameState.last_level_result.level_number
	var result_mode: String = GameState.last_level_result.mode
	if result_mode != "online" and level_number < LEVEL_PATHS.size() and (
		result_mode == "versus_bot"
		or GameState.is_level_unlocked(level_number + 1)
	):
		GameState.current_mode = result_mode
		_change_scene(LEVEL_PATHS[level_number])


func _open_level_select() -> void:
	if GameState.current_mode == "online":
		Net.leave_match()
		GameState.current_mode = "campaign"
		_change_scene("res://scenes/ui/ModeSelect.tscn")
		return
	GameState.current_mode = GameState.last_level_result.mode
	_change_scene("res://scenes/ui/LevelSelect.tscn")


func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not open scene %s: %s" % [path, error_string(error)])


func _add_button(container: HBoxContainer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 70)
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(callback)
	container.add_child(button)
	return button


func _add_label(text: String, position_value: Vector2, size_value: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
