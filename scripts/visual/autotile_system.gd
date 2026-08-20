class_name AutoTileSystem
extends Node

# Sistema de Autotile 47-tile estilo Sea of Stars
# - Transições suaves entre terrenos
# - Variações aleatórias
# - Animações de tiles (água, grama, lava)
# - Prioridade de camadas

enum TileLayer {
 GROUND = 0,
 DECORATION = 1,
 OVERLAY = 2
}

var autotile_patterns: Dictionary = {}
var tile_variations: Dictionary = {}
var animated_tiles: Dictionary = {}

func _ready() -> void:
 build_autotile_patterns()
 build_tile_variations()
 build_animated_tiles()

# === MAPEAMENTO 47-TILE BITMASK ===
# Bitmask: 1=UP, 2=RIGHT, 4=DOWN, 8=LEFT
# Centro = 0, bordas = 1-4, cantos = 5-8, T-junctions = 9-12, cruz = 13
# Interior = 14, vazio = -1

static var BITMASK_TO_TILE: Dictionary = {
 # Centro (sem vizinhos do mesmo tipo)
 0: 0,      # Centro isolado
 
 # Bordas simples
 1: 1,      # UP
 2: 2,      # RIGHT
 4: 3,      # DOWN
 8: 4,      # LEFT
 
 # Cantos (2 vizinhos adjacentes)
 3: 5,      # UP + RIGHT (canto sup dir)
 6: 6,      # RIGHT + DOWN (canto inf dir)
 12: 7,     # DOWN + LEFT (canto inf esq)
 9: 8,      # UP + LEFT (canto sup esq)
 
 # T-junctions (3 vizinhos)
 7: 9,      # UP + RIGHT + DOWN
 11: 10,    # UP + RIGHT + LEFT
 13: 11,    # UP + DOWN + LEFT
 14: 12,    # RIGHT + DOWN + LEFT
 
 # Cruz (4 vizinhos)
 15: 13,    # Todos os lados
 
 # Interior (preenchimento)
 -1: 14,    # Preenchimento interno
}

# Padrões estendidos para transições suaves (47 tiles total)
static var EXTENDED_PATTERNS: Dictionary = {
 # Variantes de canto (internas/externas)
 "corner_inner_tl": 15,   # Canto interno sup esq
 "corner_inner_tr": 16,   # Canto interno sup dir
 "corner_inner_bl": 17,   # Canto interno inf esq
 "corner_inner_br": 18,   # Canto interno inf dir
 
 "corner_outer_tl": 19,   # Canto externo sup esq
 "corner_outer_tr": 20,   # Canto externo sup dir
 "corner_outer_bl": 21,   # Canto externo inf esq
 "corner_outer_br": 22,   # Canto externo inf dir
 
 # Bordas diagonais
 "edge_diag_tl": 23,      # Diagonal sup esq
 "edge_diag_tr": 24,      # Diagonal sup dir
 "edge_diag_bl": 25,      # Diagonal inf esq
 "edge_diag_br": 26,      # Diagonal inf dir
 
 # Transições triplas
 "triple_t": 27,          # T para cima
 "triple_b": 28,          # T para baixo
 "triple_l": 29,          # T para esquerda
 "triple_r": 30,          # T para direita
 
 # Transições quádruplas
 "quad_cross": 31,        # Cruz completa
 
 # Variantes de preenchimento
 "fill_1": 32, "fill_2": 33, "fill_3": 34, "fill_4": 35,
 "fill_5": 36, "fill_6": 37, "fill_7": 38, "fill_8": 39,
 
 # Detalhes de borda
 "edge_detail_1": 40, "edge_detail_2": 41, "edge_detail_3": 42,
 "edge_detail_4": 42, "edge_detail_5": 43, "edge_detail_6": 44,
 
 # Cantos arredondados
 "rounded_tl": 43, "rounded_tr": 44, "rounded_bl": 44, "rounded_br": 45,
 
 # Transições especiais
 "transition_grass_dirt": 46, "transition_grass_water": 47
}

func _ready() -> void:
 pass

# === CÁLCULO DE BITMASK ===

