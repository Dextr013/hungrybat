extends Node2D

# Тип (для матчей). Можно подставлять случайно при создании.
@export var type: String = ""

# Позиция в сетке
var grid_position: Vector2i = Vector2i.ZERO

var _sprite: Sprite2D

var _texture_by_type := {
	"apple": preload("res://sprites/apple.png"),
	"banana": preload("res://sprites/banana.png"),
	"orange": preload("res://sprites/orange.png"),
	"grape": preload("res://sprites/grape.png"),
}

# special can be "", "line_h", "line_v", "bomb"
var special: String = ""

func _ready() -> void:
	_sprite = get_node_or_null("TileSprite")
	if _sprite == null:
		return
	if type != "":
		_update_sprite()

func set_type(new_type: String) -> void:
	type = new_type
	_update_sprite()

func set_special(new_special: String) -> void:
	special = new_special
	_update_sprite()

func _update_sprite() -> void:
	if _sprite == null:
		return
	if type in _texture_by_type:
		_sprite.texture = _texture_by_type[type]
	else:
		_sprite.texture = null
	# Apply a simple visual marker for specials by modulating color
	match special:
		"line_h":
			_sprite.modulate = Color(1, 0.85, 0.85)
		"line_v":
			_sprite.modulate = Color(0.85, 1, 0.85)
		"bomb":
			_sprite.modulate = Color(0.85, 0.85, 1)
		_:
			_sprite.modulate = Color(1, 1, 1)
