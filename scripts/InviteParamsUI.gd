extends Control

class_name InviteParamsUI

signal invite_params_updated(params: Dictionary)
signal invite_sent(success: bool)

@export var invite_manager: Node
@export var notification_manager: Node

@export var game_mode_dropdown: OptionButton
@export var difficulty_dropdown: OptionButton
@export var booster_bonus_checkbox: CheckBox
@export var daily_challenge_checkbox: CheckBox
@export var custom_theme_dropdown: OptionButton
@export var special_rules_dropdown: OptionButton
@export var send_invite_button: Button
@export var reset_params_button: Button
@export var params_summary_label: RichTextLabel

var current_params: Dictionary = {}

func _ready():
	if invite_manager == null:
		invite_manager = get_node_or_null("/root/InviteManager")
	
	if notification_manager == null:
		notification_manager = get_node_or_null("/root/NotificationManager")
	
	# Создаем UI элементы если они не заданы
	_setup_ui_elements()
	
	# Подключаем сигналы
	_connect_signals()
	
	# Инициализируем UI
	_initialize_ui()
	_update_params_display()

func _setup_ui_elements() -> void:
	# Game Mode Dropdown
	if game_mode_dropdown == null:
		game_mode_dropdown = OptionButton.new()
		game_mode_dropdown.custom_minimum_size = Vector2(200, 30)
		add_child(game_mode_dropdown)
	
	# Difficulty Dropdown
	if difficulty_dropdown == null:
		difficulty_dropdown = OptionButton.new()
		difficulty_dropdown.custom_minimum_size = Vector2(200, 30)
		add_child(difficulty_dropdown)
	
	# Booster Bonus Checkbox
	if booster_bonus_checkbox == null:
		booster_bonus_checkbox = CheckBox.new()
		booster_bonus_checkbox.text = "Booster Bonus"
		add_child(booster_bonus_checkbox)
	
	# Daily Challenge Checkbox
	if daily_challenge_checkbox == null:
		daily_challenge_checkbox = CheckBox.new()
		daily_challenge_checkbox.text = "Daily Challenge"
		add_child(daily_challenge_checkbox)
	
	# Custom Theme Dropdown
	if custom_theme_dropdown == null:
		custom_theme_dropdown = OptionButton.new()
		custom_theme_dropdown.custom_minimum_size = Vector2(200, 30)
		add_child(custom_theme_dropdown)
	
	# Special Rules Dropdown
	if special_rules_dropdown == null:
		special_rules_dropdown = OptionButton.new()
		special_rules_dropdown.custom_minimum_size = Vector2(200, 30)
		add_child(special_rules_dropdown)
	
	# Send Invite Button
	if send_invite_button == null:
		send_invite_button = Button.new()
		send_invite_button.text = "Send Invite"
		send_invite_button.custom_minimum_size = Vector2(120, 40)
		add_child(send_invite_button)
	
	# Reset Params Button
	if reset_params_button == null:
		reset_params_button = Button.new()
		reset_params_button.text = "Reset to Default"
		reset_params_button.custom_minimum_size = Vector2(120, 40)
		add_child(reset_params_button)
	
	# Params Summary Label
	if params_summary_label == null:
		params_summary_label = RichTextLabel.new()
		params_summary_label.custom_minimum_size = Vector2(300, 150)
		params_summary_label.bbcode_enabled = true
		add_child(params_summary_label)

func _connect_signals() -> void:
	if game_mode_dropdown:
		game_mode_dropdown.item_selected.connect(_on_game_mode_changed)
	
	if difficulty_dropdown:
		difficulty_dropdown.item_selected.connect(_on_difficulty_changed)
	
	if booster_bonus_checkbox:
		booster_bonus_checkbox.toggled.connect(_on_booster_bonus_changed)
	
	if daily_challenge_checkbox:
		daily_challenge_checkbox.toggled.connect(_on_daily_challenge_changed)
	
	if custom_theme_dropdown:
		custom_theme_dropdown.item_selected.connect(_on_custom_theme_changed)
	
	if special_rules_dropdown:
		special_rules_dropdown.item_selected.connect(_on_special_rules_changed)
	
	if send_invite_button:
		send_invite_button.pressed.connect(_on_send_invite_pressed)
	
	if reset_params_button:
		reset_params_button.pressed.connect(_on_reset_params_pressed)

