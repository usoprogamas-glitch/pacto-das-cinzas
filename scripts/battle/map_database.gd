class_name MapDatabase
extends RefCounted

static var maps: Dictionary = {
 0: {
  "name": "Fronteira Cinzenta",
  "size": Vector2i(10, 10),
  "terrain": "mixed",
  "enemies": ["mercenario", "cacador"],
  "enemy_count": 3,
  "description": "Onde tudo começou. Terreno baldio com vegetação morta.",
  "music": "exploration",
  "tiles": generate_frontier_map()
 },
 1: {
  "name": "Floresta Sombria",
  "size": Vector2i(12, 12),
  "terrain": "forest",
  "enemies": ["lobo_sombrio", "aranha_gigante"],
  "enemy_count": 5,
  "description": "Floresta densa e perigosa.",
  "music": "exploration",
  "tiles": generate_forest_map()
 },
 2: {
  "name": "Caverna Profunda",
  "size": Vector2i(10, 10),
  "terrain": "cave",
  "enemies": ["esqueleto", "troll"],
  "enemy_count": 4,
  "description": "Sistema de cavernas com cristais brilhantes.",
  "music": "exploration",
  "tiles": generate_cave_map()
 },
 3: {
  "name": "Castelo Solaris",
  "size": Vector2i(14, 14),
  "terrain": "castle",
  "enemies": ["inquisidor", "paladino"],
  "enemy_count": 6,
  "description": "A fortaleza da Igreja.",
  "music": "battle",
  "tiles": generate_castle_map()
 },
 4: {
  "name": "Vulcão do Abismo",
  "size": Vector2i(12, 12),
  "terrain": "volcanic",
  "enemies": ["troll", "santo_cardeal"],
  "enemy_count": 4,
  "description": "Terra de ninguém. Feras elementais e lava.",
  "music": "battle",
  "tiles": generate_volcanic_map()
 }
}

static func generate_frontier_map() -> Array:
 var tiles = []
 for y in range(10):
  var row = []
  for x in range(10):
   if randf() < 0.2:
    row.append("stone")
   elif randf() < 0.1:
    row.append("water")
   else:
    row.append("grass")
  tiles.append(row)
 return tiles

static func generate_forest_map() -> Array:
 var tiles = []
 for y in range(12):
  var row = []
  for x in range(12):
   if randf() < 0.3:
    row.append("stone")
   elif randf() < 0.15:
    row.append("water")
   else:
    row.append("grass")
  tiles.append(row)
 return tiles

static func generate_cave_map() -> Array:
 var tiles = []
 for y in range(10):
  var row = []
  for x in range(10):
   if randf() < 0.4:
    row.append("stone")
   elif randf() < 0.1:
    row.append("water")
   else:
    row.append("grass")
  tiles.append(row)
 return tiles

static func generate_castle_map() -> Array:
 var tiles = []
 for y in range(14):
  var row = []
  for x in range(14):
   if randf() < 0.5:
    row.append("stone")
   else:
    row.append("grass")
  tiles.append(row)
 return tiles

static func generate_volcanic_map() -> Array:
 var tiles = []
 for y in range(12):
  var row = []
  for x in range(12):
   if randf() < 0.3:
    row.append("lava")
   elif randf() < 0.4:
    row.append("stone")
   else:
    row.append("grass")
  tiles.append(row)
 return tiles

static func get_map(map_id: int) -> Dictionary:
 if maps.has(map_id):
  return maps[map_id]
 return {}

static func get_random_spawn_position(map_id: int) -> Vector2i:
 var map = get_map(map_id)
 var size = map.get("size", Vector2i(10, 10))
 return Vector2i(randi() % size.x, randi() % size.y)

static func get_enemy_spawn_positions(map_id: int, count: int) -> Array:
 var positions = []
 var map = get_map(map_id)
 var size = map.get("size", Vector2i(10, 10))

 for i in range(count):
  var pos = Vector2i(
   size.x - 1 - (randi() % 3),
   randi() % size.y
  )
  while pos in positions:
   pos = Vector2i(
    size.x - 1 - (randi() % 3),
    randi() % size.y
   )
  positions.append(pos)

 return positions

static func get_player_spawn_positions(map_id: int, count: int) -> Array:
 var positions = []
 var map = get_map(map_id)

 for i in range(count):
  var pos = Vector2i(
   randi() % 2,
   1 + i * 2
  )
  while pos in positions:
   pos = Vector2i(
    randi() % 2,
    1 + i * 2
   )
  positions.append(pos)

 return positions
