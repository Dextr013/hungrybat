extends Node

var language: String = "en"

var _strings := {
	"en": {
		"score": "Score",
		"best": "Best",
		"moves": "Moves",
		"pause": "Pause",
		"resume": "Resume",
		"settings": "Settings",
		"music": "Music",
		"music_vol": "Music Vol",
		"sfx": "SFX",
		"sfx_vol": "SFX Vol",
		"daily_reward": "Daily Reward",
		"reward_claimed": "Reward claimed",
		"continue_question": "Continue game?",
		"continue": "Continue",
		"restart": "Restart",
	},
	"ru": {
		"score": "Очки",
		"best": "Рекорд",
		"moves": "Ходы",
		"pause": "Пауза",
		"resume": "Продолжить",
		"settings": "Настройки",
		"music": "Музыка",
		"music_vol": "Громкость музыки",
		"sfx": "Звуки",
		"sfx_vol": "Громкость звуков",
		"daily_reward": "Ежедневная награда",
		"reward_claimed": "Награда получена",
		"continue_question": "Продолжить игру?",
		"continue": "Продолжить",
		"restart": "Заново",
	}
}

func _ready() -> void:
	var loc := OS.get_locale()
	if loc.begins_with("ru"):
		language = "ru"
	else:
		language = "en"

func set_language(lang: String) -> void:
	if _strings.has(lang):
		language = lang

func trn(key: String) -> String:
	if _strings.has(language) and _strings[language].has(key):
		return _strings[language][key]
	return key