extends Node3D

@export var targets_required := 10
@export var time_limit_seconds := 60.0
@export var shot_range := 50.0
@export_range(1, 5) var level_number := 1
@export var targets_move := false
@export var target_scene: PackedScene
@export var enemy_scene: PackedScene
@export var enemies_per_wave := 0
@export var wave_count := 1
@export var enemies_shoot_back := false
@export var boss_on_final_wave := false
@export var enemy_attack_damage := 10
@export var enemy_attack_interval := 2.0

const PAUSE_SCENE := preload("res://scenes/ui/Pause.tscn")
const SIMPLE_AI_SCRIPT := preload("res://scripts/SimpleAI.gd")

var _score := 0
var _score_goal := 0
var _wave_number := 0
var _enemies_remaining := 0
var _time_left := 0.0
var _is_active := true
var _simple_ai: Node

@onready var _player: CharacterBody3D = $Player
@onready var _raycast: RayCast3D = $Player/Head/Camera3D/RayCast3D
@onready var _targets: Node3D = $Targets
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _timer_label: Label = $HUD/TimerLabel
@onready var _message_label: Label = $HUD/MessageLabel
@onready var _health_label: Label = $HUD/HealthLabel


func _ready() -> void:
	if enemy_scene == null and target_scene == null:
		push_error("Level %d needs a target scene or an enemy scene." % level_number)
		set_process(false)
		return

	_time_left = time_limit_seconds
	_player.connect("fire_requested", _on_fire_requested)
	_player.connect("health_changed", _on_player_health_changed)
	_on_player_health_changed(100, 100)
	_create_pause_button()

	if GameState.current_mode == "online":
		if not Net.is_online_match:
			GameState.menu_message = "Online match is no longer connected."
			get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")
			return
		_score_goal = Net.target_count
		_spawn_target_layout(_online_target_positions())
		Net.scores_updated.connect(_on_online_scores_updated)
		Net.match_finished.connect(_on_online_match_finished)
		Net.restart_requested.connect(_on_online_restart_requested)
	elif enemy_scene != null:
		_score_goal = enemies_per_wave * wave_count
		_spawn_enemy_wave()
	else:
		_score_goal = targets_required
		_spawn_target_layout(_target_positions(targets_required))

	if GameState.current_mode == "versus_bot":
		_simple_ai = SIMPLE_AI_SCRIPT.new()
		add_child(_simple_ai)
		_simple_ai.connect("score_changed", _on_ai_score_changed)
		_simple_ai.call("configure", level_number, _score_goal)

	if GameState.current_mode == "online":
		_message_label.text = "Race: hit %d targets before your opponent" % _score_goal
	elif enemy_scene != null:
		var wave_word := "wave" if wave_count == 1 else "waves"
		_message_label.text = "Goal: Defeat %d bots in %d %s before time runs out" % [
			_score_goal,
			wave_count,
			wave_word
		]
	else:
		_message_label.text = "Goal: Hit %d targets in %d seconds" % [
			targets_required,
			int(time_limit_seconds)
		]
	_update_hud()


