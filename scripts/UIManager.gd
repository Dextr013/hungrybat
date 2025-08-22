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

const INITIAL_MOVES = 30
var moves = INITIAL_MOVES
var goal_score = 500  # Пример цели
var endless_mode: bool = true

func _ready():
	add_to_group("ui_manager")
	# Load boosters if SaveManager exists
	var saver := get_node_or_null("/root/SaveManager")
	if saver and saver.has_method("load_data"):
		saver.load_data()
		if saver.has_method("get_boosters"):
			var b = saver.get_boosters()
			if b.has("bomb"): bomb_count = int(b.bomb)
			if b.has("shuffle"): shuffle_count = int(b.shuffle)
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
	
	if play_button:
		play_button.pressed.connect(load_game_scene)
	if pause_button:
		pause_button.pressed.connect(pause_game)
		pause_button.visible = false  # Скрываем до загрузки игры
	if resume_button:
		resume_button.pressed.connect(resume_game)
		resume_button.visible = false  # Скрываем до паузы
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
	if pause_panel:
		pause_panel.visible = false
	_update_booster_labels()
	_update_booster_enabled()

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
	if FileAccess.file_exists("res://MainMenu.tscn") and not endless_mode:
		get_tree().change_scene_to_file("res://MainMenu.tscn")
	if yandex_sdk:
		yandex_sdk.gameplay_api_stop()

func use_bomb_booster():
	if audio_manager:
		audio_manager.play_match_sfx()
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
	if audio_manager:
		audio_manager.play_match_sfx()
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
	if audio_manager:
		audio_manager.play_match_sfx()
	modesafe_set_moves(moves + 5)
	print("Extra move booster used")