func _initialize_ui() -> void:
	if not invite_manager:
		return
	
	var available_params = invite_manager.get_available_params()
	
	# Инициализируем Game Mode dropdown
	if game_mode_dropdown and available_params.has("game_mode"):
		game_mode_dropdown.clear()
		for i in range(available_params.game_mode.size()):
			var mode = available_params.game_mode[i]
			game_mode_dropdown.add_item(mode.capitalize(), i)
	
	# Инициализируем Difficulty dropdown
	if difficulty_dropdown and available_params.has("difficulty"):
		difficulty_dropdown.clear()
		for i in range(available_params.difficulty.size()):
			var diff = available_params.difficulty[i]
			difficulty_dropdown.add_item(diff.capitalize(), i)
	
	# Инициализируем Custom Theme dropdown
	if custom_theme_dropdown and available_params.has("custom_theme"):
		custom_theme_dropdown.clear()
		for i in range(available_params.custom_theme.size()):
			var theme = available_params.custom_theme[i]
			custom_theme_dropdown.add_item(theme.capitalize(), i)
	
	# Инициализируем Special Rules dropdown
	if special_rules_dropdown and available_params.has("special_rules"):
		special_rules_dropdown.clear()
		for i in range(available_params.special_rules.size()):
			var rule = available_params.special_rules[i]
			special_rules_dropdown.add_item(rule.capitalize(), i)
	
	# Загружаем текущие параметры
	_load_current_params()

func _load_current_params() -> void:
	if not invite_manager:
		return
	
	current_params = invite_manager.get_all_invite_params()
	_apply_params_to_ui()

func _apply_params_to_ui() -> void:
	# Применяем Game Mode
	if game_mode_dropdown and current_params.has("game_mode"):
		var mode = current_params.game_mode
		var available_params = invite_manager.get_available_params()
		if available_params.has("game_mode"):
			var index = available_params.game_mode.find(mode)
			if index >= 0:
				game_mode_dropdown.selected = index
	
	# Применяем Difficulty
	if difficulty_dropdown and current_params.has("difficulty"):
		var diff = current_params.difficulty
		var available_params = invite_manager.get_available_params()
		if available_params.has("difficulty"):
			var index = available_params.difficulty.find(diff)
			if index >= 0:
				difficulty_dropdown.selected = index
	
	# Применяем Booster Bonus
	if booster_bonus_checkbox and current_params.has("booster_bonus"):
		booster_bonus_checkbox.button_pressed = current_params.booster_bonus == "true"
	
	# Применяем Daily Challenge
	if daily_challenge_checkbox and current_params.has("daily_challenge"):
		daily_challenge_checkbox.button_pressed = current_params.daily_challenge == "true"
	
	# Применяем Custom Theme
	if custom_theme_dropdown and current_params.has("custom_theme"):
		var theme = current_params.custom_theme
		var available_params = invite_manager.get_available_params()
		if available_params.has("custom_theme"):
			var index = available_params.custom_theme.find(theme)
			if index >= 0:
				custom_theme_dropdown.selected = index
	
	# Применяем Special Rules
	if special_rules_dropdown and current_params.has("special_rules"):
		var rule = current_params.special_rules
		var available_params = invite_manager.get_available_params()
		if available_params.has("special_rules"):
			var index = available_params.special_rules.find(rule)
			if index >= 0:
				special_rules_dropdown.selected = index

func _on_game_mode_changed(index: int) -> void:
	if not invite_manager:
		return
	
	var available_params = invite_manager.get_available_params()
	if available_params.has("game_mode") and index < available_params.game_mode.size():
		var mode = available_params.game_mode[index]
		invite_manager.set_invite_param("game_mode", mode)
		current_params["game_mode"] = mode
		_update_params_display()
		emit_signal("invite_params_updated", current_params)

func _on_difficulty_changed(index: int) -> void:
	if not invite_manager:
		return
	
	var available_params = invite_manager.get_available_params()
	if available_params.has("difficulty") and index < available_params.difficulty.size():
		var diff = available_params.difficulty[index]
		invite_manager.set_invite_param("difficulty", diff)
		current_params["difficulty"] = diff
		_update_params_display()
		emit_signal("invite_params_updated", current_params)

func _on_booster_bonus_changed(button_pressed: bool) -> void:
	if not invite_manager:
		return
	
	var value = "true" if button_pressed else "false"
	invite_manager.set_invite_param("booster_bonus", value)
	current_params["booster_bonus"] = value
	_update_params_display()
	emit_signal("invite_params_updated", current_params)

func _on_daily_challenge_changed(button_pressed: bool) -> void:
	if not invite_manager:
		return
	
	var value = "true" if button_pressed else "false"
	invite_manager.set_invite_param("daily_challenge", value)
	current_params["daily_challenge"] = value
	_update_params_display()
	emit_signal("invite_params_updated", current_params)

