extends Area3D

signal hit

var _already_hit := false
var _move_origin := Vector3.ZERO
var _move_phase := 0.0
var _moving := false
var _move_speed := 1.5
var _move_pattern := 0
var _move_range := 1.5
var _movement_timer := 0.0
var _movement_destination := Vector3.ZERO
var _movement_rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("targets")
	$HeadHitbox.add_to_group("headshots")


func start_moving(
	target_index: int,
	move_speed := 1.5,
	move_pattern := 0,
	move_range := 1.5,
	target_scale := 1.0,
	is_bullseye := false
) -> void:
	_move_origin = position
	_move_phase = float(target_index) * 1.4
	_moving = true
	_move_speed = move_speed
	_move_pattern = move_pattern
	_move_range = move_range
	_movement_rng.seed = target_index + 1709
	_movement_destination = _move_origin
	_movement_timer = 0.0
	scale = Vector3.ONE * target_scale
	$SilhouetteVisual.visible = not is_bullseye
	$BullseyeVisual.visible = is_bullseye


func _process(delta: float) -> void:
	if not _moving or _move_pattern < 0:
		return

	var time := Time.get_ticks_msec() / 1000.0
	if _move_pattern == 0:
		position.x = _move_origin.x + sin(time * _move_speed + _move_phase) * _move_range
		position.y = _move_origin.y
	elif _move_pattern == 1:
		position.y = _move_origin.y + sin(time * _move_speed + _move_phase) * _move_range * 0.4
		position.x = _move_origin.x
	else:
		_movement_timer -= delta
		if _movement_timer <= 0.0:
			_movement_destination = Vector3(
				_move_origin.x + _movement_rng.randf_range(-_move_range, _move_range),
				_move_origin.y + _movement_rng.randf_range(-_move_range * 0.25, _move_range * 0.25),
				_move_origin.z
			)
			_movement_timer = _movement_rng.randf_range(0.65, 1.25)
		position = position.move_toward(_movement_destination, _move_speed * delta)


func register_hit(_headshot := false) -> bool:
	if _already_hit:
		return false

	_already_hit = true
	hit.emit()
	queue_free()
	return true


func is_bullseye() -> bool:
	return $BullseyeVisual.visible
