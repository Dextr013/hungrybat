extends Node

var first_tile_pos = Vector2i(-1, -1)
var board_manager

func _ready():
	var boards := get_tree().get_nodes_in_group("board_manager")
	board_manager = boards.size() > 0 ? boards[0] : null

func _input(event):
	if board_manager == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos = get_viewport().get_mouse_position()
		var tile_size: int = board_manager.get_tile_size()
		var grid_pos = Vector2i(floor(world_pos.x / tile_size), floor(world_pos.y / tile_size))

		if first_tile_pos.x == -1:
			first_tile_pos = grid_pos
		else:
			if board_manager.swap_tiles(first_tile_pos, grid_pos):
				var uis := get_tree().get_nodes_in_group("ui_manager")
				if uis.size() > 0 and uis[0].has_method("decrement_moves"):
					uis[0].decrement_moves()
			first_tile_pos = Vector2i(-1, -1)
