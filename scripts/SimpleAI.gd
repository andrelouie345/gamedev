extends Node

signal score_changed(score: int)

var score := 0
var _score_goal := 0
var _shot_delay := 1.8
var _accuracy := 0.45
var _time_until_shot := 0.0
var _is_running := false


func configure(level_number: int, score_goal: int) -> void:
	_score_goal = score_goal
	_shot_delay = maxf(1.8 - float(level_number - 1) * 0.18, 0.9)
	_accuracy = clampf(0.45 + float(level_number - 1) * 0.08, 0.45, 0.77)
	_time_until_shot = _shot_delay
	_is_running = true


func _process(delta: float) -> void:
	if not _is_running or score >= _score_goal:
		return

	_time_until_shot -= delta
	if _time_until_shot > 0.0:
		return

	if randf() <= _accuracy:
		score += 1
		score_changed.emit(score)
	_time_until_shot = _shot_delay


func stop() -> void:
	_is_running = false


func get_score() -> int:
	return score
