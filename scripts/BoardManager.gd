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
var _busy: bool = false

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

func is_busy() -> bool:
	return _busy

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
	if _busy:
		return false
	if (abs(a.x - b.x) + abs(a.y - b.y)) != 1:
		return false
	var t1 = grid[a.x][a.y]
	var t2 = grid[b.x][b.y]
	if t1 == null or t2 == null:
		return false
	_busy = true
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
		_busy = false
		return false

	await _resolve_board_with_cascades_create_specials()
	_busy = false
	return true

func _resolve_board_with_cascades_create_specials() -> void:
	while true:
		var seqs := match_finder != null && match_finder.has_method("find_sequences") ? match_finder.find_sequences(grid) : []
		if seqs.is_empty():
			break
		# Create specials for 4/5+ sequences, prefer placing at last moved tile if involved
		await _apply_specials_then_clear(seqs)
		await _apply_gravity()
		await _refill_board()

func _apply_specials_then_clear(seqs: Array) -> void:
	var to_clear := {}
	for s in seqs:
		var positions: Array = s["positions"]
		var length: int = s["length"]
		var orientation: String = s["orientation"]
		if length == 4:
			var pivot: Vector2i = positions[2]
			var tile = grid[pivot.x][pivot.y]
			if tile != null and tile.has_method("set_special"):
				tile.set_special(orientation == "h" ? "line_h" : "line_v")
			# Clear others
			for p in positions:
				if p != pivot:
					to_clear[p] = true
		elif length >= 5:
			var pivot5: Vector2i = positions[2]
			var tile5 = grid[pivot5.x][pivot5.y]
			if tile5 != null and tile5.has_method("set_special"):
				tile5.set_special("bomb")
			for p5 in positions:
				if p5 != pivot5:
					to_clear[p5] = true
		else:
			for p3 in positions:
				to_clear[p3] = true
	# Expand clears if specials reside inside clear set
	var expanded := _expand_clears_with_specials(to_clear)
	await _clear_matches(expanded.keys())

func _expand_clears_with_specials(marked: Dictionary) -> Dictionary:
	var queue := []
	for k in marked.keys():
		queue.append(k)
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_back()
		var tile = grid[pos.x][pos.y]
		if tile == null:
			continue
		if not tile.has_variable("special"):
			continue
		match tile.special:
			"line_h":
				for x in range(grid_width):
					var p = Vector2i(x, pos.y)
					if not marked.has(p):
						marked[p] = true
						queue.append(p)
			"line_v":
				for y in range(grid_height):
					var p2 = Vector2i(pos.x, y)
					if not marked.has(p2):
						marked[p2] = true
						queue.append(p2)
			"bomb":
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var px := pos.x + dx
						var py := pos.y + dy
						if px >= 0 and px < grid_width and py >= 0 and py < grid_height:
							var p3 = Vector2i(px, py)
							if not marked.has(p3):
								marked[p3] = true
								queue.append(p3)
			_:
				pass
	return marked
