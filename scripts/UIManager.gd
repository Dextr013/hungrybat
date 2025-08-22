extends CanvasLayer

@export var score_text: RichTextLabel
@export var moves_text: RichTextLabel
@export var play_button: Button
@export var pause_button: Button
@export var resume_button: Button
@export var yandex_sdk: Node  # YandexSDKManager.gd
@export var score_manager: Node  # ScoreManager.gd
@export var audio_manager: Node  # AudioManager.gd
@export var pause_panel: Panel  # Panel для паузного меню
@export var booster1_button: Button  # Bomb booster
@export var booster2_button: Button  # Shuffle booster
@export var booster3_button: Button  # Extra move booster
@export var goal_text: RichTextLabel  # Для отображения цели

var bomb_count := 3
var shuffle_count := 3
var best_score := 0

const INITIAL_MOVES = 30
var moves = INITIAL_MOVES
var goal_score = 500  # Пример цели
var endless_mode: bool = true

var _saver: Node = null

func _ready():
	add_to_group("ui_manager")
	_saver = get_node_or_null("/root/SaveManager")
	# Load boosters/best score and settings
	if _saver and _saver.has_method("load_data"):
		_saver.load_data()
		if _saver.has_method("get_boosters"):
			var b = _saver.get_boosters()
			if b.has("bomb"): bomb_count = int(b.bomb)
			if b.has("shuffle"): shuffle_count = int(b.shuffle)
		if _saver.has_method("get_best_score"):
			best_score = int(_saver.get_best_score())
		_apply_settings_from_save()
	# Auto-wire if present
	if score_text == null:
		score_text = get_node_or_null("ScoreText")
	if moves_text == null:
		moves_text = get_node_or_null("MovesText")
	if goal_text == null:
		goal_text = get_node_or_null("GoalText")
	if booster1_button == null:
		booster1_button = get_node_or_null("BoosterBomb")
	if booster2_button == null:
		booster2_button = get_node_or_null("BoosterShuffle")
	if booster3_button == null:
		booster3_button = get_node_or_null("BoosterExtra")
	if pause_button == null:
		pause_button = get_node_or_null("PauseButton")
	if resume_button == null:
		resume_button = get_node_or_null("ResumeButton")
	if pause_panel == null:
		pause_panel = get_node_or_null("SettingsPanel")
	if audio_manager == null:
		audio_manager = get_node_or_null("AudioManager")
	if yandex_sdk == null:
		yandex_sdk = get_node_or_null("/root/YandexSDKManager")
	
	if play_button:
		play_button.pressed.connect(load_game_scene)
	if pause_button:
		pause_button.pressed.connect(pause_game)
		pause_button.visible = true
	if resume_button:
		resume_button.pressed.connect(resume_game)
		resume_button.visible = false
	if booster1_button:
		booster1_button.pressed.connect(_on_bomb_pressed)
	if booster2_button:
		booster2_button.pressed.connect(_on_shuffle_pressed)
	if booster3_button:
		booster3_button.pressed.connect(use_extra_move_booster)
	if moves_text:
		moves_text.text = endless_mode ? "Moves: ∞" : "Moves: " + str(moves)
	if goal_text:
		goal_text.visible = not endless_mode
	var best_label: RichTextLabel = get_node_or_null("BestScoreText")
	if best_label:
		best_label.text = _tr("best") + ": " + str(best_score)
	if pause_panel:
		pause_panel.visible = false
	_update_booster_labels()
	_update_booster_enabled()
	_localize_ui()
	_bind_settings_controls()
	_setup_lang_selector()
	_setup_daily_reward()
	_bind_volume_sliders()

func _apply_settings_from_save() -> void:
	if _saver == null: return
	var s = _saver.get_settings() if _saver.has_method("get_settings") else {}
	var loc := get_node_or_null("Localization")
	if s.has("language") and loc:
		loc.set_language(String(s.language))
	if audio_manager:
		if s.has("music_enabled") and audio_manager.has_method("set_music_enabled"):
			audio_manager.set_music_enabled(bool(s.music_enabled))
		if s.has("sfx_enabled") and audio_manager.has_method("set_sfx_enabled"):
			audio_manager.set_sfx_enabled(bool(s.sfx_enabled))
		if s.has("music_volume") and audio_manager.has_method("set_music_volume"):
			audio_manager.set_music_volume(float(s.music_volume))
		if s.has("sfx_volume") and audio_manager.has_method("set_sfx_volume"):
			audio_manager.set_sfx_volume(float(s.sfx_volume))

