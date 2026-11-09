extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ProjectSettings.get_setting(
		"input_devices/pointing/emulate_touch_from_mouse",
		false
	):
		push_error("Desktop mouse-to-touch emulation is not enabled.")
		quit(1)
		return

	var network: Node = root.get_node("Net")
	var audio: Node = root.get_node("AudioManager")
	if not network.call("is_valid_ipv4_address", "192.168.1.10"):
		push_error("A valid private IPv4 address was rejected.")
		quit(1)
		return
	if network.call("is_valid_ipv4_address", "host-name"):
		push_error("A hostname was accepted where IPv4 is required.")
		quit(1)
		return
	if network.call("is_valid_ipv4_address", "192.168.1.999"):
		push_error("An out-of-range IPv4 address was accepted.")
		quit(1)
		return
	var music_player: AudioStreamPlayer = audio.get("_music_player")
	var music_stream := music_player.stream as AudioStreamWAV
	if (
		music_stream == null
		or music_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD
		or music_stream.loop_end <= 0
	):
		push_error("The looping background music did not load correctly.")
		quit(1)
		return
	var sound_players: Dictionary = audio.get("_sound_players")
	if sound_players.size() != 6:
		push_error("Not all six game sound effects were loaded.")
		quit(1)
		return
	for sound_name in sound_players:
		var sound_player := sound_players[sound_name] as AudioStreamPlayer
		if sound_player.stream == null:
			push_error("Sound effect %s has no imported audio stream." % sound_name)
			quit(1)
			return
		audio.call("play_sound", sound_name)

	var local_addresses: PackedStringArray = network.call("get_local_ipv4_addresses")
	for address in local_addresses:
		if not network.call("is_valid_ipv4_address", address):
			push_error("The lobby advertised an invalid IPv4 address.")
			quit(1)
			return

	var level_paths := [
		"res://scenes/levels/Level01.tscn",
		"res://scenes/levels/Level02.tscn",
		"res://scenes/levels/Level03.tscn",
		"res://scenes/levels/Level04.tscn",
		"res://scenes/levels/Level05.tscn",
	]
	for index in range(level_paths.size()):
		var level: Node3D = load(level_paths[index]).instantiate() as Node3D
		root.add_child(level)
		await process_frame
		var message: String = level.get_node("HUD/MessageLabel").text
		var expected_title := "LEVEL %d:" % (index + 1)
		if not message.contains(expected_title) or not message.contains("Time:"):
			push_error("Level %d objective is missing its title or timer." % (index + 1))
			quit(1)
			return
		root.remove_child(level)
		level.free()
		await process_frame

	print("IPv4 validation and all five level objective introductions validated.")
	quit(0)
