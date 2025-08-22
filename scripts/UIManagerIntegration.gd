extends Node

class_name UIManagerIntegration

# Пример интеграции новых систем с существующим UIManager
# Этот файл показывает, как добавить новые функции в существующий UI

@export var ui_manager: UIManager
@export var game_systems: GameSystemsManager

# UI элементы для новых функций
var purchase_panel: Panel
var invite_panel: Panel
var ad_settings_panel: Panel

func _ready():
	if not ui_manager:
		ui_manager = get_node_or_null("/root/UIManager")
	
	if not game_systems:
		game_systems = get_node_or_null("/root/GameSystemsManager")
	
	# Создаем панели для новых функций
	_create_additional_panels()
	
	# Интегрируем с существующим UI
	_integrate_with_existing_ui()

func _create_additional_panels() -> void:
	# Панель покупок
	purchase_panel = Panel.new()
	purchase_panel.name = "PurchasePanel"
	purchase_panel.visible = false
	purchase_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	purchase_panel.custom_minimum_size = Vector2(400, 500)
	
	var purchase_vbox = VBoxContainer.new()
	purchase_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	purchase_vbox.add_theme_constant_override("separation", 10)
	
	var purchase_title = Label.new()
	purchase_title.text = "Shop"
	purchase_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purchase_title.add_theme_font_size_override("font_size", 24)
	
	var purchase_ui_container = Control.new()
	purchase_ui_container.custom_minimum_size = Vector2(380, 400)
	
	var close_purchase_button = Button.new()
	close_purchase_button.text = "Close"
	close_purchase_button.custom_minimum_size = Vector2(100, 40)
	close_purchase_button.pressed.connect(func(): purchase_panel.hide())
	
	purchase_vbox.add_child(purchase_title)
	purchase_vbox.add_child(purchase_ui_container)
	purchase_vbox.add_child(close_purchase_button)
	purchase_panel.add_child(purchase_vbox)
	
	# Панель инвайтов
	invite_panel = Panel.new()
	invite_panel.name = "InvitePanel"
	invite_panel.visible = false
	invite_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	invite_panel.custom_minimum_size = Vector2(450, 600)
	
	var invite_vbox = VBoxContainer.new()
	invite_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	invite_vbox.add_theme_constant_override("separation", 10)
	
	var invite_title = Label.new()
	invite_title.text = "Invite Friends"
	invite_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invite_title.add_theme_font_size_override("font_size", 24)
	
	var invite_ui_container = Control.new()
	invite_ui_container.custom_minimum_size = Vector2(430, 500)
	
	var close_invite_button = Button.new()
	close_invite_button.text = "Close"
	close_invite_button.custom_minimum_size = Vector2(100, 40)
	close_invite_button.pressed.connect(func(): invite_panel.hide())
	
	invite_vbox.add_child(invite_title)
	invite_vbox.add_child(invite_ui_container)
	invite_vbox.add_child(close_invite_button)
	invite_panel.add_child(invite_vbox)
	
	# Панель настроек рекламы
	ad_settings_panel = Panel.new()
	ad_settings_panel.name = "AdSettingsPanel"
	ad_settings_panel.visible = false
	ad_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ad_settings_panel.custom_minimum_size = Vector2(500, 700)
	
	var ad_vbox = VBoxContainer.new()
	ad_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ad_vbox.add_theme_constant_override("separation", 10)
	
	var ad_title = Label.new()
	ad_title.text = "Ad Settings"
	ad_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_title.add_theme_font_size_override("font_size", 24)
	
	var ad_ui_container = Control.new()
	ad_ui_container.custom_minimum_size = Vector2(480, 600)
	
	var close_ad_button = Button.new()
	close_ad_button.text = "Close"
	close_ad_button.custom_minimum_size = Vector2(100, 40)
	close_ad_button.pressed.connect(func(): ad_settings_panel.hide())
	
	ad_vbox.add_child(ad_title)
	ad_vbox.add_child(ad_ui_container)
	ad_vbox.add_child(close_ad_button)
	ad_settings_panel.add_child(ad_vbox)

func _integrate_with_existing_ui() -> void:
	if not ui_manager:
		return
	
	# Добавляем панели в существующий UI
	ui_manager.add_child(purchase_panel)
	ui_manager.add_child(invite_panel)
	ui_manager.add_child(ad_settings_panel)
	
	# Добавляем кнопки в существующее меню
	_add_menu_buttons()
	
	# Интегрируем UI компоненты
	_integrate_ui_components()

