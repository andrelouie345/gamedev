extends Area3D

signal hit

const MOVE_DISTANCE := 1.5

var _health := 1
var _already_defeated := false
var _move_origin := Vector3.ZERO
var _move_phase := 0.0
var _attacks_player := false
var _attack_damage := 10
var _attack_interval := 2.0
var _attack_time_left := 0.0
var _move_speed := 1.5
var _move_pattern := 0
var _target_scale := 1.0
var _move_range := MOVE_DISTANCE
var _movement_timer := 0.0
var _movement_destination := Vector3.ZERO
var _movement_rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("targets")
	$HeadHitbox.add_to_group("headshots")
	_move_origin = position


func configure(
	enemy_index: int,
	is_boss: bool,
	attacks_player: bool,
	attack_damage: int,
	attack_interval: float,
	move_speed := 1.5,
	move_pattern := 0,
	target_scale := 1.0,
	move_range := MOVE_DISTANCE
) -> void:
	_health = 5 if is_boss else 1
	_move_origin = position
	_move_phase = float(enemy_index) * 1.4
	_move_speed = move_speed
	_move_pattern = move_pattern
	_move_range = move_range
	_movement_rng.seed = enemy_index + 2903
	_movement_destination = _move_origin
	_movement_timer = 0.0
	_target_scale = target_scale
	_attacks_player = attacks_player
	_attack_damage = attack_damage
	_attack_interval = attack_interval
	_attack_time_left = attack_interval
	if is_boss:
		_target_scale *= 1.35
	scale = Vector3.ONE * _target_scale


func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	if _move_pattern == 1:
		position.y = _move_origin.y + sin(time * _move_speed + _move_phase) * MOVE_DISTANCE * 0.35
	elif _move_pattern == 2:
		_movement_timer -= delta
		if _movement_timer <= 0.0:
			_movement_destination = Vector3(
				_move_origin.x + _movement_rng.randf_range(-_move_range, _move_range),
				_move_origin.y + _movement_rng.randf_range(-_move_range * 0.35, _move_range * 0.35),
				_move_origin.z
			)
			_movement_timer = _movement_rng.randf_range(0.65, 1.25)
		position = position.move_toward(_movement_destination, _move_speed * delta)
	else:
		position.x = _move_origin.x + sin(time * _move_speed + _move_phase) * _move_range
	if not _attacks_player:
		return

	_attack_time_left -= delta
	if _attack_time_left <= 0.0:
		_try_attack_player()
		_attack_time_left = _attack_interval


func register_hit(headshot := false) -> bool:
	if _already_defeated:
		return false

	_health -= 2 if headshot else 1
	if _health <= 0:
		_already_defeated = true
		hit.emit()
		queue_free()
	return true


func _try_attack_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null:
		return

	var player_aim_point := player.global_position + Vector3(0.0, 0.5, 0.0)
	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		player_aim_point,
		1,
		[get_rid()]
	)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return

	if result["collider"] == player:
		player.call("take_damage", _attack_damage)