func _save_settings_now() -> void:
	if _saver and _saver.has_method("save_settings") and audio_manager:
		var loc := get_node_or_null("Localization")
		var mcheck: CheckBox = get_node_or_null("SettingsPanel/MusicCheck")
		var scheck: CheckBox = get_node_or_null("SettingsPanel/SfxCheck")
		var mv: HSlider = get_node_or_null("SettingsPanel/MusicVolume")
		var sv: HSlider = get_node_or_null("SettingsPanel/SfxVolume")
		_saver.save_settings({
			"language": loc.language if loc else "en",
			"music_enabled": mcheck.button_pressed if mcheck else true,
			"sfx_enabled": scheck.button_pressed if scheck else true,
			"music_volume": mv.value if mv else 1.0,
			"sfx_volume": sv.value if sv else 1.0,
		})

func _tr(key: String) -> String:
	var loc := get_node_or_null("Localization")
	return loc and loc.has_method("trn") ? loc.trn(key) : key

func _bind_volume_sliders() -> void:
	var mv: HSlider = get_node_or_null("SettingsPanel/MusicVolume")
	var sv: HSlider = get_node_or_null("SettingsPanel/SfxVolume")
	if mv and audio_manager and audio_manager.has_method("set_music_volume"):
		mv.value_changed.connect(func(v): audio_manager.set_music_volume(v); _save_settings_now())
	if sv and audio_manager and audio_manager.has_method("set_sfx_volume"):
		sv.value_changed.connect(func(v): audio_manager.set_sfx_volume(v); _save_settings_now())

func _bind_settings_controls() -> void:
	var mcheck: CheckBox = get_node_or_null("SettingsPanel/MusicCheck")
	var scheck: CheckBox = get_node_or_null("SettingsPanel/SfxCheck")
	if mcheck and audio_manager and audio_manager.has_method("set_music_enabled"):
		mcheck.toggled.connect(func(pressed): audio_manager.set_music_enabled(pressed); _save_settings_now())
	if scheck and audio_manager and audio_manager.has_method("set_sfx_enabled"):
		scheck.toggled.connect(func(pressed): audio_manager.set_sfx_enabled(pressed); _save_settings_now())
	# Banner/Auth/Rewarded test
	var show_b: Button = get_node_or_null("SettingsPanel/ShowBannerBtn")
	if show_b and yandex_sdk and yandex_sdk.has_method("show_banner"):
		show_b.text = _tr("show_banner")
		show_b.pressed.connect(func(): yandex_sdk.show_banner())
	var hide_b: Button = get_node_or_null("SettingsPanel/HideBannerBtn")
	if hide_b and yandex_sdk and yandex_sdk.has_method("hide_banner"):
		hide_b.text = _tr("hide_banner")
		hide_b.pressed.connect(func(): yandex_sdk.hide_banner())
	var login_b: Button = get_node_or_null("SettingsPanel/LoginBtn")
	if login_b and yandex_sdk and yandex_sdk.has_method("open_auth_dialog"):
		login_b.text = _tr("login")
		login_b.pressed.connect(func(): yandex_sdk.open_auth_dialog())
	var reward_b: Button = get_node_or_null("SettingsPanel/RewardedTestBtn")
	if reward_b and yandex_sdk and yandex_sdk.has_method("show_rewarded_ad"):
		reward_b.text = _tr("rewarded_test")
		reward_b.pressed.connect(func():
			if audio_manager and audio_manager.has_method("pause_music"): audio_manager.pause_music()
			yandex_sdk.show_rewarded_ad(func(): if moves_text: modesafe_set_moves(moves + 5), func(_): pass)
			if audio_manager and audio_manager.has_method("resume_music"): audio_manager.resume_music()
		)

func _setup_lang_selector() -> void:
	var ob: OptionButton = get_node_or_null("SettingsPanel/LangSelect")
	if ob == null: return
	ob.clear()
	ob.add_item("English")
	ob.add_item("Русский")
	var loc := get_node_or_null("Localization")
	var default_ru := loc and loc.language == "ru"
	ob.select(default_ru ? 1 : 0)
	ob.item_selected.connect(func(idx):
		if loc:
			loc.set_language(idx == 0 ? "en" : "ru")
		_localize_ui()
		_save_settings_now()
	)

func _setup_daily_reward() -> void:
	var btn: Button = get_node_or_null("SettingsPanel/DailyReward")
	if btn == null: return
	btn.pressed.connect(_on_daily_reward)
	_update_daily_reward_button()

