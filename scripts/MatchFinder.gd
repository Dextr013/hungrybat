extends Node

# Ожидается сетка grid[x][y], где элемент либо null, либо узел Tile с полем .type
func find_matches(grid: Array) -> Array:
	if grid.is_empty():
		return []
	var width: int = grid.size()
	var height: int = (grid[0] as Array).size()

	var matched := {} # Dictionary<Vector2i,bool>

	# Горизонтальные серии
	for y in range(height):
		var run_type = null
		var run_start: int = 0
		var run_len: int = 0
		for x in range(width + 1): # +1 — фиксация хвоста
			var t = null
			if x < width:
				t = grid[x][y]
			var ttype = null
			if t != null:
				ttype = t.type

			if ttype != null and ttype == run_type:
				run_len += 1
			else:
				if run_type != null and run_len >= 3:
					for rx in range(run_start, run_start + run_len):
						matched[Vector2i(rx, y)] = true
				run_type = ttype
				run_start = x
				if ttype != null:
					run_len = 1
				else:
					run_len = 0

	# Вертикальные серии
	for x in range(width):
		var run_type = null
		var run_start: int = 0
		var run_len: int = 0
		for y in range(height + 1): # +1 — фиксация хвоста
			var t = null
			if y < height:
				t = grid[x][y]
			var ttype = null
			if t != null:
				ttype = t.type

			if ttype != null and ttype == run_type:
				run_len += 1
			else:
				if run_type != null and run_len >= 3:
					for ry in range(run_start, run_start + run_len):
						matched[Vector2i(x, ry)] = true
				run_type = ttype
				run_start = y
				if ttype != null:
					run_len = 1
				else:
					run_len = 0

	return matched.keys()
