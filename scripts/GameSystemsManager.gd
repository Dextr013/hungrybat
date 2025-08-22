extends Node

class_name GameSystemsManager

# Основные системы
var notification_manager: NotificationManager
var purchase_manager: PurchaseManager
var invite_manager: InviteManager
var ad_quota_manager: AdQuotaManager

# UI компоненты
var purchase_ui: PurchaseUI
var invite_params_ui: InviteParamsUI

# Системы для интеграции
var yandex_sdk: Node
var save_manager: Node
var ui_manager: Node
var board_manager: Node

func _ready():
	# Инициализируем основные системы
	_initialize_systems()
	
	# Создаем UI компоненты
	_create_ui_components()
	
	# Подключаем сигналы
	_connect_signals()
	
	# Загружаем данные
	_load_system_data()
	
	print("GameSystemsManager initialized successfully")

func _initialize_systems() -> void:
	# Получаем ссылки на существующие системы
	yandex_sdk = get_node_or_null("/root/YandexSDKManager")
	save_manager = get_node_or_null("/root/SaveManager")
	ui_manager = get_node_or_null("/root/UIManager")
	board_manager = get_node_or_null("/root/BoardManager")
	
	# Создаем новые системы
	notification_manager = NotificationManager.new()
	notification_manager.name = "NotificationManager"
	add_child(notification_manager)
	
	purchase_manager = PurchaseManager.new()
	purchase_manager.name = "PurchaseManager"
	purchase_manager.yandex_sdk = yandex_sdk
	purchase_manager.notification_manager = notification_manager
	add_child(purchase_manager)
	
	invite_manager = InviteManager.new()
	invite_manager.name = "InviteManager"
	invite_manager.yandex_sdk = yandex_sdk
	invite_manager.notification_manager = notification_manager
	add_child(invite_manager)
	
	ad_quota_manager = AdQuotaManager.new()
	ad_quota_manager.name = "AdQuotaManager"
	ad_quota_manager.yandex_sdk = yandex_sdk
	ad_quota_manager.notification_manager = notification_manager
	add_child(ad_quota_manager)

func _create_ui_components() -> void:
	# Создаем UI для покупок
	purchase_ui = PurchaseUI.new()
	purchase_ui.name = "PurchaseUI"
	purchase_ui.purchase_manager = purchase_manager
	purchase_ui.notification_manager = notification_manager
	add_child(purchase_ui)
	
	# Создаем UI для параметров инвайтов
	invite_params_ui = InviteParamsUI.new()
	invite_params_ui.name = "InviteParamsUI"
	invite_params_ui.invite_manager = invite_manager
	invite_params_ui.notification_manager = notification_manager
	add_child(invite_params_ui)
	
	# Подключаем UI к менеджерам
	purchase_ui.connect_to_purchase_manager()
	invite_params_ui.connect_to_invite_manager()

func _connect_signals() -> void:
	# Подключаем сигналы покупок
	if purchase_manager:
		purchase_manager.purchase_completed.connect(_on_purchase_completed)
		purchase_manager.purchase_failed.connect(_on_purchase_failed)
	
	# Подключаем сигналы инвайтов
	if invite_manager:
		invite_manager.invite_received.connect(_on_invite_received)
	
	# Подключаем сигналы рекламы
	if ad_quota_manager:
		ad_quota_manager.ad_quota_exceeded.connect(_on_ad_quota_exceeded)
		ad_quota_manager.ad_show_triggered.connect(_on_ad_show_triggered)
	
	# Подключаем сигналы UI
	if purchase_ui:
		purchase_ui.purchase_requested.connect(_on_purchase_requested)
	
	if invite_params_ui:
		invite_params_ui.invite_params_updated.connect(_on_invite_params_updated)

func _load_system_data() -> void:
	# Загружаем данные покупок
	if purchase_manager:
		purchase_manager.load_purchase_data()
	
	# Загружаем данные инвайтов (автоматически в _ready)
	# Загружаем данные рекламы (автоматически в _ready)

# Обработчики сигналов покупок
func _on_purchase_completed(item_id: String, token: String) -> void:
	print("Purchase completed: ", item_id)
	
	# Обновляем UI если нужно
	if ui_manager and ui_manager.has_method("_update_booster_labels"):
		ui_manager._update_booster_labels()
	
	# Показываем уведомление об успехе
	notification_manager.show_success("Purchase completed successfully!")

func _on_purchase_failed(item_id: String, error: String) -> void:
	print("Purchase failed: ", item_id, " - ", error)
	
	# Показываем уведомление об ошибке
	notification_manager.show_error("Purchase failed: " + error)

func _on_purchase_requested(item_id: String) -> void:
	print("Purchase requested: ", item_id)
	
	# Здесь можно добавить дополнительную логику
	# Например, проверку баланса, подтверждение и т.д.

# Обработчики сигналов инвайтов
func _on_invite_received(params: Dictionary) -> void:
	print("Invite received with params: ", params)
	
	# Применяем параметры к игровому процессу
	_apply_invite_params_to_gameplay(params)
	
	# Показываем уведомление
	notification_manager.show_success("Invite parameters applied!")

func _on_invite_params_updated(params: Dictionary) -> void:
	print("Invite params updated: ", params)
	
	# Здесь можно добавить логику для применения параметров в реальном времени

