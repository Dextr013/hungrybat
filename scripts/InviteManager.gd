extends Node

class_name InviteManager

signal invite_sent(success: bool, error: String)
signal invite_received(params: Dictionary)
signal invite_button_clicked

@export var yandex_sdk: Node
@export var notification_manager: Node

var invite_params: Dictionary = {}
var current_invite_link: String = ""
var invite_button_visible: bool = false

# Конфигурация инвайтов
var default_invite_params: Dictionary = {
	"game_mode": "classic",
	"difficulty": "normal",
	"booster_bonus": "true",
	"daily_challenge": "false"
}

# Доступные параметры для инвайтов
var available_params: Dictionary = {
	"game_mode": ["classic", "time_attack", "puzzle", "endless"],
	"difficulty": ["easy", "normal", "hard", "expert"],
	"booster_bonus": ["true", "false"],
	"daily_challenge": ["true", "false"],
	"custom_theme": ["default", "halloween", "christmas", "summer"],
	"special_rules": ["none", "no_boosters", "time_limit", "score_target"]
}

func _ready():
	if yandex_sdk == null:
		yandex_sdk = get_node_or_null("/root/YandexSDKManager")
	
	if notification_manager == null:
		notification_manager = get_node_or_null("/root/NotificationManager")
	
	# Загружаем сохраненные параметры инвайтов
	_load_invite_params()
	
	# Подключаемся к сигналам SDK если доступен
	if yandex_sdk:
		_connect_sdk_signals()

func _connect_sdk_signals() -> void:
	# Здесь должны быть подключения к сигналам SDK для инвайтов
	# Например: yandex_sdk.invite_received.connect(_on_invite_received)
	pass

func set_invite_param(key: String, value: String) -> bool:
	if not available_params.has(key):
		_show_notification("Invalid invite parameter: " + key, "error")
		return false
	
	if not available_params[key].has(value):
		_show_notification("Invalid value for parameter " + key + ": " + value, "error")
		return false
	
	invite_params[key] = value
	_save_invite_params()
	
	_show_notification("Invite parameter updated: " + key + " = " + value, "success")
	return true

func get_invite_param(key: String, default_value: String = "") -> String:
	return invite_params.get(key, default_value)

func get_all_invite_params() -> Dictionary:
	return invite_params.duplicate()

func reset_invite_params() -> void:
	invite_params = default_invite_params.duplicate()
	_save_invite_params()
	_show_notification("Invite parameters reset to default", "info")

func send_invite() -> void:
	if not yandex_sdk or not yandex_sdk.has_method("invite_link"):
		_show_notification("Yandex SDK not available for invites", "error")
		emit_signal("invite_sent", false, "SDK not available")
		return
	
	# Подготавливаем параметры для отправки
	var params_to_send = _prepare_invite_params()
	
	# Отправляем инвайт через SDK
	var invite_result = await yandex_sdk.invite_link(params_to_send)
	_handle_invite_result(invite_result)

func _prepare_invite_params() -> Dictionary:
	var params = invite_params.duplicate()
	
	# Добавляем метаданные
	params["timestamp"] = Time.get_unix_time_from_system()
	params["version"] = "1.0"
	params["platform"] = OS.get_name()
	
	# Добавляем пользовательские данные если есть
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		var settings = save_manager.get_settings()
		if settings.has("language"):
			params["language"] = settings.language
	
	return params

func _handle_invite_result(result) -> void:
	if result == null:
		_show_notification("Failed to send invite", "error")
		emit_signal("invite_sent", false, "No result from SDK")
		return
	
	if result.has("success") and result.success:
		current_invite_link = result.get("link", "")
		_show_notification("Invite sent successfully!", "success")
		emit_signal("invite_sent", true, "")
		
		# Сохраняем ссылку для последующего использования
		_save_invite_link()
	else:
		var error_msg = result.get("error", "Unknown error")
		_show_notification("Failed to send invite: " + error_msg, "error")
		emit_signal("invite_sent", false, error_msg)

func show_invite_button() -> void:
	if not yandex_sdk or not yandex_sdk.has_method("show_invite_button"):
		_show_notification("Cannot show invite button - SDK not available", "error")
		return
	
	invite_button_visible = true
	
	# Показываем кнопку инвайта через SDK
	var button_params = {
		"text": "Invite Friends",
		"position": "bottom_right",
		"callback": "invite_button_clicked"
	}
	
	yandex_sdk.show_invite_button(button_params)
	_show_notification("Invite button shown", "info")

