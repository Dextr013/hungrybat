extends Node

class_name AdQuotaManager

signal ad_quota_exceeded
signal ad_quota_reset
signal ad_show_triggered(reason: String)
signal ad_show_blocked(reason: String)

@export var yandex_sdk: Node
@export var notification_manager: Node

# Квоты показа рекламы
var ad_quotas: Dictionary = {
	"interstitial": {
		"daily_limit": 5,
		"hourly_limit": 2,
		"session_limit": 3,
		"min_interval": 60.0, # секунды между показами
		"current_daily": 0,
		"current_hourly": 0,
		"current_session": 0,
		"last_shown": 0.0
	},
	"rewarded": {
		"daily_limit": 10,
		"hourly_limit": 3,
		"session_limit": 5,
		"min_interval": 30.0,
		"current_daily": 0,
		"current_hourly": 0,
		"current_session": 0,
		"last_shown": 0.0
	},
	"banner": {
		"daily_limit": 50,
		"hourly_limit": 10,
		"session_limit": 20,
		"min_interval": 5.0,
		"current_daily": 0,
		"current_hourly": 0,
		"current_session": 0,
		"last_shown": 0.0
	}
}

# Антиспам настройки
var anti_spam_settings: Dictionary = {
	"enabled": true,
	"max_ads_per_minute": 2,
	"max_ads_per_hour": 8,
	"cooldown_after_spam": 300.0, # 5 минут
	"spam_detection_window": 3600.0, # 1 час
	"recent_ad_timestamps": []
}

# Триггеры показа рекламы
var ad_triggers: Dictionary = {
	"game_start": {
		"enabled": true,
		"probability": 0.3, # 30% шанс
		"min_games_between": 2,
		"games_since_last": 0
	},
	"game_over": {
		"enabled": true,
		"probability": 0.5, # 50% шанс
		"min_games_between": 1,
		"games_since_last": 0
	},
	"level_complete": {
		"enabled": true,
		"probability": 0.4, # 40% шанс
		"min_levels_between": 3,
		"levels_since_last": 0
	},
	"booster_used": {
		"enabled": true,
		"probability": 0.2, # 20% шанс
		"min_boosters_between": 5,
		"boosters_since_last": 0
	},
	"long_no_match_series": {
		"enabled": true,
		"probability": 0.6, # 60% шанс
		"min_moves_without_match": 10,
		"current_moves_without_match": 0
	},
	"low_score": {
		"enabled": true,
		"probability": 0.7, # 70% шанс
		"score_threshold": 100,
		"min_games_between": 2,
		"games_since_last": 0
	}
}

var session_start_time: float = 0.0
var last_daily_reset: String = ""
var last_hourly_reset: float = 0.0

func _ready():
	if yandex_sdk == null:
		yandex_sdk = get_node_or_null("/root/YandexSDKManager")
	
	if notification_manager == null:
		notification_manager = get_node_or_null("/root/NotificationManager")
	
	session_start_time = Time.get_unix_time_from_system()
	_load_ad_quota_data()
	_reset_daily_quotas_if_needed()
	_reset_hourly_quotas_if_needed()

func can_show_ad(ad_type: String) -> bool:
	if not ad_quotas.has(ad_type):
		return false
	
	var quota = ad_quotas[ad_type]
	var current_time = Time.get_unix_time_from_system()
	
	# Проверяем дневной лимит
	if quota.current_daily >= quota.daily_limit:
		emit_signal("ad_quota_exceeded")
		return false
	
	# Проверяем часовой лимит
	if quota.current_hourly >= quota.hourly_limit:
		emit_signal("ad_quota_exceeded")
		return false
	
	# Проверяем сессионный лимит
	if quota.current_session >= quota.session_limit:
		emit_signal("ad_quota_exceeded")
		return false
	
	# Проверяем минимальный интервал
	if current_time - quota.last_shown < quota.min_interval:
		emit_signal("ad_show_blocked", "Too soon since last ad")
		return false
	
	# Проверяем антиспам
	if not _check_anti_spam():
		emit_signal("ad_show_blocked", "Anti-spam protection active")
		return false
	
	return true

func show_ad(ad_type: String, trigger_reason: String = "") -> bool:
	if not can_show_ad(ad_type):
		return false
	
	# Проверяем триггеры
	if not _check_ad_triggers(trigger_reason):
		return false
	
	# Показываем рекламу
	var success = _display_ad(ad_type)
	
	if success:
		_record_ad_shown(ad_type, trigger_reason)
		emit_signal("ad_show_triggered", trigger_reason)
		return true
	
	return false

