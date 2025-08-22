extends Node2D

@export var tile_scene: PackedScene = preload("res://Tile.tscn")
@export var swap_duration: float = 0.2

const TILE_SIZE: int = 64

var grid: Array = []
var grid_width: int = 8
var grid_height: int = 8

var match_finder: Node = null

func _ready() -> void:
	_init_grid()
	match_finder = get_node_or_null("../MatchFinder")

func _init_grid() -> void:
	grid.resize(grid_width)
	for x in range(grid_width):
		grid[x] = []
		for y in range(grid_height):
			var tile_instance: Node2D = tile_scene.instantiate()
			tile_instance.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			tile_instance.grid_position = Vector2i(x, y)
			add_child(tile_instance)
			grid[x].append(tile_instance)

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
	var ok: bool = match_finder.find_matches(grid).size() > 0
	_swap_in_grid(a, b)
	return ok

func swap_tiles(a: Vector2i, b: Vector2i) -> bool:
	if (abs(a.x - b.x) + abs(a.y - b.y)) != 1:
		return false
	var t1 = grid[a.x][a.y]
	var t2 = grid[b.x][b.y]

	var tween = create_tween()
	tween.tween_property(t1, "position", Vector2(b.x * TILE_SIZE, b.y * TILE_SIZE), swap_duration)
	tween.parallel().tween_property(t2, "position", Vector2(a.x * TILE_SIZE, a.y * TILE_SIZE), swap_duration)
	await tween.finished
	_swap_in_grid(a, b)

	var matched: Array = match_finder.find_matches(grid)
	if matched.is_empty():
		var tween_back = create_tween()
		tween_back.tween_property(t1, "position", Vector2(a.x * TILE_SIZE, a.y * TILE_SIZE), swap_duration)
		tween_back.parallel().tween_property(t2, "position", Vector2(b.x * TILE_SIZE, b.y * TILE_SIZE), swap_duration)
		await tween_back.finished
		_swap_in_grid(a, b)
		return false

	# здесь должна быть логика очистки совпавших, сдвига и заполнения новых
	return true
