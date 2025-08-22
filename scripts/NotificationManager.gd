extends CanvasLayer

class_name NotificationManager

signal notification_shown
signal notification_hidden

@export var notification_scene: PackedScene
@export var notification_container: Control

var notifications: Array[Control] = []
var max_notifications: int = 3
var notification_duration: float = 3.0

enum NotificationType {
	SUCCESS,
	ERROR,
	WARNING,
	INFO
}

func _ready():
	if notification_container == null:
		notification_container = self
	
	# Создаем базовый контейнер для уведомлений если не задан
	if not notification_container.has_method("add_child"):
		var container = Control.new()
		container.name = "NotificationContainer"
		container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		container.position = Vector2(-20, 20)
		container.size = Vector2(300, 0)
		add_child(container)
		notification_container = container

func show_notification(message: String, type: NotificationType = NotificationType.INFO, duration: float = -1.0) -> Control:
	# Удаляем старые уведомления если превышен лимит
	if notifications.size() >= max_notifications:
		_remove_oldest_notification()
	
	# Создаем уведомление
	var notification = _create_notification(message, type)
	notifications.append(notification)
	
	# Показываем уведомление
	notification_container.add_child(notification)
	notification.visible = true
	
	# Анимация появления
	notification.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	
	# Автоматическое скрытие
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		hide_notification(notification)
	elif duration == -1.0:
		await get_tree().create_timer(notification_duration).timeout
		hide_notification(notification)
	
	emit_signal("notification_shown", notification)
	return notification

func hide_notification(notification: Control) -> void:
	if not notification or not is_instance_valid(notification):
		return
	
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	notifications.erase(notification)
	notification.queue_free()
	emit_signal("notification_hidden", notification)

func _create_notification(message: String, type: NotificationType) -> Control:
	var notification: Control
	
	if notification_scene:
		notification = notification_scene.instantiate()
	else:
		notification = _create_default_notification()
	
	# Настраиваем текст и стиль
	_setup_notification(notification, message, type)
	
	# Позиционируем уведомление
	notification.position.y = notifications.size() * 80
	
	return notification

func _create_default_notification() -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 70)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	
	var label = Label.new()
	label.text = "Notification"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	vbox.add_child(label)
	panel.add_child(vbox)
	
	return panel

func _setup_notification(notification: Control, message: String, type: NotificationType) -> void:
	var label = notification.get_node_or_null("VBoxContainer/Label")
	if not label:
		label = notification.get_node_or_null("Label")
	
	if label:
		label.text = message
	
	# Применяем стиль в зависимости от типа
	match type:
		NotificationType.SUCCESS:
			notification.modulate = Color(0.2, 0.8, 0.2)
		NotificationType.ERROR:
			notification.modulate = Color(0.8, 0.2, 0.2)
		NotificationType.WARNING:
			notification.modulate = Color(0.8, 0.8, 0.2)
		NotificationType.INFO:
			notification.modulate = Color(0.2, 0.6, 0.8)

func _remove_oldest_notification() -> void:
	if notifications.size() > 0:
		hide_notification(notifications[0])

# Удобные методы для разных типов уведомлений
func show_success(message: String, duration: float = -1.0) -> Control:
	return show_notification(message, NotificationType.SUCCESS, duration)

func show_error(message: String, duration: float = -1.0) -> Control:
	return show_notification(message, NotificationType.ERROR, duration)

func show_warning(message: String, duration: float = -1.0) -> Control:
	return show_notification(message, NotificationType.WARNING, duration)

func show_info(message: String, duration: float = -1.0) -> Control:
	return show_notification(message, NotificationType.INFO, duration)

# Очистка всех уведомлений
func clear_all_notifications() -> void:
	for notification in notifications.duplicate():
		hide_notification(notification)