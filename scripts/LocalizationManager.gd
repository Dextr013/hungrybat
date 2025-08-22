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
		"show_banner": "Show Banner",
		"hide_banner": "Hide Banner",
		"login": "Login",
		"rewarded_test": "Show Rewarded",
		"lb_info": "LB Info",
		"lb_entry": "LB Entry",
		"lb_entries": "LB Entries",
		"pay_init": "Init Payments",
		"pay_buy": "Purchase",
		"pay_list": "Purchases",
		"pay_catalog": "Catalog",
		"pay_consume": "Consume",
		"review_can": "Can Review",
		"review_request": "Request Review",
		"invite_link": "Invite Link",
		"invite_get": "Get Invite Param",
		"invite_show_btn": "Show Invite Button",
		"invite_hide_btn": "Hide Invite Button",
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
		"show_banner": "Показать баннер",
		"hide_banner": "Скрыть баннер",
		"login": "Войти",
		"rewarded_test": "Показать наградную",
		"lb_info": "Таблица инфо",
		"lb_entry": "Запись игрока",
		"lb_entries": "Записи таблицы",
		"pay_init": "Инициализ. платежи",
		"pay_buy": "Покупка",
		"pay_list": "Покупки",
		"pay_catalog": "Каталог",
		"pay_consume": "Списать",
		"review_can": "Можно отзыв?",
		"review_request": "Запросить отзыв",
		"invite_link": "Ссылка-приглашение",
		"invite_get": "Парам. приглашения",
		"invite_show_btn": "Показать кнопку приглаш.",
		"invite_hide_btn": "Скрыть кнопку приглаш.",
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