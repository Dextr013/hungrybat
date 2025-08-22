extends Node

class_name SaveManager

const SAVE_KEY = "PlayerData"
var score = 0
var best_score = 0
var level = 1
var boosters := {
	"bomb": 3,
	"shuffle": 3,
}
var last_reward_date := ""
var settings := {
	"language": "en",
	"music_enabled": true,
	"sfx_enabled": true,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
}

func save_score(new_score):
	score = new_score
	if new_score > best_score:
		best_score = new_score
	save_data()

func save_boosters(new_bomb: int, new_shuffle: int) -> void:
	boosters["bomb"] = max(0, new_bomb)
	boosters["shuffle"] = max(0, new_shuffle)
	save_data()

func save_settings(new_settings: Dictionary) -> void:
	for k in new_settings.keys():
		settings[k] = new_settings[k]
	save_data()

func save_data():
	var data = {
		"score": score,
		"best_score": best_score,
		"level": level,
		"boosters": boosters,
		"last_reward_date": last_reward_date,
		"settings": settings,
	}
	var json = JSON.stringify(data)
	var file = FileAccess.open("user://" + SAVE_KEY + ".json", FileAccess.WRITE)
	file.store_string(json)
	file.close()
	if has_node("/root/YandexSDK"):
		get_node("/root/YandexSDK").save_data(json)

func load_data(json_data = ""):
	if json_data and json_data != "":
		var parsed = JSON.parse_string(json_data)
		_apply_loaded(parsed)
	else:
		if FileAccess.file_exists("user://" + SAVE_KEY + ".json"):
			var file = FileAccess.open("user://" + SAVE_KEY + ".json", FileAccess.READ)
			var json = file.get_as_text()
			var parsed = JSON.parse_string(json)
			_apply_loaded(parsed)
			file.close()

func _apply_loaded(parsed):
	score = parsed.score
	best_score = parsed.has("best_score") ? int(parsed.best_score) : 0
	level = parsed.level
	if parsed.has("boosters"): boosters = parsed.boosters
	if parsed.has("last_reward_date"): last_reward_date = String(parsed.last_reward_date)
	if parsed.has("settings"): settings = parsed.settings

func get_score():
	return score

func get_best_score():
	return best_score

func get_level():
	return level

func get_boosters():
	return boosters

func get_settings():
	return settings

func can_claim_daily_reward(today_str: String) -> bool:
	return last_reward_date != today_str

func claim_daily_reward(today_str: String) -> void:
	last_reward_date = today_str
	boosters["bomb"] = int(boosters.get("bomb", 0)) + 1
	boosters["shuffle"] = int(boosters.get("shuffle", 0)) + 1
	save_data()
