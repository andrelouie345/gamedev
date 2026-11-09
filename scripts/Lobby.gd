extends Control

@onready var _ip_field: LineEdit = $Panel/Content/IpField
@onready var _status_label: Label = $Panel/Content/StatusLabel


func _ready() -> void:
	Net.match_ready.connect(_on_match_ready)
	Net.connection_error.connect(_on_connection_error)
	_status_label.text = "Host a match or join the host's Wi-Fi IP."


func _on_host_pressed() -> void:
	var error := Net.host_match()
	if error != OK:
		_show_error("Could not host match: %s" % error_string(error))
		return
	_status_label.text = "Hosting on port %d. Waiting for one player..." % Net.PORT


func _on_join_pressed() -> void:
	var address := _ip_field.text.strip_edges()
	if address.is_empty():
		_show_error("Enter the host phone's Wi-Fi IP address.")
		return

	var error := Net.join_match(address)
	if error != OK:
		_return_to_mode_select(
			"Cannot reach host. Check that you are on the same Wi-Fi."
		)
		return
	_status_label.text = "Connecting... timeout in 5 seconds."


func _on_back_pressed() -> void:
	Net.leave_match()
	GameState.current_mode = "campaign"
	_change_scene("res://scenes/ui/ModeSelect.tscn")


func _on_match_ready() -> void:
	GameState.current_mode = "online"
	_change_scene("res://scenes/levels/Level01.tscn")


func _on_connection_error(message: String) -> void:
	GameState.menu_message = message


func _show_error(message: String) -> void:
	_status_label.text = message
	GameState.menu_message = message


func _return_to_mode_select(message: String) -> void:
	Net.leave_match()
	GameState.current_mode = "campaign"
	GameState.menu_message = message
	_change_scene("res://scenes/ui/ModeSelect.tscn")


func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not open scene %s: %s" % [path, error_string(error)])
