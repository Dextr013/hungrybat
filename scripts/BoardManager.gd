extends Node2D

@export var tile_scene: PackedScene = preload("res://Tile.tscn")
@export var swap_duration: float = 0.2

const TILE_SIZE: int = 64

var grid: Array = []
var grid_width: int = 8
var grid_height: int = 8

var match_finder: Node = null

var _available_types := ["apple", "banana", "orange", "grape"]
var _score: int = 0

func _ready() -> void:
	add_to_group("board_manager")
	randomize()
	match_finder = get_node_or_null("../MatchFinder")
	if match_finder == null:
		match_finder = Node.new()
		match_finder.set_script(load("res://scripts/MatchFinder.gd"))
		add_child(match_finder)
	_init_grid()

func get_tile_size() -> int:
	return TILE_SIZE

func _init_grid() -> void:
	grid.resize(grid_width)
	for x in range(grid_width):
		grid[x] = []
		for y in range(grid_height):
			var tile_instance: Node2D = tile_scene.instantiate()
			tile_instance.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			tile_instance.grid_position = Vector2i(x, y)
			# Assign type avoiding initial matches
			if tile_instance.has_method("set_type"):
				(tile_instance as Node).call("set_type", _pick_type_for_initial(x, y))
			add_child(tile_instance)
			grid[x].append(tile_instance)

func _pick_type_for_initial(x: int, y: int) -> String:
	var candidates: Array = _available_types.duplicate()
	# Avoid creating a horizontal run >= 3
	if x >= 2:
		var t1 = grid[x - 1][y]
		var t2 = grid[x - 2][y]
		if t1 != null and t2 != null and t1.type == t2.type:
			candidates.erase(t1.type)
	# Avoid creating a vertical run >= 3
	if y >= 2:
		var u1 = grid[x][y - 1]
		var u2 = grid[x][y - 2]
		if u1 != null and u2 != null and u1.type == u2.type:
			candidates.erase(u1.type)
	if candidates.is_empty():
		return _available_types[randi() % _available_types.size()]
	return candidates[randi() % candidates.size()]

func _swap_in_grid(a: Vector2i, b: Vector2i) -> void:
	var t1 = grid[a.x][a.y]
	var t2 = grid[b.x][b.y]
	grid[a.x][a.y] = t2
	grid[b.x][b.y] = t1
	if t1 != null:
		t1.grid_position = b
	if t2 != null:
		t2.grid_position = a

func is_valid_swap(a: Vector2i, b: Vector2i) -> bool:
	if (abs(a.x - b.x) + abs(a.y - b.y)) != 1:
		return false
	_swap_in_grid(a, b)
	var ok: bool = match_finder != null and match_finder.find_matches(grid).size() > 0
	_swap_in_grid(a, b)
	return ok

func swap_tiles(a: Vector2i, b: Vector2i) -> bool:
	if (abs(a.x - b.x) + abs(a.y - b.y)) != 1:
		return false
	var t1 = grid[a.x][a.y]
	var t2 = grid[b.x][b.y]
	if t1 == null or t2 == null:
		return false

	var tween = create_tween()
	tween.tween_property(t1, "position", Vector2(b.x * TILE_SIZE, b.y * TILE_SIZE), swap_duration)
	tween.parallel().tween_property(t2, "position", Vector2(a.x * TILE_SIZE, a.y * TILE_SIZE), swap_duration)
	await tween.finished
	_swap_in_grid(a, b)

	var matched: Array = match_finder != null ? match_finder.find_matches(grid) : []
	if matched.is_empty():
		var tween_back = create_tween()
		tween_back.tween_property(t1, "position", Vector2(a.x * TILE_SIZE, a.y * TILE_SIZE), swap_duration)
		tween_back.parallel().tween_property(t2, "position", Vector2(b.x * TILE_SIZE, b.y * TILE_SIZE), swap_duration)
		await tween_back.finished
		_swap_in_grid(a, b)
		return false

	await _resolve_board_with_cascades()
	return true

func _resolve_board_with_cascades() -> void:
	while true:
		var matched: Array = match_finder != null ? match_finder.find_matches(grid) : []
		if matched.is_empty():
			break
		await _clear_matches(matched)
		await _apply_gravity()
		await _refill_board()

func _clear_matches(matched_positions: Array) -> void:
	# Remove matched tiles and update score
	for pos in matched_positions:
		var p: Vector2i = pos
		var tile = grid[p.x][p.y]
		if tile != null:
			tile.queue_free()
			grid[p.x][p.y] = null
	_score += matched_positions.size()
	var uis := get_tree().get_nodes_in_group("ui_manager")
	if uis.size() > 0 and uis[0].has_method("update_score"):
		uis[0].update_score(_score)
	# Small delay for clarity if desired
	await get_tree().create_timer(0.05).timeout

func _apply_gravity() -> void:
	# For each column, move tiles down to fill nulls
	for x in range(grid_width):
		var write_y := grid_height - 1
		for y in range(grid_height - 1, -1, -1):
			var tile = grid[x][y]
			if tile != null:
				if y != write_y:
					grid[x][write_y] = tile
					grid[x][y] = null
					tile.grid_position = Vector2i(x, write_y)
					var tween = create_tween()
					tween.tween_property(tile, "position", Vector2(x * TILE_SIZE, write_y * TILE_SIZE), 0.1)
					await tween.finished
				write_y -= 1
			else:
				write_y -= 1

func _refill_board() -> void:
	# Spawn new tiles for empty cells at the top and animate falling into place
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == null:
				var tile_instance: Node2D = tile_scene.instantiate()
				var spawn_y := -1
				tile_instance.position = Vector2(x * TILE_SIZE, spawn_y * TILE_SIZE)
				tile_instance.grid_position = Vector2i(x, y)
				if tile_instance.has_method("set_type"):
					(tile_instance as Node).call("set_type", _available_types[randi() % _available_types.size()])
				add_child(tile_instance)
				grid[x][y] = tile_instance
				var tween = create_tween()
				tween.tween_property(tile_instance, "position", Vector2(x * TILE_SIZE, y * TILE_SIZE), 0.1 + 0.02 * (grid_height - y))
				await tween.finished

func apply_bomb(center: Vector2i, radius: int = 1) -> void:
	var positions := []
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var px := center.x + dx
			var py := center.y + dy
			if px >= 0 and px < grid_width and py >= 0 and py < grid_height:
				positions.append(Vector2i(px, py))
	await _clear_matches(positions)
	await _apply_gravity()
	await _refill_board()
	await _resolve_board_with_cascades()

func shuffle_board(max_attempts: int = 20) -> void:
	var tiles := []
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null:
				tiles.append(grid[x][y].type)
	if tiles.is_empty():
		return
	var attempt := 0
	while attempt < max_attempts:
		attempt += 1
		tiles.shuffle()
		var idx := 0
		for x in range(grid_width):
			for y in range(grid_height):
				if grid[x][y] != null:
					grid[x][y].set_type(tiles[idx])
					idx += 1
		# If no immediate matches after shuffle, accept
		var m := match_finder != null ? match_finder.find_matches(grid) : []
		if m.is_empty():
			break
