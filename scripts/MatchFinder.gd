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

func find_sequences(grid: Array) -> Array:
	# Возвращает массив словарей: { positions: Array<Vector2i>, length: int, orientation: "h"|"v" }
	if grid.is_empty():
		return []
	var width: int = grid.size()
	var height: int = (grid[0] as Array).size()
	var sequences: Array = []
	# Горизонтальные
	for y in range(height):
		var run_type = null
		var run_start: int = 0
		var run_len: int = 0
		for x in range(width + 1):
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
					var positions := []
					for rx in range(run_start, run_start + run_len):
						positions.append(Vector2i(rx, y))
					sequences.append({
						"positions": positions,
						"length": run_len,
						"orientation": "h"
					})
				run_type = ttype
				run_start = x
				run_len = 1 if ttype != null else 0
	# Вертикальные
	for x in range(width):
		var run_type = null
		var run_start: int = 0
		var run_len: int = 0
		for y in range(height + 1):
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
					var positions := []
					for ry in range(run_start, run_start + run_len):
						positions.append(Vector2i(x, ry))
					sequences.append({
						"positions": positions,
						"length": run_len,
						"orientation": "v"
					})
				run_type = ttype
				run_start = y
				run_len = 1 if ttype != null else 0
	return sequences
