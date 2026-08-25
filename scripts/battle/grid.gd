class_name BattleGrid
extends Node2D

const TILE_SIZE = 32
const GRID_SIZE = Vector2i(12, 12)

var highlight_layer: TileMapLayer
var terrain_layer: TileMapLayer
var movement_tiles: Array[Vector2i] = []
var attack_tiles: Array[Vector2i] = []
var grid_origin: Vector2 = Vector2.ZERO

var terrain_map: Array = []  # Mapa de terrenos por posição

func _ready() -> void:
 add_to_group("battle_grid")
 grid_origin = position
 setup_layers()

func setup_layers() -> void:
 # Camada de terreno (base)
 terrain_layer = TileMapLayer.new()
 terrain_layer.name = "TerrainLayer"
 terrain_layer.z_index = -1
 add_child(terrain_layer)
 
 # Camada de highlights (por cima)
 highlight_layer = TileMapLayer.new()
 highlight_layer.name = "HighlightLayer"
 highlight_layer.z_index = 10
 add_child(highlight_layer)

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
 return grid_origin + Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func pixel_to_grid(pixel_pos: Vector2) -> Vector2i:
 var local = pixel_pos - grid_origin
 return Vector2i(int(local.x / TILE_SIZE), int(local.y / TILE_SIZE))

func initialize_terrain(terrain_type: String = "grass") -> void:
 # Inicializar mapa de terreno
 terrain_map.clear()
 terrain_layer.clear()
 
 for y in GRID_SIZE.y:
  var row: Array = []
  for x in GRID_SIZE.x:
   var terrain_id = get_terrain_tile_id(terrain_type)
   row.append(terrain_id)
   var pos = Vector2i(x, y)
   terrain_layer.set_cell(pos, 0, Vector2i(terrain_id % 8, terrain_id / 8))
  terrain_map.append(row)

func get_terrain_tile_id(terrain_type: String) -> int:
 # Retorna o ID do tile no atlas para o tipo de terreno
 match terrain_type:
  "grass": return 0
  "dirt": return 14
  "stone": return 28
  "water": return 42
  "lava": return 56
  "castle": return 98
  "cave": return 112
  "forest": return 126
  _: return 0

func show_movement_range(unit: Unit, move_range: int) -> void:
 clear_highlights()
 movement_tiles = get_reachable_tiles(unit.grid_position, move_range)
 for tile in movement_tiles:
  highlight_tile(tile, Color(0.2, 0.6, 1.0, 0.5))

func show_attack_range(unit: Unit, attack_range: int) -> void:
 attack_tiles = get_tiles_in_range(unit.grid_position, attack_range)
 for tile in attack_tiles:
  highlight_tile(tile, Color(1.0, 0.2, 0.2, 0.5))

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

func get_tiles_in_range(center: Vector2i, tile_range: int) -> Array[Vector2i]:
 var tiles: Array[Vector2i] = []
 for y in range(center.y - tile_range, center.y + tile_range + 1):
  for x in range(center.x - tile_range, center.x + tile_range + 1):
   var pos = Vector2i(x, y)
   if BattleManager.is_valid_position(pos):
    var dist = abs(x - center.x) + abs(y - center.y)
    if dist <= tile_range and dist > 0:
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

func set_terrain_at(pos: Vector2i, terrain_type: String) -> void:
 if BattleManager.is_valid_position(pos):
  var terrain_id = get_terrain_tile_id(terrain_type)
  terrain_map[pos.y][pos.x] = terrain_id
  terrain_layer.set_cell(pos, 0, Vector2i(terrain_id % 8, terrain_id / 8))

func get_terrain_at(pos: Vector2i) -> String:
 if BattleManager.is_valid_position(pos):
  var terrain_id = terrain_map[pos.y][pos.x]
  return get_terrain_name_from_id(terrain_id)
 return "grass"

func get_terrain_name_from_id(terrain_id: int) -> String:
 # Converte ID de tile de volta para nome de terreno
 for terrain_name in ["grass", "dirt", "stone", "water", "lava"]:
  if get_terrain_tile_id(terrain_name) == terrain_id:
   return terrain_name
 return "grass"

func apply_autotile(autotile) -> void:
 # Autotile é aplicado pela battle_scene diretamente (grid não é um TileMap clássico)
 pass

func _draw() -> void:
 # Desenhar fundo se não houver terrain_layer
 if terrain_layer.get_used_cells().size() == 0:
  for y in GRID_SIZE.y:
   for x in GRID_SIZE.x:
    var pos = grid_to_pixel(Vector2i(x, y))
    var rect = Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE))
    var color = Color(0.2, 0.35, 0.2) if (x + y) % 2 == 0 else Color(0.25, 0.4, 0.25)
    draw_rect(rect, color, true)
    draw_rect(rect, Color(0.35, 0.5, 0.35), false, 1.0)