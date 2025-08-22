extends Node2D

@export var tile_scene: PackedScene = preload("res://Tile.tscn")

const GRID_WIDTH: int = 8
const GRID_HEIGHT: int = 8
const TILE_SIZE: int = 64

func _ready() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var tile_instance: Node2D = tile_scene.instantiate()
			tile_instance.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			add_child(tile_instance)
