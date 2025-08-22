extends CanvasLayer

@onready var score_label = $ScoreLabel

func _ready():
	if not score_label:
		print("Error: ScoreLabel not found in ScoreManager")
	update_score(0)

func update_score(new_score):
	if score_label:
		score_label.text = "Score: " + str(new_score)