func _display_ad(ad_type: String) -> bool:
	if not yandex_sdk:
		return false
	
	match ad_type:
		"interstitial":
			if yandex_sdk.has_method("show_ad"):
				yandex_sdk.show_ad(func(): pass)
				return true
		"rewarded":
			if yandex_sdk.has_method("show_rewarded_ad"):
				yandex_sdk.show_rewarded_ad(func(): pass, func(): pass)
				return true
		"banner":
			if yandex_sdk.has_method("show_banner"):
				yandex_sdk.show_banner()
				return true
	
	return false

func _record_ad_shown(ad_type: String, trigger_reason: String) -> void:
	if not ad_quotas.has(ad_type):
		return
	
	var quota = ad_quotas[ad_type]
	var current_time = Time.get_unix_time_from_system()
	
	# Обновляем счетчики
	quota.current_daily += 1
	quota.current_hourly += 1
	quota.current_session += 1
	quota.last_shown = current_time
	
	# Записываем в антиспам
	anti_spam_settings.recent_ad_timestamps.append(current_time)
	
	# Очищаем старые записи антиспама
	_cleanup_anti_spam_records()
	
	# Сохраняем данные
	_save_ad_quota_data()
	
	# Проверяем необходимость сброса квот
	_reset_daily_quotas_if_needed()
	_reset_hourly_quotas_if_needed()

func _check_anti_spam() -> bool:
	if not anti_spam_settings.enabled:
		return true
	
	var current_time = Time.get_unix_time_from_system()
	var recent_ads = anti_spam_settings.recent_ad_timestamps
	
	# Проверяем количество рекламы в последнюю минуту
	var ads_last_minute = 0
	for timestamp in recent_ads:
		if current_time - timestamp < 60.0:
			ads_last_minute += 1
	
	if ads_last_minute >= anti_spam_settings.max_ads_per_minute:
		return false
	
	# Проверяем количество рекламы в последний час
	var ads_last_hour = 0
	for timestamp in recent_ads:
		if current_time - timestamp < 3600.0:
			ads_last_hour += 1
	
	if ads_last_hour >= anti_spam_settings.max_ads_per_hour:
		return false
	
	return true

func _check_ad_triggers(trigger_reason: String) -> bool:
	if trigger_reason == "":
		return true
	
	if not ad_triggers.has(trigger_reason):
		return true
	
	var trigger = ad_triggers[trigger_reason]
	if not trigger.enabled:
		return false
	
	# Проверяем минимальные интервалы
	if trigger.has("min_games_between") and trigger.games_since_last < trigger.min_games_between:
		return false
	
	if trigger.has("min_levels_between") and trigger.levels_since_last < trigger.min_levels_between:
		return false
	
	if trigger.has("min_boosters_between") and trigger.boosters_since_last < trigger.min_boosters_between:
		return false
	
	# Проверяем вероятность
	var random_value = randf()
	if random_value > trigger.probability:
		return false
	
	return true

func trigger_ad_event(event_type: String, data: Dictionary = {}) -> void:
	match event_type:
		"game_start":
			ad_triggers.game_start.games_since_last += 1
			if _should_show_ad_for_trigger("game_start"):
				show_ad("interstitial", "game_start")
		
		"game_over":
			ad_triggers.game_over.games_since_last += 1
			if _should_show_ad_for_trigger("game_over"):
				show_ad("interstitial", "game_over")
		
		"level_complete":
			ad_triggers.level_complete.levels_since_last += 1
			if _should_show_ad_for_trigger("level_complete"):
				show_ad("rewarded", "level_complete")
		
		"booster_used":
			ad_triggers.booster_used.boosters_since_last += 1
			if _should_show_ad_for_trigger("booster_used"):
				show_ad("interstitial", "booster_used")
		
		"long_no_match_series":
			ad_triggers.long_no_match_series.current_moves_without_match = data.get("moves_count", 0)
			if _should_show_ad_for_trigger("long_no_match_series"):
				show_ad("rewarded", "long_no_match_series")
		
		"low_score":
			ad_triggers.low_score.games_since_last += 1
			if _should_show_ad_for_trigger("low_score"):
				show_ad("interstitial", "low_score")
	
	# Сохраняем состояние триггеров
	_save_ad_quota_data()