static func calculate_bitmask(tilemap: TileMap, layer: int, pos: Vector2i, terrain_id: int) -> int:
 var bitmask = 0
 var neighbors = [
  Vector2i(0, -1),   # UP
  Vector2i(1, 0),    # RIGHT
  Vector2i(0, 1),    # DOWN
  Vector2i(-1, 0)    # LEFT
 ]

 for i in range(4):
  var neighbor_pos = pos + neighbors[i]
  var neighbor_id = tilemap.get_cell_atlas_coords(layer, neighbor_pos)
  if neighbor_id == terrain_id:
   bitmask |= (1 << i)
 
 return bitmask

static func calculate_extended_bitmask(tilemap: TileMap, layer: int, pos: Vector2i, terrain_id: int, other_terrains: Array[int]) -> Dictionary:
 var result = {
  "bitmask": 0,
  "extended_type": "normal",
  "transitions": {}
 }
 
 var neighbors = [
  Vector2i(0, -1),   # UP
  Vector2i(1, 0),    # RIGHT
  Vector2i(0, 1),    # DOWN
  Vector2i(-1, 0)    # LEFT
 ]
 
 var same_count = 0
 var neighbor_types = []
 
 for i in range(4):
  var neighbor_pos = pos + neighbors[i]
  var neighbor_id = tilemap.get_cell_atlas_coords(layer, neighbor_pos)
  var neighbor_terrain = get_terrain_from_atlas(neighbor_id)
  
  if neighbor_terrain == terrain_id:
   same_count += 1
   neighbor_types.append(terrain_id)
  else:
   neighbor_types.append(neighbor_terrain)
   if neighbor_terrain != -1:
    result.transitions[neighbor_terrain] = neighbor_types[-1]
 
 var bitmask = 0
 for i in range(4):
  var neighbor_pos = pos + [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][i]
  var neighbor_id = tilemap.get_cell_atlas_coords(layer, neighbor_pos)
  if get_terrain_from_atlas(neighbor_id) == terrain_id:
   bitmask |= (1 << i)
 
 result.bitmask = bitmask
 
 # Determinar tipo estendido
 if same_count == 4:
  result.extended_type = "center"
 elif same_count == 3:
  result.extended_type = "triple"
 elif same_count == 2:
  # Verificar se adjacentes (canto) ou opostos (linha)
  var dirs = []
  for i in range(4):
   var neighbor_pos = pos + [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][i]
   var neighbor_id = tilemap.get_cell_atlas_coords(layer, neighbor_pos)
   if get_terrain_from_atlas(neighbor_id) == terrain_id:
    intersections.append(i)
  
  if intersections.size() == 2:
   if abs(intersections[0] - intersections[1]) == 1 or abs(intersections[0] - intersections[1]) == 3:
    result.extended_type = "corner"
   else:
    result.extended_type = "edge_straight"
 elif same_count == 1:
  result.extended_type = "edge"
 else:
  result.extended_type = "isolated"
 
 return result

static func get_terrain_from_atlas(atlas_coords: Vector2i) -> int:
 # Mapear coordenadas do atlas para ID de terreno
 # Implementar conforme seu atlas
 return -1

# === SELEÇÃO DE TILE ===

static func select_tile(bitmask: int, terrain_type: String, is_animated: bool = false) -> int:
 var base_index = TERRAIN_BASE_INDEX.get(terrain_type, 0)
 
 # Verificar se é animado
 if is_animated and ANIMATED_TERRAINS.has(terrain_type):
  return base_index + ANIMATED_TERRAINS[terrain_type].frames[0]
 
 # Tile base do bitmask
 var tile_index = BITMASK_TO_TILE.get(bitmask, 0)
 return base_index + tile_index

