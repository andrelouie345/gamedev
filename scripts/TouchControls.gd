extends Control

signal movement_changed(value: Vector2)
signal look_delta(value: Vector2)
signal fire_requested

const JOYSTICK_RADIUS := 108.0
const FIRE_RADIUS := 66.0

var _stick_touch_id := -1
var _look_touch_id := -1
var _fire_touch_id := -1
var _stick_offset := Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_touch(event.index, event.position)
		else:
			_end_touch(event.index)
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch_id:
			_update_stick(event.position)
		elif event.index == _look_touch_id:
			look_delta.emit(event.relative)


func _draw() -> void:
	var scale_factor := _ui_scale()
	var stick_center := _stick_center(scale_factor)
	var fire_center := _fire_center(scale_factor)
	var stick_radius := JOYSTICK_RADIUS * scale_factor
	var fire_radius := FIRE_RADIUS * scale_factor

	draw_circle(stick_center, stick_radius, Color(0.05, 0.07, 0.09, 0.48))
	draw_arc(stick_center, stick_radius, 0.0, TAU, 48, Color(0.85, 0.88, 0.9, 0.75), 3.0)
	draw_circle(stick_center + _stick_offset, stick_radius * 0.38, Color(0.78, 0.82, 0.85, 0.82))
	var fire_color := Color(0.65, 0.16, 0.12, 0.78)
	if _fire_touch_id != -1:
		fire_color = Color(0.9, 0.28, 0.2, 0.95)
	draw_circle(fire_center, fire_radius, fire_color)
	draw_arc(fire_center, fire_radius, 0.0, TAU, 48, Color(1.0, 0.85, 0.8, 0.95), 3.0)
	draw_string(
		ThemeDB.fallback_font,
		fire_center + Vector2(-34.0 * scale_factor, 9.0 * scale_factor),
		"FIRE",
		HORIZONTAL_ALIGNMENT_CENTER,
		68.0 * scale_factor,
		28,
		Color.WHITE
	)

	var center := size * 0.5
	draw_line(center + Vector2(-12, 0), center + Vector2(-4, 0), Color.WHITE, 2.0)
	draw_line(center + Vector2(4, 0), center + Vector2(12, 0), Color.WHITE, 2.0)
	draw_line(center + Vector2(0, -12), center + Vector2(0, -4), Color.WHITE, 2.0)
	draw_line(center + Vector2(0, 4), center + Vector2(0, 12), Color.WHITE, 2.0)


func _begin_touch(touch_id: int, position: Vector2) -> void:
	var scale_factor := _ui_scale()
	var fire_center := _fire_center(scale_factor)
	if position.distance_to(fire_center) <= FIRE_RADIUS * scale_factor:
		_fire_touch_id = touch_id
		fire_requested.emit()
		queue_redraw()
	elif (
		_stick_touch_id == -1
		and position.x < size.x * 0.48
		and position.y > size.y * 0.5
		and position.distance_to(_stick_center(scale_factor)) <= JOYSTICK_RADIUS * scale_factor * 1.8
	):
		_stick_touch_id = touch_id
		_update_stick(position)
	elif position.x >= size.x * 0.45 and _look_touch_id == -1:
		_look_touch_id = touch_id


func _end_touch(touch_id: int) -> void:
	if touch_id == _stick_touch_id:
		_stick_touch_id = -1
		_stick_offset = Vector2.ZERO
		movement_changed.emit(Vector2.ZERO)
		queue_redraw()
	elif touch_id == _look_touch_id:
		_look_touch_id = -1
	elif touch_id == _fire_touch_id:
		_fire_touch_id = -1
		queue_redraw()


func _update_stick(position: Vector2) -> void:
	var displacement := position - _stick_center(_ui_scale())
	var radius := JOYSTICK_RADIUS * _ui_scale()
	if displacement.length() > radius:
		displacement = displacement.normalized() * radius
	_stick_offset = displacement
	movement_changed.emit(displacement / radius)
	queue_redraw()


func _ui_scale() -> float:
	return minf(size.x / 1280.0, size.y / 720.0)


func _stick_center(scale_factor: float) -> Vector2:
	return Vector2(155.0 * scale_factor, size.y - 155.0 * scale_factor)


func _fire_center(scale_factor: float) -> Vector2:
	return Vector2(size.x - 125.0 * scale_factor, size.y - 125.0 * scale_factor)
