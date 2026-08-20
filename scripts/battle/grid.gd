class_name BattleGrid
extends Node2D

const TILE_SIZE = 32
const GRID_SIZE = Vector2i(12, 12)

var highlight_layer: TileMapLayer
var movement_tiles: Array[Vector2i] = []
var attack_tiles: Array[Vector2i] = []

var grid_origin: Vector2 = Vector2.ZERO

func _ready() -> void:
 grid_origin = position
 setup_highlight_layer()

func setup_highlight_layer() -> void:
 highlight_layer = TileMapLayer.new()
 highlight_layer.name = "HighlightLayer"
 add_child(highlight_layer)

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
 return grid_origin + Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func pixel_to_grid(pixel_pos: Vector2) -> Vector2i:
 var local = pixel_pos - grid_origin
 return Vector2i(int(local.x / TILE_SIZE), int(local.y / TILE_SIZE))

func show_movement_range(unit: Unit, range: int) -> void:
 clear_highlights()
 movement_tiles = get_reachable_tiles(unit.grid_position, range)
 for tile in movement_tiles:
  highlight_tile(tile, Color(0.2, 0.6, 1.0, 0.4))

func show_attack_range(unit: Unit, range: int) -> void:
 attack_tiles = get_tiles_in_range(unit.grid_position, range)
 for tile in attack_tiles:
  highlight_tile(tile, Color(1.0, 0.2, 0.2, 0.4))

func get_reachable_tiles(start: Vector2i, move_range: int) -> Array[Vector2i]:
 var reachable: Array[Vector2i] = []
 var visited: Dictionary = {}
 var queue: Array = [[start, 0]]
 visited[str(start)] = true

 while queue.size() > 0:
  var current = queue.pop_front()
  var pos = current[0]
  var cost = current[1]

  if cost > 0:
   reachable.append(pos)

  if cost < move_range:
   for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
    var neighbor = pos + dir
    var key = str(neighbor)
    if not visited.has(key) and BattleManager.is_valid_position(neighbor) and BattleManager.is_walkable(neighbor):
     visited[key] = true
     queue.append([neighbor, cost + 1])

 return reachable

func get_tiles_in_range(center: Vector2i, range: int) -> Array[Vector2i]:
 var tiles: Array[Vector2i] = []
 for y in range(center.y - range, center.y + range + 1):
  for x in range(center.x - range, center.x + range + 1):
   var pos = Vector2i(x, y)
   if BattleManager.is_valid_position(pos):
    var dist = abs(x - center.x) + abs(y - center.y)
    if dist <= range and dist > 0:
     tiles.append(pos)
 return tiles

func highlight_tile(grid_pos: Vector2i, color: Color) -> void:
 var rect = ColorRect.new()
 rect.color = color
 rect.position = grid_to_pixel(grid_pos)
 rect.size = Vector2(TILE_SIZE, TILE_SIZE)
 rect.name = "Highlight_%d_%d" % [grid_pos.x, grid_pos.y]
 highlight_layer.add_child(rect)

func clear_highlights() -> void:
 for child in highlight_layer.get_children():
  child.queue_free()
 movement_tiles.clear()
 attack_tiles.clear()

func draw_grid() -> void:
 queue_redraw()

func _draw() -> void:
 for y in GRID_SIZE.y:
  for x in GRID_SIZE.x:
   var pos = grid_to_pixel(Vector2i(x, y))
   var rect = Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE))
   var color = Color(0.2, 0.35, 0.2) if (x + y) % 2 == 0 else Color(0.25, 0.4, 0.25)
   draw_rect(rect, color, true)
   draw_rect(rect, Color(0.35, 0.5, 0.35), false, 1.0)
