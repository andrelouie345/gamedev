extends Area3D

signal hit

var _already_hit := false
var _move_origin := Vector3.ZERO
var _move_phase := 0.0
var _moving := false


func _ready() -> void:
	add_to_group("targets")


func start_moving(target_index: int) -> void:
	_move_origin = position
	_move_phase = float(target_index) * 1.4
	_moving = true


func _process(_delta: float) -> void:
	if _moving:
		position.x = _move_origin.x + sin(Time.get_ticks_msec() / 1000.0 * 1.5 + _move_phase) * 1.5


func register_hit() -> void:
	if _already_hit:
		return

	_already_hit = true
	hit.emit()
	queue_free()