func _add_menu_buttons() -> void:
	if not ui_manager:
		return
	
	# Ищем существующую панель настроек или создаем новую
	var settings_panel = ui_manager.get_node_or_null("SettingsPanel")
	if not settings_panel:
		# Создаем новую панель настроек если её нет
		settings_panel = Panel.new()
		settings_panel.name = "SettingsPanel"
		settings_panel.visible = false
		ui_manager.add_child(settings_panel)
	
	# Добавляем кнопки для новых функций
	var shop_button = Button.new()
	shop_button.text = "Shop"
	shop_button.custom_minimum_size = Vector2(120, 40)
	shop_button.pressed.connect(func(): _show_purchase_panel())
	
	var invite_button = Button.new()
	invite_button.text = "Invite Friends"
	invite_button.custom_minimum_size = Vector2(120, 40)
	invite_button.pressed.connect(func(): _show_invite_panel())
	
	var ad_settings_button = Button.new()
	ad_settings_button.text = "Ad Settings"
	ad_settings_button.custom_minimum_size = Vector2(120, 40)
	ad_settings_button.pressed.connect(func(): _show_ad_settings_panel())
	
	# Добавляем кнопки в панель настроек
	if settings_panel.has_method("add_child"):
		settings_panel.add_child(shop_button)
		settings_panel.add_child(invite_button)
		settings_panel.add_child(ad_settings_button)
	
	# Также добавляем кнопки в основное меню если есть
	var main_menu = ui_manager.get_node_or_null("MainMenu")
	if main_menu:
		main_menu.add_child(shop_button.duplicate())
		main_menu.add_child(invite_button.duplicate())
		main_menu.add_child(ad_settings_button.duplicate())

func _integrate_ui_components() -> void:
	if not game_systems:
		return
	
	# Получаем UI компоненты
	var purchase_ui = game_systems.get_purchase_ui()
	var invite_ui = game_systems.get_invite_params_ui()
	
	# Добавляем их в соответствующие панели
	if purchase_ui and purchase_panel:
		var container = purchase_panel.get_node_or_null("VBoxContainer/Control")
		if container:
			container.add_child(purchase_ui)
	
	if invite_ui and invite_panel:
		var container = invite_panel.get_node_or_null("VBoxContainer/Control")
		if container:
			container.add_child(invite_ui)

func _show_purchase_panel() -> void:
	if purchase_panel:
		purchase_panel.show()
		purchase_panel.raise()

func _show_invite_panel() -> void:
	if invite_panel:
		invite_panel.show()
		invite_panel.raise()

func _show_ad_settings_panel() -> void:
	if ad_settings_panel:
		ad_settings_panel.show()
		ad_settings_panel.raise()

# Методы для интеграции с игровыми событиями
func integrate_with_game_events() -> void:
	if not game_systems:
		return
	
	# Подключаем события игры к системам
	_connect_game_events()

func _connect_game_events() -> void:
	# Здесь должны быть подключения к сигналам игровых событий
	# Например, из BoardManager или других игровых систем
	
	# Пример подключения к событию окончания игры
	var board_manager = get_node_or_null("/root/BoardManager")
	if board_manager and board_manager.has_signal("game_over"):
		board_manager.game_over.connect(_on_game_over)

func _on_game_over(score: int) -> void:
	if game_systems:
		# Регистрируем событие окончания игры
		game_systems.trigger_game_event("game_over", {"score": score})
		
		# Показываем рекламу если можно
		if game_systems.can_show_ad("interstitial"):
			game_systems.show_ad("interstitial", "game_over")

# Методы для обновления существующего UI
func update_existing_ui() -> void:
	if not ui_manager:
		return
	
	# Обновляем счетчики бустеров
	_update_booster_display()
	
	# Обновляем статус рекламы
	_update_ad_status_display()

func _update_booster_display() -> void:
	# Обновляем отображение бустеров в существующем UI
	var booster_labels = ui_manager.get_tree().get_nodes_in_group("booster_labels")
	for label in booster_labels:
		if label.has_method("update_text"):
			label.update_text()

func _update_ad_status_display() -> void:
	if not game_systems:
		return
	
	# Показываем статус рекламы в UI
	var ad_status = game_systems.get_ad_quota_status("interstitial")
	var status_text = "Ads: " + str(ad_status.daily_remaining) + "/" + str(ad_status.get("daily_limit", 0))
	
	# Ищем или создаем label для статуса рекламы
	var ad_status_label = ui_manager.get_node_or_null("AdStatusLabel")
	if not ad_status_label:
		ad_status_label = Label.new()
		ad_status_label.name = "AdStatusLabel"
		ad_status_label.text = status_text
		ui_manager.add_child(ad_status_label)
	else:
		ad_status_label.text = status_text

# Методы для кастомизации
func customize_ui_theme() -> void:
	# Применяем кастомную тему к новым панелям
	if purchase_panel:
		purchase_panel.add_theme_stylebox_override("panel", _create_custom_stylebox())
	
	if invite_panel:
		invite_panel.add_theme_stylebox_override("panel", _create_custom_stylebox())
	
	if ad_settings_panel:
		ad_settings_panel.add_theme_stylebox_override("panel", _create_custom_stylebox())

func _create_custom_stylebox() -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.4, 0.4, 0.4)
	stylebox.corner_radius_top_left = 10
	stylebox.corner_radius_top_right = 10
	stylebox.corner_radius_bottom_left = 10
	stylebox.corner_radius_bottom_right = 10
	return stylebox

# Методы для тестирования интеграции
func test_integration() -> void:
	print("Testing UI integration...")
	
	# Тестируем показ панелей
	_show_purchase_panel()
	await get_tree().create_timer(2.0).timeout
	
	_show_invite_panel()
	await get_tree().create_timer(2.0).timeout
	
	_show_ad_settings_panel()
	await get_tree().create_timer(2.0).timeout
	
	# Скрываем все панели
	purchase_panel.hide()
	invite_panel.hide()
	ad_settings_panel.hide()
	
	print("UI integration test completed")