func _on_custom_theme_changed(index: int) -> void:
	if not invite_manager:
		return
	
	var available_params = invite_manager.get_available_params()
	if available_params.has("custom_theme") and index < available_params.custom_theme.size():
		var theme = available_params.custom_theme[index]
		invite_manager.set_invite_param("custom_theme", theme)
		current_params["custom_theme"] = theme
		_update_params_display()
		emit_signal("invite_params_updated", current_params)

func _on_special_rules_changed(index: int) -> void:
	if not invite_manager:
		return
	
	var available_params = invite_manager.get_available_params()
	if available_params.has("special_rules") and index < available_params.special_rules.size():
		var rule = available_params.special_rules[index]
		invite_manager.set_invite_param("special_rules", rule)
		current_params["special_rules"] = rule
		_update_params_display()
		emit_signal("invite_params_updated", current_params)

func _on_send_invite_pressed() -> void:
	if not invite_manager:
		_show_notification("Invite manager not available", "error")
		return
	
	# Отправляем инвайт
	invite_manager.send_invite()
	
	# Подключаемся к сигналу результата если еще не подключены
	if not invite_manager.invite_sent.is_connected(_on_invite_result):
		invite_manager.invite_sent.connect(_on_invite_result)

func _on_reset_params_pressed() -> void:
	if not invite_manager:
		return
	
	invite_manager.reset_invite_params()
	current_params = invite_manager.get_all_invite_params()
	_apply_params_to_ui()
	_update_params_display()
	emit_signal("invite_params_updated", current_params)
	
	_show_notification("Invite parameters reset to default", "info")

func _on_invite_result(success: bool, error: String) -> void:
	emit_signal("invite_sent", success)
	
	if success:
		_show_notification("Invite sent successfully!", "success")
	else:
		_show_notification("Failed to send invite: " + error, "error")

func _update_params_display() -> void:
	if not params_summary_label:
		return
	
	var summary = "[b]Current Invite Parameters:[/b]\n\n"
	
	for key in current_params.keys():
		var value = current_params[key]
		var display_key = key.replace("_", " ").capitalize()
		summary += "• [b]" + display_key + ":[/b] " + value + "\n"
	
	params_summary_label.text = summary

func _show_notification(message: String, type: String) -> void:
	if not notification_manager:
		print("[InviteParamsUI] ", message)
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
func get_current_params() -> Dictionary:
	return current_params.duplicate()

func set_param(key: String, value: String) -> bool:
	if not invite_manager:
		return false
	
	var success = invite_manager.set_invite_param(key, value)
	if success:
		current_params[key] = value
		_update_params_display()
		emit_signal("invite_params_updated", current_params)
	
	return success

func refresh_params() -> void:
	_load_current_params()
	_update_params_display()

func is_param_valid(key: String, value: String) -> bool:
	if not invite_manager:
		return false
	
	return invite_manager.is_param_valid(key, value)

# Методы для интеграции с другими системами
func connect_to_invite_manager() -> void:
	if not invite_manager:
		return
	
	# Подключаемся к сигналам менеджера инвайтов
	if invite_manager.has_signal("invite_sent"):
		invite_manager.invite_sent.connect(_on_invite_result)
	
	if invite_manager.has_signal("invite_received"):
		invite_manager.invite_received.connect(_on_invite_received)

func _on_invite_received(params: Dictionary) -> void:
	# Обновляем UI при получении инвайта
	current_params = params
	_apply_params_to_ui()
	_update_params_display()
	emit_signal("invite_params_updated", current_params)
	
	_show_notification("Invite parameters received and applied!", "success")

# Методы для кастомизации UI
func set_button_texts(send_text: String, reset_text: String) -> void:
	if send_invite_button:
		send_invite_button.text = send_text
	
	if reset_params_button:
		reset_params_button.text = reset_text

func set_dropdown_size(width: float, height: float) -> void:
	if game_mode_dropdown:
		game_mode_dropdown.custom_minimum_size = Vector2(width, height)
	
	if difficulty_dropdown:
		difficulty_dropdown.custom_minimum_size = Vector2(width, height)
	
	if custom_theme_dropdown:
		custom_theme_dropdown.custom_minimum_size = Vector2(width, height)
	
	if special_rules_dropdown:
		special_rules_dropdown.custom_minimum_size = Vector2(width, height)

func set_button_size(width: float, height: float) -> void:
	if send_invite_button:
		send_invite_button.custom_minimum_size = Vector2(width, height)
	
	if reset_params_button:
		reset_params_button.custom_minimum_size = Vector2(width, height)