func hide_invite_button() -> void:
	if not yandex_sdk or not yandex_sdk.has_method("hide_invite_button"):
		return
	
	invite_button_visible = false
	yandex_sdk.hide_invite_button()
	_show_notification("Invite button hidden", "info")

func process_invite_link(link: String) -> Dictionary:
	# Обрабатываем полученную ссылку инвайта
	var params = _parse_invite_link(link)
	
	if params.size() > 0:
		# Применяем параметры инвайта
		_apply_invite_params(params)
		
		# Уведомляем о получении инвайта
		emit_signal("invite_received", params)
		_show_notification("Invite parameters applied!", "success")
		
		return params
	else:
		_show_notification("Invalid invite link", "error")
		return {}

func _parse_invite_link(link: String) -> Dictionary:
	# Парсим ссылку инвайта и извлекаем параметры
	var params = {}
	
	# Простая реализация парсинга URL параметров
	if link.contains("?"):
		var query_part = link.split("?")[1]
		var pairs = query_part.split("&")
		
		for pair in pairs:
			if pair.contains("="):
				var key_value = pair.split("=")
				if key_value.size() == 2:
					var key = key_value[0]
					var value = key_value[1]
					
					# Декодируем URL-encoded значения
					value = value.uri_decode()
					
					# Проверяем валидность параметра
					if available_params.has(key) and available_params[key].has(value):
						params[key] = value
	
	return params

func _apply_invite_params(params: Dictionary) -> void:
	# Применяем полученные параметры инвайта
	for key in params.keys():
		if available_params.has(key):
			invite_params[key] = params[key]
	
	# Сохраняем обновленные параметры
	_save_invite_params()
	
	# Применяем параметры к игровому процессу
	_apply_gameplay_params(params)

func _apply_gameplay_params(params: Dictionary) -> void:
	# Применяем параметры к текущей игре
	var board_manager = get_node_or_null("/root/BoardManager")
	if not board_manager:
		return
	
	# Применяем режим игры
	if params.has("game_mode"):
		match params.game_mode:
			"time_attack":
				# Активируем режим игры на время
				pass
			"puzzle":
				# Активируем режим головоломки
				pass
			"endless":
				# Активируем бесконечный режим
				pass
	
	# Применяем сложность
	if params.has("difficulty"):
		match params.difficulty:
			"easy":
				# Устанавливаем легкую сложность
				pass
			"hard":
				# Устанавливаем сложную сложность
				pass
			"expert":
				# Устанавливаем экспертную сложность
				pass
	
	# Применяем бонус бустеров
	if params.has("booster_bonus") and params.booster_bonus == "true":
		# Даем бонусные бустеры
		_give_booster_bonus()

func _give_booster_bonus() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var current_boosters = save_manager.get_boosters()
	current_boosters["bomb"] = int(current_boosters.get("bomb", 0)) + 2
	current_boosters["shuffle"] = int(current_boosters.get("shuffle", 0)) + 2
	
	save_manager.save_boosters(
		current_boosters.get("bomb", 0),
		current_boosters.get("shuffle", 0)
	)
	
	_show_notification("Booster bonus applied from invite!", "success")

func _save_invite_params() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var settings = save_manager.get_settings()
	settings["invite_params"] = invite_params
	save_manager.save_settings(settings)

func _load_invite_params() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		invite_params = default_invite_params.duplicate()
		return
	
	var settings = save_manager.get_settings()
	if settings.has("invite_params"):
		invite_params = settings.invite_params
	else:
		invite_params = default_invite_params.duplicate()

func _save_invite_link() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var settings = save_manager.get_settings()
	settings["last_invite_link"] = current_invite_link
	save_manager.save_settings(settings)

func _show_notification(message: String, type: String) -> void:
	if not notification_manager:
		print("[InviteManager] ", message)
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

func get_available_params() -> Dictionary:
	return available_params.duplicate()

func is_param_valid(key: String, value: String) -> bool:
	if not available_params.has(key):
		return false
	
	return available_params[key].has(value)

func get_invite_summary() -> String:
	var summary = "Invite Parameters:\n"
	for key in invite_params.keys():
		summary += "• " + key + ": " + invite_params[key] + "\n"
	return summary