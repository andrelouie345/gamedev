extends CharacterBody3D

signal fire_requested
signal ammo_changed(current_ammo: int, reserve_ammo: int, is_reloading: bool)
signal health_changed(current_health: int, maximum_health: int)

const MOVE_SPEED := 5.0
const GRAVITY := 9.8
const LOOK_SENSITIVITY := 0.0025
const MAX_PITCH := deg_to_rad(80.0)
const MAX_HEALTH := 100
const FIRE_COOLDOWN := 0.12
const RELOAD_DURATION := 1.55
const DEFAULT_MAGAZINE_SIZE := 30
const DEFAULT_RESERVE_AMMO := 90

var _touch_move := Vector2.ZERO
var health := MAX_HEALTH
var _magazine_size := DEFAULT_MAGAZINE_SIZE
var _ammo := DEFAULT_MAGAZINE_SIZE
var _reserve_ammo := DEFAULT_RESERVE_AMMO
var _fire_cooldown := 0.0
var _reload_time_left := 0.0
var _is_reloading := false
var _look_pitch := 0.0
var _recoil_pitch := 0.0
var _muzzle_flash_time_left := 0.0
var _weapon_animation_player: AnimationPlayer

@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	# Keep the mouse visible until the player clicks, which makes desktop testing easier.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_to_group("player")
	var animation_players := $Head/Camera3D/WeaponAnchor.find_children(
		"*", "AnimationPlayer", true, false
	)
	if animation_players.is_empty():
		push_error("The first-person weapon asset has no AnimationPlayer.")
	else:
		_weapon_animation_player = animation_players[0] as AnimationPlayer
		if not _weapon_animation_player.has_animation("Idle"):
			push_error("The first-person weapon asset is missing its Idle animation.")
		else:
			_weapon_animation_player.animation_finished.connect(_on_weapon_animation_finished)
			_weapon_animation_player.play("Idle")
	_notify_ammo_changed()


func _process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_recoil_pitch = move_toward(_recoil_pitch, 0.0, delta * 0.11)
	camera.rotation.x = clampf(_look_pitch + _recoil_pitch, -MAX_PITCH, MAX_PITCH)
	if _is_reloading:
		_reload_time_left -= delta
		if _reload_time_left <= 0.0:
			var rounds_to_load := mini(_magazine_size - _ammo, _reserve_ammo)
			_ammo += rounds_to_load
			_reserve_ammo -= rounds_to_load
			_is_reloading = false
			_notify_ammo_changed()
			_play_weapon_animation("Idle")
	if _muzzle_flash_time_left > 0.0:
		_muzzle_flash_time_left -= delta
		if _muzzle_flash_time_left <= 0.0:
			$Head/Camera3D/MuzzleFlash.visible = false
			$Head/Camera3D/MuzzleLight.visible = false


func _physics_process(delta: float) -> void:
	var keyboard_move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		keyboard_move.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		keyboard_move.x += 1.0
	if Input.is_key_pressed(KEY_W):
		keyboard_move.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		keyboard_move.y += 1.0

	var move_input := _touch_move + keyboard_move
	if move_input.length() > 1.0:
		move_input = move_input.normalized()

	var move_direction := transform.basis * Vector3(move_input.x, 0.0, move_input.y)
	velocity.x = move_direction.x * MOVE_SPEED
	velocity.z = move_direction.z * MOVE_SPEED

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	move_and_slide()


func _input(event: InputEvent) -> void:
	if (
		ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)
		and (event is InputEventMouseButton or event is InputEventMouseMotion)
	):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_request_fire()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_R:
			_request_reload()


func _on_touch_movement_changed(value: Vector2) -> void:
	_touch_move = value


func _on_touch_look_delta(value: Vector2) -> void:
	_apply_look(value)


func _on_touch_fire_requested() -> void:
	_request_fire()


func _on_touch_reload_requested() -> void:
	_request_reload()


func _request_fire() -> void:
	if _is_reloading or _fire_cooldown > 0.0:
		return
	if _ammo <= 0:
		_request_reload()
		return

	_ammo -= 1
	_fire_cooldown = FIRE_COOLDOWN
	_recoil_pitch = minf(_recoil_pitch + 0.018, 0.06)
	_notify_ammo_changed()
	_play_weapon_animation("Fire")
	AudioManager.play_sound("shot")
	$Head/Camera3D/MuzzleFlash.visible = true
	$Head/Camera3D/MuzzleLight.visible = true
	$Head/Camera3D/MuzzleFlash.scale = Vector3.ONE * randf_range(0.8, 1.2)
	_muzzle_flash_time_left = 0.045
	fire_requested.emit()


func _request_reload() -> void:
	if _is_reloading or _ammo >= _magazine_size or _reserve_ammo <= 0:
		return

	_is_reloading = true
	_reload_time_left = RELOAD_DURATION
	_notify_ammo_changed()
	_play_weapon_animation("Reload")


func configure_ammo(magazine_size: int, reserve_ammo: int) -> void:
	if magazine_size <= 0 or reserve_ammo < 0:
		push_error("Ammo configuration must use a positive magazine and non-negative reserve.")
		return
	_magazine_size = magazine_size
	_ammo = magazine_size
	_reserve_ammo = reserve_ammo
	_is_reloading = false
	_reload_time_left = 0.0
	_notify_ammo_changed()


func _notify_ammo_changed() -> void:
	ammo_changed.emit(_ammo, _reserve_ammo, _is_reloading)


func _play_weapon_animation(animation_name: String) -> void:
	if not is_instance_valid(_weapon_animation_player):
		return
	if not _weapon_animation_player.has_animation(animation_name):
		push_error("The first-person weapon asset is missing its %s animation." % animation_name)
		return
	_weapon_animation_player.play(animation_name)


func _on_weapon_animation_finished(animation_name: StringName) -> void:
	if not _is_reloading:
		_play_weapon_animation("Idle")


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)


func _apply_look(delta: Vector2) -> void:
	rotate_y(-delta.x * LOOK_SENSITIVITY)
	_look_pitch = clampf(
		_look_pitch - delta.y * LOOK_SENSITIVITY,
		-MAX_PITCH,
		MAX_PITCH
	)
	camera.rotation.x = clampf(_look_pitch + _recoil_pitch, -MAX_PITCH, MAX_PITCH)
