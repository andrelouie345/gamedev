extends CharacterBody3D

signal fire_requested
signal health_changed(current_health: int, maximum_health: int)

const MOVE_SPEED := 5.0
const GRAVITY := 9.8
const LOOK_SENSITIVITY := 0.0025
const MAX_PITCH := deg_to_rad(80.0)
const MAX_HEALTH := 100

var _touch_move := Vector2.ZERO
var health := MAX_HEALTH

@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	# Keep the mouse visible until the player clicks, which makes desktop testing easier.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_to_group("player")


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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_request_fire()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_touch_movement_changed(value: Vector2) -> void:
	_touch_move = value


func _on_touch_look_delta(value: Vector2) -> void:
	_apply_look(value)


func _on_touch_fire_requested() -> void:
	_request_fire()


func _request_fire() -> void:
	fire_requested.emit()


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)


func _apply_look(delta: Vector2) -> void:
	rotate_y(-delta.x * LOOK_SENSITIVITY)
	camera.rotation.x = clampf(
		camera.rotation.x - delta.y * LOOK_SENSITIVITY,
		-MAX_PITCH,
		MAX_PITCH
	)