static func select_extended_tile(bitmask_data: Dictionary, terrain_type: String, variations: Array = []) -> int:
 var base_index = TERRAIN_BASE_INDEX.get(terrain_type, 0)
 var bitmask = bitmask_data.bitmask
 var ext_type = bitmask_data.extended_type
 
 # Prioridade: transições especiais > bitmask padrão
 if ext_type == "corner":
  var corner_map = {
   3: "corner_inner_tl",   # UP+RIGHT
   6: "corner_inner_br",   # RIGHT+DOWN
   12: "corner_inner_br",  # DOWN+LEFT
   9: "corner_inner_tl"    # UP+LEFT
  }
  var corner_key = corner_map.get(bitmask, "corner_inner_tl")
  return TERRAIN_TILE_INDICES.get(terrain_type + "_" + corner_key, 0) + base_index
 
 elif ext_type == "triple":
  var triple_map = {
   7: "triple_b",   # UP+RIGHT+DOWN (falta LEFT)
   11: "triple_l",  # UP+RIGHT+LEFT (falta DOWN)
   13: "triple_l",  # UP+DOWN+LEFT (falta RIGHT)
   14: "triple_t"   # RIGHT+DOWN+LEFT (falta UP)
  }
  var triple_key = triple_map.get(bitmask, "triple_t")
  return TERRAIN_TILE_INDICES.get(terrain_type + "_" + triple_key, 0) + base_index
 
 elif ext_type == "center":
  # Escolher variante de preenchimento
  var fill_variants = ["fill_1", "fill_2", "fill_3", "fill_4", "fill_5", "fill_6", "fill_8"]
  var variant = fill_variants[randi() % fill_variants.size()]
  return TERRAIN_TILE_INDICES.get(terrain_type + "_" + variant, 0) + base_index
 
 elif ext_type == "edge":
  var edge_map = {
   1: "edge_detail_1",   # UP
   2: "edge_detail_2",   # RIGHT
   4: "edge_detail_3",   # DOWN
   8: "edge_detail_4"    # LEFT
  }
  var edge_key = edge_map.get(bitmask, "edge_detail_1")
  return TERRAIN_TILE_INDICES.get(terrain_type + "_" + edge_map.get(bitmask, "edge_detail_1"), 0) + base_index
 
 elif ext_type == "isolated":
  return base_index + 0  # Tile isolado
 
 # Fallback para bitmask padrão
 var tile_index = BITMASK_TO_TILE.get(bitmask, 0)
 return base_index + tile_index

# === APLICAÇÃO AUTOMÁTICA ===

func auto_tile_map(tilemap: TileMap, layer: int, terrain_id: int, bounds: Rect2i) -> void:
 for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
  for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
   var pos = Vector2i(x, y)
   var current_id = tilemap.get_cell_atlas_coords(layer, pos)
   var current_terrain = get_terrain_from_atlas(current_id)
   
   if current_terrain == terrain_id:
    var bitmask = calculate_bitmask(tilemap, layer, pos, terrain_id)
    var tile_index = select_tile(bitmask, get_terrain_name(terrain_id))
    tilemap.set_cell(layer, pos, 0, tile_index)
 
   # Verificar transições com terrenos vizinhos
   _apply_transitions(tilemap, layer, pos, terrain_id)

func _apply_transitions(tilemap: TileMap, layer: int, pos: Vector2i, terrain_id: int) -> void:
 var neighbors = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
 
 for i in range(4):
  var neighbor_pos = pos + [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][i]
  var neighbor_id = tilemap.get_cell_atlas_coords(layer, neighbor_pos)
  var neighbor_terrain = get_terrain_from_atlas(neighbor_id)
  
  if neighbor_terrain != -1 and neighbor_terrain != terrain_id:
   # Aplicar tile de transição
   var transition_tile = get_transition_tile(terrain_id, neighbor_terrain, i)
   if transition_tile != -1:
    var transition_layer = layer + 1  # Camada acima
    tilemap.set_cell(transition_layer, neighbor_pos, 0, transition_tile)

static func get_transition_tile(terrain_a: int, terrain_b: int, direction: int) -> int:
 # Retorna tile de transição entre dois terrenos
 # direction: 0=UP, 1=RIGHT, 2=DOWN, 3=LEFT (lado do terrain_a)
 var key = "transition_%d_%d_%d" % [terrain_a, terrain_b, direction]
 return TERRAIN_TILE_INDICES.get(key, -1)

# === VARIANTES ALEATÓRIAS ===

