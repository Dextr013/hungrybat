extends Node

@export var bg_music: AudioStreamPlayer
@export var match_sfx: AudioStreamPlayer
@export var bomb_sfx: AudioStreamPlayer
@export var shuffle_sfx: AudioStreamPlayer

var music_enabled := true
var sfx_enabled := true
var music_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready():
	_apply_volumes()
	if bg_music and music_enabled:
		bg_music.play()

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if bg_music:
		if music_enabled and not bg_music.playing:
			bg_music.play()
		elif not music_enabled and bg_music.playing:
			bg_music.stop()

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled

func set_music_volume(vol: float) -> void:
	music_volume = clamp(vol, 0.0, 1.0)
	_apply_volumes()

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clamp(vol, 0.0, 1.0)
	_apply_volumes()

func _apply_volumes() -> void:
	if bg_music:
		bg_music.volume_db = linear_to_db(music_volume)
	if match_sfx:
		match_sfx.volume_db = linear_to_db(sfx_volume)
	if bomb_sfx:
		bomb_sfx.volume_db = linear_to_db(sfx_volume)
	if shuffle_sfx:
		shuffle_sfx.volume_db = linear_to_db(sfx_volume)

func play_match_sfx():
	if sfx_enabled and match_sfx:
		match_sfx.play()

func play_bomb_sfx():
	if sfx_enabled and bomb_sfx:
		bomb_sfx.play()

func play_shuffle_sfx():
	if sfx_enabled and shuffle_sfx:
		shuffle_sfx.play()
