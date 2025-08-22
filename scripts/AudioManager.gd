extends Node

@export var bg_music: AudioStreamPlayer
@export var match_sfx: AudioStreamPlayer

func _ready():
	if bg_music:
		bg_music.play()

func play_match_sfx():
	if match_sfx:
		match_sfx.play()