func apply_random_variations(tilemap: TileMap, layer: int, bounds: Rect2i, variation_chance: float = 0.15) -> void:
 for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
  for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
   var pos = Vector2i(x, y)
   var cell_id = tilemap.get_cell_atlas_coords(layer, pos)
   
   if cell_id != -1 and randf() < variation_chance:
    var variations = get_tile_variations(cell_id)
    if variations.size() > 0:
     var variant = variations[randi() % variations.size()]
     tilemap.set_cell(layer, pos, 0, variant)

# === ANIMAÇÃO DE TILES ===

var animated_tile_timers: Dictionary = {}

func setup_animated_tiles(tilemap: TileMap, layer: int) -> void:
 # Configurar timer para tiles animados
 var timer = Timer.new()
 timer.wait_time = 0.2
 timer.autostart = true
 timer.one_shot = false
 timer.timeout.connect(_update_animated_tiles.bind(tilemap, layer))
 add_child(timer)
 timer.start()

func _update_animated_tiles(tilemap: TileMap, layer: int) -> void:
 var used_cells = tilemap.get_used_cells(layer)
 for cell in used_cells:
  var cell_data = tilemap.get_cell_atlas_coords(layer, cell)
  var terrain = get_terrain_from_atlas(cell_data)
  
  if ANIMATED_TERRAINS.has(get_terrain_name(terrain)):
   var anim_data = ANIMATED_TERRAINS[get_terrain_name(terrain)]
   var frame = (Time.get_ticks_msec() / anim_data.frame_duration) % anim_data.frames.size()
   var frame_id = anim_data.frames[frame]
   tilemap.set_cell_atlas_coords(layer, cell, Vector2i(frame_id % 16, frame_id / 16))

# === TERRENOS ANIMADOS ===

static var ANIMATED_TERRAINS: Dictionary = {
 "water": {
  "frames": [0, 1, 2, 3, 4, 5, 6, 7],
  "frame_duration": 0.15
 },
 "lava": {
  "frames": [0, 1, 2, 3],
  "frame_duration": 0.1
 },
 "lava_flow": {
  "frames": [0, 1, 2, 3, 4, 5],
  "frame_duration": 0.1
 },
 "waterfall": {
  "frames": [0, 1, 2, 3, 4, 5, 6, 7],
  "frame_duration": 0.1
 },
 "grass_wind": {
  "frames": [0, 1, 2, 3],
  "frame_duration": 0.5
 },
 "fire": {
  "frames": [0, 1, 2, 3, 3, 2, 1],
  "frame_duration": 0.08
 },
 "torch": {
  "frames": [0, 1, 2, 3, 2, 1],
  "frame_duration": 0.15
 }
}

static var TERRAIN_BASE_INDEX: Dictionary = {
 "grass": 0,
 "dirt": 14,
 "stone": 28,
 "water": 42,
 "lava": 56,
 "sand": 70,
 "snow": 84,
 "castle": 98,
 "cave": 112,
 "forest": 126,
 "swamp": 140,
 "ice": 154,
 "corrupted": 168
}

static var TERRAIN_TILE_INDICES: Dictionary = {
 # Será populado conforme atlas
}

static var ANIMATED_TERRAINS: Dictionary = ANIMATED_TERRAINS

# === FUNÇÕES AUXILIARES ===

static func get_terrain_name(terrain_id: int) -> String:
 for terrain in TERRAIN_BASE_INDEX:
  if TERRAIN_BASE_INDEX[terrain] == terrain_id:
   return terrain
 return "grass"

static func get_terrain_from_atlas(atlas_coords: Vector2i) -> int:
 for terrain in TERRAIN_BASE_INDEX:
  var base = TERRAIN_BASE_INDEX[terrain]
  var atlas_x = atlas_coords.x
  var atlas_y = atlas_coords.y
  var tile_index = atlas_y * 16 + atlas_x  # Assumindo atlas 16 cols
  
  if tile_index >= base and tile_index < base + 48:
   return TERRAIN_BASE_INDEX[terrain]
 return -1

# === EXEMPLO DE USO ===
# var autotile = AutoTileSystem.new()
# autotile.auto_tile_map(tilemap, 0, 0, Rect2i(0, 0, 100, 100))
# autotile.setup_animated_tiles(tilemap, 0)
# autotile.apply_random_variations(tilemap, 0, Rect2i(0, 0, 100, 100), 0.15)