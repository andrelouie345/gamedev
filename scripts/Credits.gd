extends Control

func _ready() -> void:
	var title := Label.new()
	title.text = "CREDITS"
	title.position = Vector2(0, 90)
	title.size = Vector2(size.x, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	add_child(title)

	var credits := Label.new()
	credits.text = (
		"Game design and development: student project\n\n"
		+ "Original low-poly AK-47/arms and target assets are included in the project.\n"
		+ "The range uses project-made geometry and Godot UI controls.\n"
		+ "No third-party art, fonts, music, or sound effects are included."
	)
	credits.position = Vector2(100, 220)
	credits.size = Vector2(size.x - 200, 220)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits.add_theme_font_size_override("font_size", 28)
	add_child(credits)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.position = Vector2(size.x * 0.5 - 150, 520)
	back_button.size = Vector2(300, 72)
	back_button.add_theme_font_size_override("font_size", 30)
	back_button.pressed.connect(_return)
	add_child(back_button)


func _return() -> void:
	var error := get_tree().change_scene_to_file(GameState.credits_return_scene)
	if error != OK:
		push_error("Could not return from credits: %s" % error_string(error))