func _update_daily_reward_button() -> void:
	var btn: Button = get_node_or_null("SettingsPanel/DailyReward")
	if btn == null: return
	var saver := get_node_or_null("/root/SaveManager")
	var today := Time.get_date_string_from_system()
	if saver and saver.has_method("can_claim_daily_reward") and not saver.can_claim_daily_reward(today):
		btn.disabled = true
		btn.text = _tr("reward_claimed")
	else:
		btn.disabled = false
		btn.text = _tr("daily_reward")

func _on_daily_reward() -> void:
	var saver := get_node_or_null("/root/SaveManager")
	var today := Time.get_date_string_from_system()
	if saver and saver.has_method("can_claim_daily_reward") and saver.can_claim_daily_reward(today):
		saver.claim_daily_reward(today)
		saver.load_data()
		if saver.has_method("get_boosters"):
			var b = saver.get_boosters()
			if b.has("bomb"): bomb_count = int(b.bomb)
			if b.has("shuffle"): shuffle_count = int(b.shuffle)
		_update_booster_labels()
		_update_booster_enabled()
		_update_daily_reward_button()

func _localize_ui() -> void:
	if score_text: score_text.text = _tr("score") + ": 0"
	if moves_text: moves_text.text = _tr("moves") + ": " + (endless_mode ? "∞" : str(moves))
	if pause_button: pause_button.text = _tr("pause")
	if resume_button: resume_button.text = _tr("resume")
	var sl: Label = get_node_or_null("SettingsPanel/SettingsLabel")
	if sl: sl.text = _tr("settings")
	var mc: CheckBox = get_node_or_null("SettingsPanel/MusicCheck")
	if mc: mc.text = _tr("music")
	var sc: CheckBox = get_node_or_null("SettingsPanel/SfxCheck")
	if sc: sc.text = _tr("sfx")
	var best_label: RichTextLabel = get_node_or_null("BestScoreText")
	if best_label: best_label.text = _tr("best") + ": " + str(best_score)
	_update_daily_reward_button()

func _save_boosters_now() -> void:
	var saver := get_node_or_null("/root/SaveManager")
	if saver and saver.has_method("save_boosters"):
		saver.save_boosters(bomb_count, shuffle_count)

func _update_booster_labels() -> void:
	var bomb_label := get_node_or_null("BombCount")
	if bomb_label:
		bomb_label.text = "x" + str(bomb_count)
	var shuf_label := get_node_or_null("ShuffleCount")
	if shuf_label:
		shuf_label.text = "x" + str(shuffle_count)
	var extra_label := get_node_or_null("ExtraCount")
	if extra_label:
		extra_label.text = "+5"

func _update_booster_enabled() -> void:
	if booster1_button: booster1_button.disabled = bomb_count <= 0
	if booster2_button: booster2_button.disabled = shuffle_count <= 0
	# Extra moves is infinite for now

func update_score(score):
	if score_text:
		score_text.text = "Score: " + str(score)
	var saver := get_node_or_null("/root/SaveManager")
	if saver and saver.has_method("save_score"):
		saver.save_score(score)
		if saver.has_method("get_best_score"):
			best_score = int(saver.get_best_score())
			var best_label: RichTextLabel = get_node_or_null("BestScoreText")
			if best_label:
				best_label.text = _tr("best") + ": " + str(best_score)
	if not endless_mode and score >= goal_score:
		print("Goal reached!")
		end_game(true)  # Победа

func decrement_moves():
	if endless_mode:
		return
	if moves_text:
		modesafe_set_moves(moves - 1)
		if moves <= 0:
			end_game(false)  # Поражение

func modesafe_set_moves(new_moves: int) -> void:
	moves = new_moves
	if moves_text:
		moves_text.text = endless_mode ? "Moves: ∞" : "Moves: " + str(moves)

func load_game_scene():
	print("Loading GameScene...")
	var scene_path = "res://GameScene.tscn"
	var file = FileAccess.file_exists(scene_path)
	if file:
		get_tree().change_scene_to_file(scene_path)
		if yandex_sdk:
			yandex_sdk.gameplay_api_start()
	else:
		print("Error: GameScene.tscn not found at ", scene_path)

func pause_game():
	get_tree().paused = true
	if pause_panel: pause_panel.visible = true
	if pause_button: pause_button.visible = false
	if resume_button: resume_button.visible = true
	if yandex_sdk:
		yandex_sdk.gameplay_api_stop()
	var tween = create_tween()
	if pause_panel:
		tween.tween_property(pause_panel, "modulate:a", 1.0, 0.3)
	print("Game paused")

