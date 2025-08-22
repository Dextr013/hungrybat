extends Control

class_name PurchaseUI

signal purchase_requested(item_id: String)
signal purchase_cancelled

@export var purchase_manager: Node
@export var notification_manager: Node

@export var item_id_input: LineEdit
@export var purchase_button: Button
@export var cancel_button: Button
@export var item_info_label: RichTextLabel
@export var price_label: Label
@export var description_label: Label

var current_item_info: Dictionary = {}

func _ready():
	if purchase_manager == null:
		purchase_manager = get_node_or_null("/root/PurchaseManager")
	
	if notification_manager == null:
		notification_manager = get_node_or_null("/root/NotificationManager")
	
	# Создаем UI элементы если они не заданы
	_setup_ui_elements()
	
	# Подключаем сигналы
	_connect_signals()
	
	# Инициализируем UI
	_update_ui()

func _setup_ui_elements() -> void:
	if item_id_input == null:
		item_id_input = LineEdit.new()
		item_id_input.placeholder_text = "Enter Item ID (e.g., booster_pack)"
		item_id_input.custom_minimum_size = Vector2(200, 30)
		add_child(item_id_input)
	
	if purchase_button == null:
		purchase_button = Button.new()
		purchase_button.text = "Purchase"
		purchase_button.custom_minimum_size = Vector2(100, 40)
		add_child(purchase_button)
	
	if cancel_button == null:
		cancel_button = Button.new()
		cancel_button.text = "Cancel"
		cancel_button.custom_minimum_size = Vector2(100, 40)
		add_child(cancel_button)
	
	if item_info_label == null:
		item_info_label = RichTextLabel.new()
		item_info_label.custom_minimum_size = Vector2(300, 100)
		item_info_label.bbcode_enabled = true
		add_child(item_info_label)
	
	if price_label == null:
		price_label = Label.new()
		price_label.text = "Price: --"
		add_child(price_label)
	
	if description_label == null:
		description_label = Label.new()
		description_label.text = "Description: --"
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.custom_minimum_size = Vector2(300, 60)
		add_child(description_label)

func _connect_signals() -> void:
	if item_id_input:
		item_id_input.text_changed.connect(_on_item_id_changed)
		item_id_input.text_submitted.connect(_on_item_id_submitted)
	
	if purchase_button:
		purchase_button.pressed.connect(_on_purchase_pressed)
	
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)

func _on_item_id_changed(new_text: String) -> void:
	_update_item_info(new_text)

func _on_item_id_submitted(new_text: String) -> void:
	_update_item_info(new_text)
	_on_purchase_pressed()

func _on_purchase_pressed() -> void:
	var item_id = item_id_input.text.strip_edges()
	
	if item_id.is_empty():
		_show_notification("Please enter an Item ID", "warning")
		return
	
	if not purchase_manager:
		_show_notification("Purchase manager not available", "error")
		return
	
	# Проверяем доступность покупки
	if not purchase_manager.is_purchase_available(item_id):
		_show_notification("Item not available for purchase", "error")
		return
	
	# Инициируем покупку
	var success = purchase_manager.initiate_purchase(item_id)
	
	if success:
		emit_signal("purchase_requested", item_id)
		_show_notification("Purchase initiated for " + item_id, "info")
	else:
		_show_notification("Failed to initiate purchase", "error")

func _on_cancel_pressed() -> void:
	emit_signal("purchase_cancelled")
	hide()

func _update_item_info(item_id: String) -> void:
	if not purchase_manager:
		return
	
	var item_info = purchase_manager.get_item_info(item_id)
	current_item_info = item_info
	
	if item_info.is_empty():
		_clear_item_info()
		return
	
	# Обновляем информацию об элементе
	_update_item_display(item_info)

func _update_item_display(item_info: Dictionary) -> void:
	# Обновляем название
	if item_info.has("name"):
		item_info_label.text = "[b]" + item_info.name + "[/b]"
	
	# Обновляем цену
	if item_info.has("price") and item_info.has("currency"):
		price_label.text = "Price: " + item_info.price + " " + item_info.currency
	else:
		price_label.text = "Price: --"
	
	# Обновляем описание
	if item_info.has("description"):
		description_label.text = "Description: " + item_info.description
	else:
		description_label.text = "Description: --"
	
	# Обновляем детальную информацию
	var details = _format_item_details(item_info)
	item_info_label.text += "\n\n" + details