func _process(delta: float) -> void:
	if not _is_active:
		return

	_time_left = maxf(_time_left - delta, 0.0)
	_update_hud()
	if _time_left <= 0.0:
		if GameState.current_mode == "online":
			Net.finish_race_by_score()
		elif GameState.current_mode == "versus_bot":
			var bot_score: int = _simple_ai.call("get_score")
			if _score > bot_score:
				_finish_level(true, "YOU WIN!")
			elif _score < bot_score:
				_finish_level(false, "BOT WINS!")
			else:
				_finish_level(false, "DRAW!")
		else:
			_finish_level(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_active:
		_open_pause_menu()
		get_viewport().set_input_as_handled()


func _create_pause_button() -> void:
	var button := Button.new()
	button.text = "PAUSE"
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.offset_left = -170.0
	button.offset_top = 18.0
	button.offset_right = -20.0
	button.offset_bottom = 70.0
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(_open_pause_menu)
	$HUD.add_child(button)


func _open_pause_menu() -> void:
	if not _is_active or get_tree().paused:
		return
	var pause_menu := PAUSE_SCENE.instantiate()
	add_child(pause_menu)


func _spawn_target_layout(positions: Array[Vector3]) -> void:
	if target_scene == null:
		push_error("Level %d has no target scene assigned." % level_number)
		set_process(false)
		return

	for target_index in range(positions.size()):
		var target := target_scene.instantiate() as Area3D
		if target == null:
			push_error("The assigned target scene must have an Area3D root.")
			set_process(false)
			return
		_targets.add_child(target)
		target.position = positions[target_index]
		target.connect("hit", _on_target_hit.bind(target_index))
		if targets_move:
			target.call("start_moving", target_index)


func _target_positions(count: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for target_index in range(count):
		positions.append(_target_position(target_index))
	return positions


func _online_target_positions() -> Array[Vector3]:
	var positions := _target_positions(Net.target_count)
	var random := RandomNumberGenerator.new()
	random.seed = Net.match_seed
	for index in range(positions.size() - 1, 0, -1):
		var swap_index := random.randi_range(0, index)
		var position := positions[index]
		positions[index] = positions[swap_index]
		positions[swap_index] = position
	return positions


func _on_fire_requested() -> void:
	if not _is_active:
		return

	_raycast.target_position = Vector3(0.0, 0.0, -shot_range)
	_raycast.force_raycast_update()
	if not _raycast.is_colliding():
		return

	var collider := _raycast.get_collider() as Node
	if collider != null and collider.is_in_group("targets"):
		collider.call("register_hit")


func _on_online_scores_updated() -> void:
	_update_hud()


func _on_online_match_finished(
	won: bool,
	your_score: int,
	opponent_score: int,
	result_text: String
) -> void:
	_score = your_score
	_finish_level(won, result_text, opponent_score)


func _on_online_restart_requested() -> void:
	get_tree().paused = false
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("Could not restart online match: %s" % error_string(error))


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	_health_label.text = "Health: %d / %d" % [current_health, maximum_health]
	if current_health <= 0:
		if GameState.current_mode == "versus_bot":
			_finish_level(false, "BOT WINS!")
		else:
			_finish_level(false, "BOT DEFEATED YOU")


func _on_ai_score_changed(ai_score: int) -> void:
	_update_hud()
	if ai_score >= _score_goal:
		_finish_level(false, "BOT WINS!")


func _on_target_hit(target_index: int) -> void:
	if not _is_active:
		return

	if GameState.current_mode == "online":
		Net.submit_score(target_index)
		return

	_score += 1
	if enemy_scene != null:
		_enemies_remaining -= 1
	_update_hud()
	if _score >= _score_goal:
		if GameState.current_mode == "versus_bot":
			_finish_level(true, "YOU WIN!")
		else:
			_finish_level(true)
	elif enemy_scene != null and _enemies_remaining == 0:
		_spawn_enemy_wave()


func _spawn_enemy_wave() -> void:
	_wave_number += 1
	_enemies_remaining = enemies_per_wave
	for enemy_index in range(enemies_per_wave):
		var enemy := enemy_scene.instantiate() as Area3D
		if enemy == null:
			push_error("The assigned enemy scene must have an Area3D root.")
			set_process(false)
			return
		_targets.add_child(enemy)
		enemy.position = _target_position(enemy_index + (_wave_number - 1) * 2)
		var is_final_boss := (
			boss_on_final_wave
			and _wave_number == wave_count
			and enemy_index == enemies_per_wave - 1
		)
		enemy.call(
			"configure",
			enemy_index + (_wave_number - 1) * enemies_per_wave,
			is_final_boss,
			enemies_shoot_back and GameState.current_mode == "campaign",
			enemy_attack_damage,
			enemy_attack_interval
		)
		enemy.connect("hit", _on_target_hit)


func _finish_level(won: bool, outcome_message := "", online_opponent_score := -1) -> void:
	if not _is_active:
		return
	_is_active = false
	set_process_unhandled_input(false)
	if is_instance_valid(_simple_ai):
		_simple_ai.call("stop")

	var stars := 0
	if won:
		if GameState.current_mode == "campaign":
			var time_ratio := _time_left / maxf(time_limit_seconds, 1.0)
			stars = 1
			if time_ratio > 0.25:
				stars = 2
			if time_ratio > 0.5:
				stars = 3

	if outcome_message.is_empty():
		outcome_message = "LEVEL CLEAR!" if won else "TIME UP - TRY AGAIN"
	_message_label.text = outcome_message

	var opponent_score := 0
	if GameState.current_mode == "online":
		opponent_score = online_opponent_score
	elif GameState.current_mode == "versus_bot" and is_instance_valid(_simple_ai):
		opponent_score = _simple_ai.call("get_score")
	GameState.record_level_result(
		level_number,
		won,
		_score,
		_time_left,
		stars,
		opponent_score,
		outcome_message
	)

	await get_tree().create_timer(1.0).timeout
	var error := get_tree().change_scene_to_file("res://scenes/ui/Result.tscn")
	if error != OK:
		push_error("Could not open the result screen: %s" % error_string(error))


func _update_hud() -> void:
	if GameState.current_mode == "online":
		_score_label.text = "You: %d / %d     Opponent: %d / %d" % [
			Net.get_local_score(),
			_score_goal,
			Net.get_opponent_score(),
			_score_goal
		]
	elif GameState.current_mode == "versus_bot":
		var bot_score := 0
		if is_instance_valid(_simple_ai):
			bot_score = _simple_ai.call("get_score")
		_score_label.text = "You: %d / %d     Bot: %d / %d" % [
			_score,
			_score_goal,
			bot_score,
			_score_goal
		]
	elif enemy_scene != null:
		_score_label.text = "Bots: %d / %d     Wave: %d / %d" % [
			_score,
			_score_goal,
			_wave_number,
			wave_count
		]
	else:
		_score_label.text = "Targets: %d / %d" % [_score, _score_goal]
	_timer_label.text = "Time: %d" % ceili(_time_left)


func _target_position(target_index: int) -> Vector3:
	var columns := 5
	var column := target_index % columns
	var row := floori(float(target_index) / columns)
	var x_position := float(column - 2) * 4.0
	var z_position := -5.0 - float(row) * 3.0
	return Vector3(x_position, 1.3, z_position)
