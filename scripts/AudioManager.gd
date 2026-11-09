extends Node

const MUSIC_PATH := "res://assets/audio/range_theme.wav"
const SOUND_PATHS := {
	"shot": "res://assets/audio/shot.wav",
	"target_hit": "res://assets/audio/target_hit.wav",
	"enemy_destroy": "res://assets/audio/enemy_destroy.wav",
	"victory": "res://assets/audio/victory.wav",
	"defeat": "res://assets/audio/defeat.wav",
	"level_unlock": "res://assets/audio/level_unlock.wav",
}

var _music_player: AudioStreamPlayer
var _sound_players: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	_music_player.volume_db = -22.0
	add_child(_music_player)
	var music_stream := load(MUSIC_PATH) as AudioStreamWAV
	if music_stream == null:
		push_error("Could not load background music: %s" % MUSIC_PATH)
	else:
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music_stream.loop_begin = 0
		music_stream.loop_end = music_stream.data.size() / 2
		_music_player.stream = music_stream
		if DisplayServer.get_name() != "headless":
			_music_player.play()

	for sound_name in SOUND_PATHS:
		var player := AudioStreamPlayer.new()
		player.name = sound_name
		player.volume_db = -8.0
		player.stream = load(SOUND_PATHS[sound_name]) as AudioStreamWAV
		if player.stream == null:
			push_error("Could not load sound effect: %s" % SOUND_PATHS[sound_name])
		add_child(player)
		_sound_players[sound_name] = player


func _exit_tree() -> void:
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	for value in _sound_players.values():
		var player := value as AudioStreamPlayer
		player.stop()
		player.stream = null
	_sound_players.clear()


func play_sound(sound_name: String) -> void:
	if not _sound_players.has(sound_name):
		push_error("Unknown sound effect: %s" % sound_name)
		return
	if DisplayServer.get_name() == "headless":
		return

	var player := _sound_players[sound_name] as AudioStreamPlayer
	if player.stream == null:
		push_error("Sound effect %s has no audio stream." % sound_name)
		return
	player.stop()
	player.play()