func resume_game():
	get_tree().paused = false
	if pause_panel: pause_panel.visible = false
	if pause_button: pause_button.visible = true
	if resume_button: resume_button.visible = false
	# Show ad on resume
	if audio_manager and audio_manager.has_method("pause_music"):
		audio_manager.pause_music()
	if yandex_sdk and yandex_sdk.has_method("show_ad"):
		var done := false
		yandex_sdk.show_ad(func(_): done = true)
		while not done:
			await get_tree().process_frame
	if audio_manager and audio_manager.has_method("resume_music"):
		audio_manager.resume_music()
	if yandex_sdk:
		yandex_sdk.gameplay_api_start()
	var tween = create_tween()
	if pause_panel:
		tween.tween_property(pause_panel, "modulate:a", 0.0, 0.3)
	print("Game resumed")

func end_game(is_win):
	if yandex_sdk and score_manager:
		var score = score_manager.get_score()
		if score is int and score >= 0:
			yandex_sdk.submit_score("Match3Leaderboard", score)
	if is_win:
		print("Win!")
	else:
		print("Lose!")
		# Show ad and offer continue or restart
		await _handle_defeat_with_ad()
		return
	if FileAccess.file_exists("res://MainMenu.tscn") and not endless_mode:
		get_tree().change_scene_to_file("res://MainMenu.tscn")
	if yandex_sdk:
		yandex_sdk.gameplay_api_stop()

func _handle_defeat_with_ad() -> void:
	# Offer continue with rewarded ad
	var loc_yes := _tr("continue")
	var loc_no := _tr("restart")
	var q := _tr("continue_question")
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = q
	dialog.ok_button_text = loc_yes
	dialog.get_cancel_button().text = loc_no
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	var confirmed := await dialog.confirmed
	if confirmed and yandex_sdk and yandex_sdk.has_method("show_rewarded_ad"):
		if audio_manager and audio_manager.has_method("pause_music"):
			audio_manager.pause_music()
		var was_rewarded := false
		yandex_sdk.show_rewarded_ad(func(): was_rewarded = true, func(_): pass)
		while not was_rewarded:
			await get_tree().process_frame
		if audio_manager and audio_manager.has_method("resume_music"):
			audio_manager.resume_music()
		if moves_text:
			modesafe_set_moves(moves + 5)
		return
	# restart on cancel or no rewarded
	get_tree().reload_current_scene()
	return

func _prompt_continue_or_restart() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = _tr("continue_question") if has_method("_tr") else "Continue game?"
	dialog.ok_button_text = _tr("continue") if has_method("_tr") else "Continue"
	dialog.get_cancel_button().text = _tr("restart") if has_method("_tr") else "Restart"
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	var confirmed := await dialog.confirmed
	if confirmed:
		if moves_text:
			modesafe_set_moves(moves + 5)
		return
	# restart on cancel
	get_tree().reload_current_scene()
	return

func use_bomb_booster():
	if audio_manager and audio_manager.has_method("play_bomb_sfx"):
		audio_manager.play_bomb_sfx()
	if bomb_count <= 0:
		return
	bomb_count -= 1
	_update_booster_labels()
	_update_booster_enabled()
	_save_boosters_now()
	print("Bomb booster used")
	# Toggle bomb targeting via input handler
	var boards := get_tree().get_nodes_in_group("board_manager")
	if boards.size() == 0:
		return
	var handlers := boards[0].get_tree().get_nodes_in_group("input_handler")
	if handlers.size() > 0 and handlers[0].has_method("enable_bomb_mode"):
		handlers[0].enable_bomb_mode(true)

func _on_bomb_pressed():
	use_bomb_booster()

func use_shuffle_booster():
	if audio_manager and audio_manager.has_method("play_shuffle_sfx"):
		audio_manager.play_shuffle_sfx()
	if shuffle_count <= 0:
		return
	shuffle_count -= 1
	_update_booster_labels()
	_update_booster_enabled()
	_save_boosters_now()
	print("Shuffle booster used")
	var boards := get_tree().get_nodes_in_group("board_manager")
	if boards.size() > 0 and boards[0].has_method("shuffle_board"):
		boards[0].shuffle_board()

func _on_shuffle_pressed():
	use_shuffle_booster()

func use_extra_move_booster():
	if audio_manager and audio_manager.has_method("play_match_sfx"):
		audio_manager.play_match_sfx()
	modesafe_set_moves(moves + 5)
	print("Extra move booster used")
