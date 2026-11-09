extends Node3D

@export var targets_required := 10
@export var time_limit_seconds := 60.0
@export var shot_range := 50.0
@export_range(1, 5) var level_number := 1
@export var targets_move := false
@export_enum("Horizontal", "Vertical", "Unpredictable") var movement_pattern := 0
@export var movement_speed := 1.5
@export var movement_range := 1.5
@export_range(0.5, 1.5, 0.05) var target_scale := 1.0
@export var limited_ammo := false
@export var reserve_ammo := 90
@export var miss_penalty := 25
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
const LEVEL_NAMES := [
	"Fundamentals",
	"Moving Targets",
	"Precision Drill",
	"Tactical Tracking",
	"Final Qualification",
]

var _score := 0
var _score_points := 0
var _shots_fired := 0
var _shots_hit := 0
var _combo := 0
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
@onready var _ammo_label: Label = $HUD/AmmoLabel
@onready var _precision_label: Label = $HUD/PrecisionLabel


func _ready() -> void:
	if enemy_scene == null and target_scene == null:
		push_error("Level %d needs a target scene or an enemy scene." % level_number)
		set_process(false)
		return

	_time_left = time_limit_seconds
	_player.connect("fire_requested", _on_fire_requested)
	_player.connect("ammo_changed", _on_ammo_changed)
	_player.connect("health_changed", _on_player_health_changed)
	_player.call("configure_ammo", 30, reserve_ammo if limited_ammo else maxi(reserve_ammo, 90))
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

	_update_level_objective()
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


func _update_level_objective() -> void:
	var level_name: String = LEVEL_NAMES[level_number - 1]
	var objective: String
	var special_mechanics: String
	if GameState.current_mode == "online":
		objective = "Race to %d targets against your opponent." % _score_goal
		special_mechanics = "Same-Wi-Fi multiplayer"
	elif enemy_scene != null:
		objective = "Clear %d targets across %d waves." % [_score_goal, wave_count]
		special_mechanics = "Return fire enabled" if enemies_shoot_back else "Enemy target waves"
	else:
		objective = "Hit %d targets." % targets_required
		special_mechanics = "Slow moving targets" if targets_move else "Stationary targets"

	if target_scale < 0.95:
		special_mechanics += " | Smaller targets"
	if limited_ammo:
		special_mechanics += " | Limited reserve ammo"
	_message_label.text = "LEVEL %d: %s\n%s  Time: %d s  |  %s" % [
		level_number,
		level_name,
		objective,
		ceili(time_limit_seconds),
		special_mechanics
	]


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
		var pattern := movement_pattern if targets_move else -1
		target.call(
			"start_moving",
			target_index,
			movement_speed,
			pattern,
			movement_range,
			target_scale,
			target_index % 3 == 2
		)


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

	_shots_fired += 1
	_raycast.target_position = Vector3(0.0, 0.0, -shot_range)
	_raycast.force_raycast_update()
	var did_hit := false
	var headshot := false
	var bullseye := false
	if _raycast.is_colliding():
		var collider := _raycast.get_collider() as Node
		if collider != null:
			headshot = collider.is_in_group("headshots")
			var target := collider.get_parent() if headshot else collider
			if target != null and target.is_in_group("targets"):
				did_hit = bool(target.call("register_hit", headshot))
				bullseye = (
					not headshot
					and target.has_method("is_bullseye")
					and target.call("is_bullseye")
					and target.to_local(_raycast.get_collision_point()).length() <= 0.25
				)

	if did_hit:
		_shots_hit += 1
		_combo += 1
		_score_points += 100
		if headshot:
			_score_points += 100
		elif bullseye:
			_score_points += 150
		_score_points += mini(_combo - 1, 8) * 25
	else:
		_combo = 0
		if GameState.current_mode == "campaign":
			_score_points = maxi(_score_points - miss_penalty, 0)
	_update_hud()


func _on_ammo_changed(current_ammo: int, reserve: int, is_reloading: bool) -> void:
	_ammo_label.text = "Reloading..." if is_reloading else "Ammo: %d / %d | R: Reload" % [
		current_ammo,
		reserve,
	]


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
		AudioManager.play_sound("target_hit")
		Net.submit_score(target_index)
		return

	AudioManager.play_sound("enemy_destroy" if enemy_scene != null else "target_hit")
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
			enemy_attack_interval,
			movement_speed,
			movement_pattern,
			target_scale,
			movement_range
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
			var accuracy := float(_shots_hit) / float(maxi(_shots_fired, 1))
			stars = 1
			if time_ratio > 0.15 and accuracy >= 0.60:
				stars = 2
			if time_ratio > 0.35 and accuracy >= 0.82:
				stars = 3

	if outcome_message.is_empty():
		outcome_message = "LEVEL CLEAR!" if won else "TIME UP - TRY AGAIN"
	_message_label.text = outcome_message
	AudioManager.play_sound("victory" if won else "defeat")

	var opponent_score := 0
	if GameState.current_mode == "online":
		opponent_score = online_opponent_score
	elif GameState.current_mode == "versus_bot" and is_instance_valid(_simple_ai):
		opponent_score = _simple_ai.call("get_score")
	GameState.record_level_result(
		level_number,
		won,
		_score_points if GameState.current_mode == "campaign" else _score,
		_time_left,
		stars,
		opponent_score,
		outcome_message,
		_shots_fired,
		_shots_hit,
		_score_points,
		_score
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
		_score_label.text = "Targets: %d / %d     Wave: %d / %d" % [
			_score,
			_score_goal,
			_wave_number,
			wave_count
		]
	else:
		_score_label.text = "Targets: %d / %d     Score: %d     Combo: %d" % [
			_score,
			_score_goal,
			_score_points,
			_combo
		]
	_timer_label.text = "Time: %d" % ceili(_time_left)
	var accuracy := 0.0
	if _shots_fired > 0:
		accuracy = float(_shots_hit) / float(_shots_fired) * 100.0
	_precision_label.text = "Accuracy: %.0f%%     Shots: %d" % [accuracy, _shots_fired]


func _target_position(target_index: int) -> Vector3:
	var columns := 5
	var column := target_index % columns
	var row := floori(float(target_index) / columns)
	var x_position := float(column - 2) * 4.0
	var z_position := -5.0 - float(row) * 3.0
	return Vector3(x_position, 1.45, z_position)