# Обработчики сигналов рекламы
func _on_ad_quota_exceeded() -> void:
	print("Ad quota exceeded")
	
	# Показываем уведомление
	notification_manager.show_warning("Ad quota exceeded for today")

func _on_ad_show_triggered(reason: String) -> void:
	print("Ad show triggered: ", reason)
	
	# Логируем показ рекламы
	_log_ad_show(reason)

# Методы для интеграции с игровым процессом
func trigger_game_event(event_type: String, data: Dictionary = {}) -> void:
	# Передаем события в менеджер рекламы
	if ad_quota_manager:
		ad_quota_manager.trigger_ad_event(event_type, data)
	
	# Здесь можно добавить другие обработчики событий
	match event_type:
		"game_start":
			_handle_game_start(data)
		"game_over":
			_handle_game_over(data)
		"level_complete":
			_handle_level_complete(data)
		"booster_used":
			_handle_booster_used(data)

func _handle_game_start(data: Dictionary) -> void:
	# Логика для начала игры
	pass

func _handle_game_over(data: Dictionary) -> void:
	# Логика для окончания игры
	var score = data.get("score", 0)
	
	# Проверяем триггер рекламы для низкого счета
	if score < 100:
		ad_quota_manager.trigger_ad_event("low_score", {"score": score})

func _handle_level_complete(data: Dictionary) -> void:
	# Логика для завершения уровня
	pass

func _handle_booster_used(data: Dictionary) -> void:
	# Логика для использования бустера
	pass

func _apply_invite_params_to_gameplay(params: Dictionary) -> void:
	# Применяем параметры инвайта к игровому процессу
	if board_manager:
		# Здесь должна быть логика применения параметров
		# Например, изменение сложности, режима игры и т.д.
		pass

func _log_ad_show(reason: String) -> void:
	# Логируем показ рекламы для аналитики
	var log_data = {
		"timestamp": Time.get_unix_time_from_system(),
		"reason": reason,
		"ad_type": "interstitial" # или другой тип
	}
	
	# Сохраняем в настройках для аналитики
	if save_manager:
		var settings = save_manager.get_settings()
		if not settings.has("ad_analytics"):
			settings["ad_analytics"] = []
		
		settings.ad_analytics.append(log_data)
		save_manager.save_settings(settings)

# Публичные методы для внешнего доступа
func get_notification_manager() -> NotificationManager:
	return notification_manager

func get_purchase_manager() -> PurchaseManager:
	return purchase_manager

func get_invite_manager() -> InviteManager:
	return invite_manager

func get_ad_quota_manager() -> AdQuotaManager:
	return ad_quota_manager

func get_purchase_ui() -> PurchaseUI:
	return purchase_ui

func get_invite_params_ui() -> InviteParamsUI:
	return invite_params_ui

# Методы для управления рекламой
func show_ad(ad_type: String, trigger_reason: String = "") -> bool:
	if not ad_quota_manager:
		return false
	
	return ad_quota_manager.show_ad(ad_type, trigger_reason)

func can_show_ad(ad_type: String) -> bool:
	if not ad_quota_manager:
		return false
	
	return ad_quota_manager.can_show_ad(ad_type)

func get_ad_quota_status(ad_type: String) -> Dictionary:
	if not ad_quota_manager:
		return {}
	
	return ad_quota_manager.get_ad_quota_status(ad_type)

# Методы для управления покупками
func initiate_purchase(item_id: String) -> bool:
	if not purchase_manager:
		return false
	
	return purchase_manager.initiate_purchase(item_id)

func get_available_items() -> Dictionary:
	if not purchase_manager:
		return {}
	
	return purchase_manager.get_available_items()

# Методы для управления инвайтами
func send_invite() -> void:
	if invite_manager:
		invite_manager.send_invite()

func set_invite_param(key: String, value: String) -> bool:
	if not invite_manager:
		return false
	
	return invite_manager.set_invite_param(key, value)

func get_invite_params() -> Dictionary:
	if not invite_manager:
		return {}
	
	return invite_manager.get_all_invite_params()

# Методы для управления уведомлениями
func show_notification(message: String, type: String) -> void:
	if not notification_manager:
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

# Методы для интеграции с существующими системами
func integrate_with_ui_manager() -> void:
	if not ui_manager:
		return
	
	# Добавляем новые UI элементы в существующий UI менеджер
	# Здесь должна быть логика интеграции с существующим UI
	pass

func integrate_with_board_manager() -> void:
	if not board_manager:
		return
	
	# Интегрируем с менеджером игрового поля
	# Например, подключаем сигналы для триггеров рекламы
	pass

# Методы для отладки и тестирования
func test_notification_system() -> void:
	notification_manager.show_success("Test success notification")
	notification_manager.show_error("Test error notification")
	notification_manager.show_warning("Test warning notification")
	notification_manager.show_info("Test info notification")

func test_purchase_system() -> void:
	var items = get_available_items()
	for item_id in items.keys():
		print("Available item: ", item_id, " - ", items[item_id].name)

func test_invite_system() -> void:
	var params = get_invite_params()
	print("Current invite params: ", params)

func test_ad_system() -> void:
	var status = get_ad_quota_status("interstitial")
	print("Interstitial ad quota status: ", status)