extends Control
# Tiny automap: walls, exit, player. Refreshed on a timer by main.

var game = null
var cell := 8.0

func _ready() -> void:
	custom_minimum_size = Vector2(20 * cell + 8, 13 * cell + 8)
	size = custom_minimum_size

func _draw() -> void:
	if game == null or game.grid.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	for y in game.grid.size():
		for x in game.grid[y].size():
			var ch: String = game.grid[y][x]
			if ch == ".":
				continue
			var c := Color(0.4, 0.4, 0.4)
			if ch == "E":
				c = Color(0, 1, 0) if game.room_clear() else Color(0.2, 0.27, 0.33)
			elif ch == "s":
				c = Color(0.44, 0.09, 0.09)
			draw_rect(Rect2(Vector2(4 + x * cell, 4 + y * cell), Vector2(cell, cell)), c)
	if game.player_node:
		var p: Vector3 = game.player_node.position
		var px: float = 4 + p.x / game.CELL * cell
		var py: float = 4 + p.z / game.CELL * cell
		draw_rect(Rect2(Vector2(px - 1, py - 1), Vector2(3, 3)), Color(1, 1, 1))
		var dx: float = -sin(game.yaw) * 8.0
		var dz: float = -cos(game.yaw) * 8.0
		draw_rect(Rect2(Vector2(px + dx - 1, py + dz - 1), Vector2(2, 2)), Color(0, 1, 0))
