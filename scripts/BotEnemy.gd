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


func _ready() -> void:
	add_to_group("targets")
	_move_origin = position


func configure(
	enemy_index: int,
	is_boss: bool,
	attacks_player: bool,
	attack_damage: int,
	attack_interval: float
) -> void:
	_health = 5 if is_boss else 1
	_move_origin = position
	_move_phase = float(enemy_index) * 1.4
	_attacks_player = attacks_player
	_attack_damage = attack_damage
	_attack_interval = attack_interval
	_attack_time_left = attack_interval
	if is_boss:
		scale = Vector3.ONE * 1.6


func _process(delta: float) -> void:
	position.x = _move_origin.x + sin(Time.get_ticks_msec() / 1000.0 * 1.5 + _move_phase) * MOVE_DISTANCE
	if not _attacks_player:
		return

	_attack_time_left -= delta
	if _attack_time_left <= 0.0:
		_try_attack_player()
		_attack_time_left = _attack_interval


func register_hit() -> void:
	if _already_defeated:
		return

	_health -= 1
	if _health <= 0:
		_already_defeated = true
		hit.emit()
		queue_free()


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