func _format_item_details(item_info: Dictionary) -> String:
	var details = ""
	
	# Информация о бустерах
	if item_info.has("boosters"):
		details += "[b]Boosters:[/b]\n"
		for booster_type in item_info.boosters.keys():
			details += "• " + booster_type.capitalize() + ": " + str(item_info.boosters[booster_type]) + "\n"
	
	# Информация о длительности
	if item_info.has("duration"):
		var hours = item_info.duration / 3600.0
		details += "[b]Duration:[/b] " + str(hours) + " hours\n"
	
	# Информация о типе
	if item_info.has("unlimited") and item_info.unlimited:
		details += "[b]Type:[/b] Unlimited boosters\n"
	
	if item_info.has("permanent") and item_info.permanent:
		details += "[b]Type:[/b] Permanent effect\n"
	
	return details

func _clear_item_info() -> void:
	item_info_label.text = "Enter an Item ID to see details"
	price_label.text = "Price: --"
	description_label.text = "Description: --"
	current_item_info = {}

func _update_ui() -> void:
	# Обновляем состояние кнопок
	if purchase_button:
		purchase_button.disabled = current_item_info.is_empty()
	
	# Обновляем доступность покупки
	if not current_item_info.is_empty() and purchase_manager:
		var item_id = item_id_input.text.strip_edges()
		var is_available = purchase_manager.is_purchase_available(item_id)
		purchase_button.disabled = not is_available
		
		if not is_available:
			purchase_button.text = "Not Available"
		else:
			purchase_button.text = "Purchase"

func _show_notification(message: String, type: String) -> void:
	if not notification_manager:
		print("[PurchaseUI] ", message)
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

# Публичные методы для внешнего управления
func set_item_id(item_id: String) -> void:
	if item_id_input:
		item_id_input.text = item_id
		_update_item_info(item_id)

func get_current_item_id() -> String:
	if item_id_input:
		return item_id_input.text.strip_edges()
	return ""

func is_item_selected() -> bool:
	return not current_item_info.is_empty()

func refresh_item_info() -> void:
	var current_id = get_current_item_id()
	if not current_id.is_empty():
		_update_item_info(current_id)

# Методы для интеграции с другими системами
func connect_to_purchase_manager() -> void:
	if not purchase_manager:
		return
	
	# Подключаемся к сигналам менеджера покупок
	if purchase_manager.has_signal("purchase_initiated"):
		purchase_manager.purchase_initiated.connect(_on_purchase_initiated)
	
	if purchase_manager.has_signal("purchase_completed"):
		purchase_manager.purchase_completed.connect(_on_purchase_completed)
	
	if purchase_manager.has_signal("purchase_failed"):
		purchase_manager.purchase_failed.connect(_on_purchase_failed)

func _on_purchase_initiated(item_id: String) -> void:
	_show_notification("Purchase started for " + item_id, "info")
	purchase_button.disabled = true
	purchase_button.text = "Processing..."

func _on_purchase_completed(item_id: String, token: String) -> void:
	_show_notification("Purchase completed successfully!", "success")
	purchase_button.disabled = false
	purchase_button.text = "Purchase"
	
	# Очищаем поле ввода
	if item_id_input:
		item_id_input.text = ""
		_clear_item_info()

func _on_purchase_failed(item_id: String, error: String) -> void:
	_show_notification("Purchase failed: " + error, "error")
	purchase_button.disabled = false
	purchase_button.text = "Purchase"

# Методы для кастомизации UI
func set_button_texts(purchase_text: String, cancel_text: String) -> void:
	if purchase_button:
		purchase_button.text = purchase_text
	
	if cancel_button:
		cancel_button.text = cancel_text

func set_placeholder_text(placeholder: String) -> void:
	if item_id_input:
		item_id_input.placeholder_text = placeholder

func set_input_field_size(width: float, height: float) -> void:
	if item_id_input:
		item_id_input.custom_minimum_size = Vector2(width, height)

func set_button_size(width: float, height: float) -> void:
	if purchase_button:
		purchase_button.custom_minimum_size = Vector2(width, height)
	
	if cancel_button:
		cancel_button.custom_minimum_size = Vector2(width, height)