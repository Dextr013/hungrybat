extends Node

class_name SaveManager

const SAVE_KEY = "PlayerData"
var score = 0
var level = 1

func save_score(new_score):
	score = new_score
	save_data()

func save_data():
	var data = { "score": score, "level": level }
	var json = JSON.stringify(data)
	# PlayerPrefs аналог — FileAccess
	var file = FileAccess.open("user://" + SAVE_KEY + ".json", FileAccess.WRITE)
	file.store_string(json)
	file.close()
	# Yandex SDK через аддон
	if has_node("/root/YandexSDK"):
		get_node("/root/YandexSDK").save_data(json)

func load_data(json_data):
	if json_data and json_data != "":
		var parsed = JSON.parse_string(json_data)
		score = parsed.score
		level = parsed.level
	else:
		if FileAccess.file_exists("user://" + SAVE_KEY + ".json"):
			var file = FileAccess.open("user://" + SAVE_KEY + ".json", FileAccess.READ)
			var json = file.get_as_text()
			var parsed = JSON.parse_string(json)
			score = parsed.score
			level = parsed.level
			file.close()

func get_score():
	return score

func get_level():
	return level
