extends Node

const MAX_LEVELS := 5
const PROGRESS_PATH := "user://progress.cfg"

var unlocked_level := 1
var level_stars: Dictionary = {}
var current_mode := "campaign"
var sound_enabled := true
var menu_message := ""
var credits_return_scene := "res://scenes/ui/ModeSelect.tscn"
var last_level_result: Dictionary = {
	"level_number": 1,
	"won": false,
	"score": 0,
	"time_left": 0.0,
	"stars": 0,
	"mode": "campaign",
	"opponent_score": 0,
	"result_text": "No result yet",
	"shots_fired": 0,
	"shots_hit": 0,
	"accuracy": 0.0,
	"score_points": 0,
	"targets_cleared": 0,
}


func _ready() -> void:
	load_progress()
	_apply_sound_setting()


func load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(PROGRESS_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_error("Could not load campaign progress: %s" % error_string(error))
		return

	var saved_unlocked = config.get_value("progress", "unlocked_level", 1)
	if typeof(saved_unlocked) == TYPE_INT and saved_unlocked >= 1 and saved_unlocked <= MAX_LEVELS:
		unlocked_level = saved_unlocked
	else:
		push_warning("Ignoring invalid unlocked level in saved progress.")

	var saved_sound_enabled = config.get_value("settings", "sound_enabled", true)
	if typeof(saved_sound_enabled) == TYPE_BOOL:
		sound_enabled = saved_sound_enabled
	else:
		push_warning("Ignoring invalid saved sound setting.")

	for level_number in range(1, MAX_LEVELS + 1):
		var saved_stars = config.get_value(
			"progress",
			"level_%d_stars" % level_number,
			0
		)
		if typeof(saved_stars) == TYPE_INT and saved_stars >= 0 and saved_stars <= 3:
			level_stars[level_number] = saved_stars
		else:
			push_warning("Ignoring invalid star record for level %d." % level_number)


func is_level_unlocked(level_number: int) -> bool:
	return level_number >= 1 and level_number <= unlocked_level


func get_level_stars(level_number: int) -> int:
	return level_stars.get(level_number, 0)


func complete_level(level_number: int, stars: int) -> void:
	if level_number < 1 or level_number > MAX_LEVELS:
		push_error("Cannot save progress for invalid level %d." % level_number)
		return
	if not is_level_unlocked(level_number):
		push_error("Cannot clear locked level %d." % level_number)
		return
	if stars < 1 or stars > 3:
		push_error("Level clear must award between 1 and 3 stars.")
		return

	var previous_unlocked_level := unlocked_level
	level_stars[level_number] = maxi(get_level_stars(level_number), stars)
	unlocked_level = mini(maxi(unlocked_level, level_number + 1), MAX_LEVELS)
	_save_progress()
	if unlocked_level > previous_unlocked_level:
		AudioManager.play_sound("level_unlock")


func record_level_result(
	level_number: int,
	won: bool,
	score: int,
	time_left: float,
	stars: int,
	opponent_score := 0,
	result_text := "",
	shots_fired := 0,
	shots_hit := 0,
	score_points := 0,
	targets_cleared := 0
) -> void:
	last_level_result = {
		"level_number": level_number,
		"won": won,
		"score": score,
		"time_left": time_left,
		"stars": stars,
		"mode": current_mode,
		"opponent_score": opponent_score,
		"result_text": result_text,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"accuracy": (
			float(shots_hit) / float(shots_fired) * 100.0 if shots_fired > 0 else 0.0
		),
		"score_points": score_points,
		"targets_cleared": targets_cleared,
	}
	if won and current_mode == "campaign":
		complete_level(level_number, stars)


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_sound_setting()
	_save_progress()


func _apply_sound_setting() -> void:
	AudioServer.set_bus_mute(0, not sound_enabled)


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_level", unlocked_level)
	for level_number in range(1, MAX_LEVELS + 1):
		config.set_value(
			"progress",
			"level_%d_stars" % level_number,
			get_level_stars(level_number)
		)
	config.set_value("settings", "sound_enabled", sound_enabled)

	var error := config.save(PROGRESS_PATH)
	if error != OK:
		push_error("Could not save campaign progress: %s" % error_string(error))
