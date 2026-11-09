extends Node

signal match_ready
signal scores_updated
signal match_finished(won: bool, your_score: int, opponent_score: int, result_text: String)
signal restart_requested
signal connection_error(message: String)

const PORT := 2456
const TARGET_COUNT := 10
const JOIN_TIMEOUT_SECONDS := 5.0
const MODE_SELECT_SCENE := "res://scenes/ui/ModeSelect.tscn"

var is_online_match := false
var is_server := false
var match_seed := 1
var target_count := TARGET_COUNT
var host_score := 0
var client_score := 0
var _client_peer_id := 0
var _join_timeout_left := 0.0
var _match_active := false
var _scored_targets: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	if _join_timeout_left <= 0.0:
		return

	_join_timeout_left -= delta
	if _join_timeout_left <= 0.0 and not _match_active:
		_return_to_mode_select("Cannot reach host. Check that you are on the same Wi-Fi.")


func host_match(port: int = PORT) -> Error:
	_reset_match_state()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 1)
	if error != OK:
		return error

	multiplayer.multiplayer_peer = peer
	is_online_match = true
	is_server = true
	match_seed = int(randi() % 2147483646) + 1
	return OK


func get_local_ipv4_addresses() -> PackedStringArray:
	var addresses := PackedStringArray()
	for address in IP.get_local_addresses():
		if not is_valid_ipv4_address(address):
			continue
		if address.begins_with("127.") or address.begins_with("169.254."):
			continue
		addresses.append(address)
	return addresses


func is_valid_ipv4_address(address: String) -> bool:
	var octets := address.split(".", true)
	if octets.size() != 4:
		return false

	for octet in octets:
		if not octet.is_valid_int() or str(int(octet)) != octet:
			return false
		var value := int(octet)
		if value < 0 or value > 255:
			return false
	return true


func join_match(address: String, port: int = PORT) -> Error:
	var trimmed_address := address.strip_edges()
	if not is_valid_ipv4_address(trimmed_address):
		return ERR_INVALID_PARAMETER

	_reset_match_state()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(trimmed_address, port)
	if error != OK:
		return error

	multiplayer.multiplayer_peer = peer
	is_online_match = true
	is_server = false
	_join_timeout_left = JOIN_TIMEOUT_SECONDS
	return OK


func leave_match() -> void:
	_reset_match_state()
	multiplayer.multiplayer_peer = null


func submit_score(target_index: int) -> void:
	if not is_online_match or not _match_active:
		return
	if target_index < 0 or target_index >= target_count:
		push_error("Online score event has an invalid target index.")
		return

	if is_server:
		_accept_score(1, target_index)
	else:
		rpc_id(1, "request_score", target_index)


func restart_match() -> void:
	if not is_online_match or not _match_active:
		return
	if is_server:
		_start_new_round()
	else:
		rpc_id(1, "request_restart")


func finish_race_by_score() -> void:
	if not is_server or not _match_active:
		return
	if host_score > client_score:
		_finish_match(1)
	elif client_score > host_score:
		_finish_match(_client_peer_id)
	else:
		_finish_match(0)


func get_local_score() -> int:
	return host_score if is_server else client_score


func get_opponent_score() -> int:
	return client_score if is_server else host_score


func get_client_peer_id() -> int:
	return _client_peer_id


func _on_peer_connected(peer_id: int) -> void:
	if not is_server or _client_peer_id != 0:
		return

	_client_peer_id = peer_id
	_match_active = true
	_join_timeout_left = 0.0
	_scored_targets[1] = {}
	_scored_targets[peer_id] = {}
	receive_match_setup.rpc_id(peer_id, match_seed, target_count)
	match_ready.emit()


func _on_peer_disconnected(peer_id: int) -> void:
	if is_online_match and peer_id == _client_peer_id:
		_return_to_mode_select("Opponent disconnected. Returning to mode select.")


func _on_connection_failed() -> void:
	_return_to_mode_select("Cannot reach host. Check that you are on the same Wi-Fi.")


func _on_server_disconnected() -> void:
	_return_to_mode_select("Host disconnected. Returning to mode select.")


func _accept_score(peer_id: int, target_index: int) -> void:
	if not is_server or not _match_active:
		return
	if peer_id != 1 and peer_id != _client_peer_id:
		return

	var player_targets: Dictionary = _scored_targets.get(peer_id, {})
	if player_targets.has(target_index):
		return
	player_targets[target_index] = true
	_scored_targets[peer_id] = player_targets

	if peer_id == 1:
		host_score += 1
	else:
		client_score += 1

	sync_scores.rpc(host_score, client_score)
	if host_score >= target_count:
		_finish_match(1)
	elif client_score >= target_count:
		_finish_match(_client_peer_id)


func _finish_match(winner_peer_id: int) -> void:
	finish_match.rpc(winner_peer_id, host_score, client_score)


func _start_new_round() -> void:
	match_seed = int(randi() % 2147483646) + 1
	host_score = 0
	client_score = 0
	_scored_targets[1] = {}
	_scored_targets[_client_peer_id] = {}
	_match_active = true
	restart_round.rpc(match_seed, target_count)


func _return_to_mode_select(message: String) -> void:
	if not is_online_match:
		return

	connection_error.emit(message)
	_reset_match_state()
	multiplayer.multiplayer_peer = null
	GameState.current_mode = "campaign"
	GameState.menu_message = message
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(MODE_SELECT_SCENE)
	if error != OK:
		push_error("Could not return to mode select: %s" % error_string(error))


func _reset_match_state() -> void:
	_join_timeout_left = 0.0
	_match_active = false
	is_online_match = false
	is_server = false
	match_seed = 1
	target_count = TARGET_COUNT
	host_score = 0
	client_score = 0
	_client_peer_id = 0
	_scored_targets.clear()


@rpc("authority", "reliable")
func receive_match_setup(seed_value: int, target_total: int) -> void:
	match_seed = seed_value
	target_count = target_total
	host_score = 0
	client_score = 0
	_scored_targets[1] = {}
	_scored_targets[multiplayer.get_unique_id()] = {}
	_match_active = true
	_join_timeout_left = 0.0
	match_ready.emit()
	scores_updated.emit()


@rpc("any_peer", "reliable")
func request_score(target_index: int) -> void:
	if not is_server:
		return
	_accept_score(multiplayer.get_remote_sender_id(), target_index)


@rpc("authority", "call_local", "reliable")
func sync_scores(server_score: int, joining_score: int) -> void:
	host_score = server_score
	client_score = joining_score
	scores_updated.emit()


@rpc("authority", "call_local", "reliable")
func finish_match(winner_peer_id: int, server_score: int, joining_score: int) -> void:
	_match_active = false
	host_score = server_score
	client_score = joining_score
	_join_timeout_left = 0.0
	var won := multiplayer.get_unique_id() == winner_peer_id
	var your_score := get_local_score()
	var opponent_score := get_opponent_score()
	var result_text := "DRAW!" if winner_peer_id == 0 else ("YOU WIN!" if won else "OPPONENT WINS!")
	match_finished.emit(won, your_score, opponent_score, result_text)


@rpc("any_peer", "reliable")
func request_restart() -> void:
	if is_server:
		_start_new_round()


@rpc("authority", "call_local", "reliable")
func restart_round(seed_value: int, target_total: int) -> void:
	match_seed = seed_value
	target_count = target_total
	restart_requested.emit()
