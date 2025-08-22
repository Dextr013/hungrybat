extends Node

class_name PurchaseManager

signal purchase_initiated(item_id: String)
signal purchase_completed(item_id: String, token: String)
signal purchase_failed(item_id: String, error: String)
signal purchase_cancelled(item_id: String)

@export var yandex_sdk: Node
@export var notification_manager: Node

var current_purchase_item: String = ""
var is_purchase_in_progress: bool = false
var purchase_history: Array[Dictionary] = []

# Конфигурация покупок
var available_items: Dictionary = {
	"booster_pack": {
		"name": "Booster Pack",
		"description": "Get 5 boosters of each type",
		"price": "99",
		"currency": "RUB",
		"boosters": {
			"bomb": 5,
			"shuffle": 5,
			"extra_move": 5
		}
	},
	"premium_booster": {
		"name": "Premium Booster",
		"description": "Unlimited boosters for 24 hours",
		"price": "199",
		"currency": "RUB",
		"duration": 86400, # 24 hours in seconds
		"unlimited": true
	},
	"remove_ads": {
		"name": "Remove Ads",
		"description": "Remove all advertisements permanently",
		"price": "299",
		"currency": "RUB",
		"permanent": true
	}
}

func _ready():
	if yandex_sdk == null:
		yandex_sdk = get_node_or_null("/root/YandexSDKManager")
	
	if notification_manager == null:
		notification_manager = get_node_or_null("/root/NotificationManager")

func initiate_purchase(item_id: String) -> bool:
	if is_purchase_in_progress:
		_show_notification("Purchase already in progress", "error")
		return false
	
	if not available_items.has(item_id):
		_show_notification("Invalid item ID: " + item_id, "error")
		return false
	
	current_purchase_item = item_id
	is_purchase_in_progress = true
	
	emit_signal("purchase_initiated", item_id)
	_show_notification("Initiating purchase for " + available_items[item_id].name, "info")
	
	# Инициализируем платежи если SDK доступен
	if yandex_sdk and yandex_sdk.has_method("init_payments"):
		yandex_sdk.init_payments(false) # false = unsigned
	
	# Выполняем покупку
	_perform_purchase(item_id)
	
	return true

func _perform_purchase(item_id: String) -> void:
	if not yandex_sdk or not yandex_sdk.has_method("purchase"):
		_handle_purchase_failure(item_id, "Yandex SDK not available")
		return
	
	var payload = JSON.stringify({
		"item_id": item_id,
		"timestamp": Time.get_unix_time_from_system(),
		"user_id": _get_user_id()
	})
	
	# Вызываем покупку через SDK
	var purchase_result = await yandex_sdk.purchase(item_id, payload)
	_handle_purchase_result(item_id, purchase_result)

func _handle_purchase_result(item_id: String, result) -> void:
	if result == null:
		_handle_purchase_failure(item_id, "Purchase failed - no result")
		return
	
	# Обрабатываем результат покупки
	if result.has("status") and result.status == "success":
		_handle_purchase_success(item_id, result)
	else:
		var error_msg = result.get("error", "Unknown error")
		_handle_purchase_failure(item_id, error_msg)

func _handle_purchase_success(item_id: String, result: Dictionary) -> void:
	var token = result.get("token", "")
	
	# Сохраняем в историю
	var purchase_record = {
		"item_id": item_id,
		"token": token,
		"timestamp": Time.get_unix_time_from_system(),
		"status": "completed"
	}
	purchase_history.append(purchase_record)
	
	# Применяем эффекты покупки
	_apply_purchase_effects(item_id)
	
	# Потребляем покупку если нужно
	if token != "" and yandex_sdk and yandex_sdk.has_method("consume_purchase"):
		yandex_sdk.consume_purchase(token)
	
	is_purchase_in_progress = false
	current_purchase_item = ""
	
	emit_signal("purchase_completed", item_id, token)
	_show_notification("Purchase completed: " + available_items[item_id].name, "success")
	
	# Сохраняем данные
	_save_purchase_data()

func _handle_purchase_failure(item_id: String, error: String) -> void:
	is_purchase_in_progress = false
	current_purchase_item = ""
	
	emit_signal("purchase_failed", item_id, error)
	_show_notification("Purchase failed: " + error, "error")

func _apply_purchase_effects(item_id: String) -> void:
	var item = available_items[item_id]
	if not item:
		return
	
	# Применяем эффекты в зависимости от типа покупки
	if item.has("boosters"):
		_apply_booster_purchase(item.boosters)
	elif item.has("unlimited") and item.unlimited:
		_apply_unlimited_boosters(item.duration)
	elif item.has("permanent") and item.permanent:
		_apply_permanent_effect(item_id)
	
	# Обновляем UI если есть доступ к UIManager
	_update_ui_after_purchase()

func _apply_booster_purchase(boosters: Dictionary) -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var current_boosters = save_manager.get_boosters()
	for booster_type in boosters.keys():
		if current_boosters.has(booster_type):
			current_boosters[booster_type] = int(current_boosters[booster_type]) + int(boosters[booster_type])
		else:
			current_boosters[booster_type] = int(boosters[booster_type])
	
	save_manager.save_boosters(
		current_boosters.get("bomb", 0),
		current_boosters.get("shuffle", 0)
	)

func _apply_unlimited_boosters(duration: int) -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	# Устанавливаем флаг неограниченных бустеров
	var settings = save_manager.get_settings()
	settings["unlimited_boosters_until"] = Time.get_unix_time_from_system() + duration
	save_manager.save_settings(settings)

func _apply_permanent_effect(item_id: String) -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var settings = save_manager.get_settings()
	
	match item_id:
		"remove_ads":
			settings["ads_removed"] = true
		# Добавьте другие постоянные эффекты здесь
	
	save_manager.save_settings(settings)

func _update_ui_after_purchase() -> void:
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.has_method("_update_booster_labels"):
		ui_manager._update_booster_labels()

func _show_notification(message: String, type: String) -> void:
	if not notification_manager:
		print("[PurchaseManager] ", message)
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

func _get_user_id() -> String:
	# Получаем ID пользователя из SDK или генерируем локальный
	if yandex_sdk and yandex_sdk.has_method("get_data"):
		# Здесь должна быть логика получения ID пользователя
		return "local_user"
	return "local_user"

func _save_purchase_data() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	# Сохраняем историю покупок в настройках
	var settings = save_manager.get_settings()
	settings["purchase_history"] = purchase_history
	save_manager.save_settings(settings)

func load_purchase_data() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return
	
	var settings = save_manager.get_settings()
	if settings.has("purchase_history"):
		purchase_history = settings.purchase_history

func get_available_items() -> Dictionary:
	return available_items

func get_item_info(item_id: String) -> Dictionary:
	return available_items.get(item_id, {})

func is_purchase_available(item_id: String) -> bool:
	if not available_items.has(item_id):
		return false
	
	# Проверяем, не куплен ли уже постоянный эффект
	var item = available_items[item_id]
	if item.has("permanent") and item.permanent:
		var save_manager = get_node_or_null("/root/SaveManager")
		if save_manager:
			var settings = save_manager.get_settings()
			if settings.get("ads_removed", false) and item_id == "remove_ads":
				return false
	
	return true

func cancel_current_purchase() -> void:
	if not is_purchase_in_progress:
		return
	
	emit_signal("purchase_cancelled", current_purchase_item)
	is_purchase_in_progress = false
	current_purchase_item = ""
	_show_notification("Purchase cancelled", "warning")