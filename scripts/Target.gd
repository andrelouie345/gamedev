extends Area3D

signal hit

var _already_hit := false


func _ready() -> void:
	add_to_group("targets")


func register_hit() -> void:
	if _already_hit:
		return

	_already_hit = true
	hit.emit()
	queue_free()
