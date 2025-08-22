extends Node

var first_tile_pos = Vector2i(-1, -1)
var board_manager

func _ready():
	board_manager = get_tree().root.get_node("BoardManager")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos = get_viewport().get_mouse_position()
		var grid_pos = Vector2i(floor(world_pos.x / board_manager.TILE_SIZE), floor(world_pos.y / board_manager.TILE_SIZE))

		if first_tile_pos.x == -1:
			first_tile_pos = grid_pos
		else:
			if board_manager.swap_tiles(first_tile_pos, grid_pos):
				get_tree().root.get_node("UIManager").decrement_moves()
			first_tile_pos = Vector2i(-1, -1)
