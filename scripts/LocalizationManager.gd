extends Node

var language: String = "en"

var _strings := {
	"en": {
		"score": "Score",
		"moves": "Moves",
		"pause": "Pause",
		"resume": "Resume",
		"settings": "Settings",
		"music": "Music",
		"sfx": "SFX",
	},
	"ru": {
		"score": "Очки",
		"moves": "Ходы",
		"pause": "Пауза",
		"resume": "Продолжить",
		"settings": "Настройки",
		"music": "Музыка",
		"sfx": "Звуки",
	}
}

func set_language(lang: String) -> void:
	if _strings.has(lang):
		language = lang

func trn(key: String) -> String:
	if _strings.has(language) and _strings[language].has(key):
		return _strings[language][key]
	return key