func _should_show_ad_for_trigger(trigger_name: String) -> bool:
	if not ad_triggers.has(trigger_name):
		return false
	
	var trigger = ad_triggers[trigger_name]
	if not trigger.enabled:
		return false
	
	# Проверяем квоты
	if not can_show_ad("interstitial") and not can_show_ad("rewarded"):
		return false
	
	return true

func _cleanup_anti_spam_records() -> void:
	var current_time = Time.get_unix_time_from_system()
	var window = anti_spam_settings.spam_detection_window
	
	# Удаляем старые записи
	anti_spam_settings.recent_ad_timestamps = anti_spam_settings.recent_ad_timestamps.filter(
		func(timestamp): return current_time - timestamp < window
	)

func _reset_daily_quotas_if_needed() -> void:
	var today = Time.get_datetime_string_from_system().split("T")[0]
	
	if last_daily_reset != today:
		for ad_type in ad_quotas.keys():
			ad_quotas[ad_type].current_daily = 0
		
		last_daily_reset = today
		emit_signal("ad_quota_reset")

func _reset_hourly_quotas_if_needed() -> void:
	var current_time = Time.get_unix_time_from_system()
	var current_hour = int(current_time / 3600)
	
	if int(last_hourly_reset / 3600) != current_hour:
		for ad_type in ad_quotas.keys():
			ad_quotas[ad_type].current_hourly = 0
		
		last_hourly_reset = current_time

func reset_session_quotas() -> void:
	for ad_type in ad_quotas.keys():
		ad_quotas[ad_type].current_session = 0
	
	emit_signal("ad_quota_reset")

func get_ad_quota_status(ad_type: String) -> Dictionary:
	if not ad_quotas.has(ad_type):
		return {}
	
	var quota = ad_quotas[ad_type]
	return {
		"daily_remaining": quota.daily_limit - quota.current_daily,
		"hourly_remaining": quota.hourly_limit - quota.current_hourly,
		"session_remaining": quota.session_limit - quota.current_session,
		"time_until_next": max(0.0, quota.min_interval - (Time.get_unix_time_from_system() - quota.last_shown))
	}

func get_all_quotas_status() -> Dictionary:
	var status = {}
	for ad_type in ad_quotas.keys():
		status[ad_type] = get_ad_quota_status(ad_type)
	return status

func _save_ad_quota_data() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var data = {
		"ad_quotas": ad_quotas,
		"anti_spam_settings": anti_spam_settings,
		"ad_triggers": ad_triggers,
		"last_daily_reset": last_daily_reset,
		"last_hourly_reset": last_hourly_reset
	}
	
	var settings = save_manager.get_settings()
	settings["ad_quota_data"] = data
	save_manager.save_settings(settings)

func _load_ad_quota_data() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var settings = save_manager.get_settings()
	if settings.has("ad_quota_data"):
		var data = settings.ad_quota_data
		
		if data.has("ad_quotas"):
			ad_quotas = data.ad_quotas
		if data.has("anti_spam_settings"):
			anti_spam_settings = data.anti_spam_settings
		if data.has("ad_triggers"):
			ad_triggers = data.ad_triggers
		if data.has("last_daily_reset"):
			last_daily_reset = data.last_daily_reset
		if data.has("last_hourly_reset"):
			last_hourly_reset = data.last_hourly_reset

func _show_notification(message: String, type: String) -> void:
	if not notification_manager:
		print("[AdQuotaManager] ", message)
		return
	
	match type:
		"success":
			notification_manager.show_success(message)
		"error":
			notification_manager.show_error(message)
		"warning":
			notification_manager.show_warning(message)
		"info":
			notification_manager.show_info(message)

# Методы для настройки квот
func set_ad_quota(ad_type: String, quota_type: String, value: int) -> bool:
	if not ad_quotas.has(ad_type):
		return false
	
	if not ad_quotas[ad_type].has(quota_type):
		return false
	
	ad_quotas[ad_type][quota_type] = value
	_save_ad_quota_data()
	return true

func set_anti_spam_setting(setting: String, value) -> bool:
	if not anti_spam_settings.has(setting):
		return false
	
	anti_spam_settings[setting] = value
	_save_ad_quota_data()
	return true

func set_ad_trigger_setting(trigger: String, setting: String, value) -> bool:
	if not ad_triggers.has(trigger):
		return false
	
	if not ad_triggers[trigger].has(setting):
		return false
	
	ad_triggers[trigger][setting] = value
	_save_ad_quota_data()
	return true