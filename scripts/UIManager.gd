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

const INITIAL_MOVES = 30
var moves = INITIAL_MOVES
var goal_score = 500  # Пример цели

func _ready():
	add_to_group("ui_manager")
	if play_button:
		play_button.pressed.connect(load_game_scene)
	if pause_button:
		pause_button.pressed.connect(pause_game)
		pause_button.visible = false  # Скрываем до загрузки игры
	if resume_button:
		resume_button.pressed.connect(resume_game)
		resume_button.visible = false  # Скрываем до паузы
	if booster1_button:
		booster1_button.pressed.connect(use_bomb_booster)
	if booster2_button:
		booster2_button.pressed.connect(use_shuffle_booster)
	if booster3_button:
		booster3_button.pressed.connect(use_extra_move_booster)
	if moves_text:
		moves_text.text = "Moves: " + str(moves)
	if goal_text:
		goal_text.text = "Goal: " + str(goal_score)
	if pause_panel:
		pause_panel.visible = false

func update_score(score):
	if score_text:
		score_text.text = "Score: " + str(score)
	if score >= goal_score:
		print("Goal reached!")
		end_game(true)  # Победа

func decrement_moves():
	if moves_text:
		moves -= 1
		moves_text.text = "Moves: " + str(moves)
		if moves <= 0:
			end_game(false)  # Поражение

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
	if yandex_sdk:
		get_tree().paused = true
		if pause_panel: pause_panel.visible = true
		if pause_button: pause_button.visible = false
		if resume_button: resume_button.visible = true
		yandex_sdk.gameplay_api_stop()
		var tween = create_tween()
		if pause_panel:
			tween.tween_property(pause_panel, "modulate:a", 1.0, 0.3)
		print("Game paused")

func resume_game():
	if yandex_sdk:
		get_tree().paused = false
		if pause_panel: pause_panel.visible = false
		if pause_button: pause_button.visible = true
		if resume_button: resume_button.visible = false
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
	if FileAccess.file_exists("res://MainMenu.tscn"):
		get_tree().change_scene_to_file("res://MainMenu.tscn")
	if yandex_sdk:
		yandex_sdk.gameplay_api_stop()

func use_bomb_booster():
	if audio_manager:
		audio_manager.play_match_sfx()
	print("Bomb booster used")
	# Логика: Удалить 3x3 тайлы

func use_shuffle_booster():
	if audio_manager:
		audio_manager.play_match_sfx()
	print("Shuffle booster used")
	# Логика: Перемешать доску

func use_extra_move_booster():
	if audio_manager:
		audio_manager.play_match_sfx()
	moves += 5
	if moves_text:
		moves_text.text = "Moves: " + str(moves)
	print("Extra move booster used")
