extends Control

@onready var _ip_field: LineEdit = $Panel/Content/IpField
@onready var _status_label: Label = $Panel/Content/StatusLabel

var _leave_confirmation: ConfirmationDialog


func _ready() -> void:
	Net.match_ready.connect(_on_match_ready)
	Net.connection_error.connect(_on_connection_error)
	_leave_confirmation = ConfirmationDialog.new()
	_leave_confirmation.dialog_text = "Leave this lobby and disconnect from the match?"
	_leave_confirmation.confirmed.connect(_leave_lobby)
	add_child(_leave_confirmation)
	_status_label.text = "Host a match or join the host's Wi-Fi IP."


func _on_host_pressed() -> void:
	var error := Net.host_match()
	if error != OK:
		_show_error("Could not host match: %s" % error_string(error))
		return
	var addresses: PackedStringArray = Net.get_local_ipv4_addresses()
	if addresses.is_empty():
		_status_label.text = (
			"Hosting on port %d, but no LAN IPv4 address was found. "
			+ "Check Wi-Fi and firewall settings."
		) % Net.PORT
	else:
		_status_label.text = (
			"Hosting at %s:%d. On the other device, enter this address and join."
			% [", ".join(addresses), Net.PORT]
		)


func _on_join_pressed() -> void:
	var address := _ip_field.text.strip_edges()
	if address.is_empty():
		_show_error("Enter the host phone's Wi-Fi IP address.")
		return

	if not Net.is_valid_ipv4_address(address):
		_show_error("Enter a valid IPv4 address, for example 192.168.1.10.")
		return

	var error := Net.join_match(address)
	if error != OK:
		_show_error("Could not start connection: %s" % error_string(error))
		return
	_status_label.text = "Connecting... timeout in 5 seconds."


func _on_back_pressed() -> void:
	if Net.is_online_match:
		_leave_confirmation.popup_centered()
		return
	_leave_lobby()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _leave_lobby() -> void:
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
