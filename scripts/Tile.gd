extends Node2D

# Тип (для матчей). Можно подставлять случайно при создании.
@export var type: String = ""

# Позиция в сетке
var grid_position: Vector2i = Vector2i.ZERO

func _ready() -> void:
	if has_node("Sprite2D"):
		var sprite: Sprite2D = $Sprite2D
		_update_sprite(sprite)

func _update_sprite(sprite: Sprite2D) -> void:
	match type:
		"apple":
			sprite.texture = preload("res://sprites/apple.png")
		"banana":
			sprite.texture = preload("res://sprites/banana.png")
		"orange":
			sprite.texture = preload("res://sprites/orange.png")
		"grape":
			sprite.texture = preload("res://sprites/grape.png")
