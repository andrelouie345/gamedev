extends Node3D

@export var targets_required := 10
@export var time_limit_seconds := 60.0
@export var shot_range := 50.0

var _score := 0
var _time_left := 0.0
var _is_active := true

@onready var _player: CharacterBody3D = $Player
@onready var _raycast: RayCast3D = $Player/Head/Camera3D/RayCast3D
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _timer_label: Label = $HUD/TimerLabel
@onready var _message_label: Label = $HUD/MessageLabel


func _ready() -> void:
	_time_left = time_limit_seconds
	_player.connect("fire_requested", _on_fire_requested)

	for target in get_tree().get_nodes_in_group("targets"):
		if target.has_signal("hit"):
			target.connect("hit", _on_target_hit)

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
		_finish_level(false)


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


func _on_target_hit() -> void:
	if not _is_active:
		return

	_score += 1
	_update_hud()
	if _score >= targets_required:
		_finish_level(true)


func _finish_level(won: bool) -> void:
	_is_active = false
	if won:
		_message_label.text = "LEVEL CLEAR!"
	else:
		_message_label.text = "TIME UP - TRY AGAIN"


func _update_hud() -> void:
	_score_label.text = "Targets: %d / %d" % [_score, targets_required]
	_timer_label.text = "Time: %d" % ceili(_time_left)
