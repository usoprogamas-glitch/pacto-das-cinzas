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
   "props": [],
   "puzzles": [
    {
     "id": "fronteira_espelhos",
     "type": "mirror_alignment",
     "light": Vector2i(3, 3),
     "target": Vector2i(12, 3),
     "mirrors": [
      {"id": "m1", "pos": Vector2i(6, 3), "angle": 1},
      {"id": "m2", "pos": Vector2i(9, 3), "angle": 7}
     ],
     "rewards": {"soul_ether": 5, "gold": 10, "xp": 40}
    }
   ],
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
  "props": [],
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
   "props": [],
   "traversal_nodes": [
    {
     "id": "precipicio_caverna",
     "ability": "ether_harpoon",
     "pos": Vector2i(8, 3),
     "label": "PRECIPÍCIO — E para arpéu",
     "rewards": {"soul_ether": 8, "gold": 14, "xp": 85}
    }
   ],
   "puzzles": [
    {
     "id": "caverna_sombra",
     "type": "shadow_reveal",
     "light": Vector2i(1, 5),
     "target": Vector2i(8, 5),
     "clock": Vector2i(4, 2),
     "mirrors": [
      {"id": "m1", "pos": Vector2i(4, 5), "angle": 2}
     ],
     "rewards": {"soul_ether": 10, "gold": 15, "xp": 95}
    }
   ],
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
   "waves": [
    {"enemies": ["paladino", "inquisidor"], "stat_scale": 1.0},
    {"enemies": ["paladino", "inquisidor", "paladino"], "stat_scale": 1.25},
    {"enemies": ["santo_cardeal"], "stat_scale": 1.5}
   ],
   "puzzles": [
    {
     "id": "castelo_espelhos",
     "type": "mirror_alignment",
     "light": Vector2i(1, 12),
     "target": Vector2i(12, 1),
     "mirrors": [
      {"id": "m1", "pos": Vector2i(5, 9), "angle": 1},
      {"id": "m2", "pos": Vector2i(8, 5), "angle": 4}
     ],
     "rewards": {"soul_ether": 12, "gold": 20, "xp": 140}
    }
   ],
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
  "props": [],
  "traversal_nodes": [
   {
    "id": "garganta_vulcao",
    "ability": "climb",
    "pos": Vector2i(10, 6),
    "label": "GARGANTA DO VULCÃO — E para escalar",
    "rewards": {"soul_ether": 12, "gold": 20, "xp": 130}
   }
  ],
  "puzzles": [
   {
    "id": "vulcao_eclipse",
    "type": "eclipse_timing",
    "light": Vector2i(1, 10),
    "target": Vector2i(10, 1),
    "clock": Vector2i(2, 10),
    "rewards": {"soul_ether": 12, "gold": 18, "xp": 125}
   }
  ],
  "tiles": generate_volcanic_map()
 },
  # ===== ATO II — CARDEAIS =====
 5: {
  "name": "Vale dos Despojos — Ignis",
  "size": Vector2i(12, 12),
  "terrain": "volcanic",
  "enemies": ["cardeal_ignis"],
  "enemy_count": 1,
  "description": "Plataformas sobre lava branca. Ignis aguarda no vulcão.",
  "music": "battle",
  "props": [
   {"texture": "estatua_ignis", "pos": Vector2i(9, 2), "scale": 1.6},
   {"texture": "arvore_queimada", "pos": Vector2i(2, 9), "scale": 1.4},
   {"texture": "arvore_queimada", "pos": Vector2i(10, 8), "scale": 1.3}
  ],
    "puzzles": [
     {
      "id": "despojos_sombras",
      "type": "shadow_reveal",
      "light": Vector2i(2, 6),
      "target": Vector2i(9, 6),
      "clock": Vector2i(8, 4),
      "mirrors": [
       {"id": "m1", "pos": Vector2i(5, 6), "angle": 6}
      ],
    "rewards": {"soul_ether": 8, "gold": 15, "xp": 80}
   }
  ],
  "traversal_nodes": [
   {
    "id": "fenda_ignis",
    "ability": "ether_harpoon",
    "pos": Vector2i(6, 2),
    "label": "FENDA DE ÉTER — E para arpéu (precisa de Asas)",
    "rewards": {"soul_ether": 12, "gold": 20, "xp": 120},
    "grants_wings": false
   },
   {
    "id": "penhasco_ignis",
    "ability": "climb",
    "pos": Vector2i(2, 3),
    "label": "PENHASCO — E para escalar",
    "rewards": {"soul_ether": 6, "gold": 10, "xp": 60},
    "grants_wings": false
   }
  ],
    "tiles": generate_volcanic_map()
   },
 6: {
  "name": "Floresta dos Ventos — Zephyr",
  "size": Vector2i(14, 14),
  "terrain": "forest",
  "enemies": ["cardeal_zephyr"],
  "enemy_count": 1,
  "description": "Tempestades de vento. Zephyr comanda as alturas.",
  "music": "battle",
  "props": [
   {"texture": "estatua_zephyr", "pos": Vector2i(7, 1), "scale": 1.7}
  ],
  "traversal_nodes": [
   {
    "id": "desfiladeiro_zephyr",
    "ability": "dash",
    "pos": Vector2i(4, 7),
    "label": "DESFILADEIRO — E para impulso",
    "rewards": {"soul_ether": 8, "gold": 12, "xp": 90},
    "grants_wings": true
   }
  ],
  "puzzles": [
   {
    "id": "ventos_espelhos",
    "type": "mirror_alignment",
    "light": Vector2i(2, 11),
    "target": Vector2i(11, 2),
    "mirrors": [
     {"id": "m1", "pos": Vector2i(6, 9), "angle": 1},
     {"id": "m2", "pos": Vector2i(9, 6), "angle": 4}
    ],
    "rewards": {"soul_ether": 10, "gold": 18, "xp": 110}
   }
  ],
  "tiles": generate_forest_map()
 },
 7: {
  "name": "Lago Corrosivo — Aqua",
  "size": Vector2i(12, 12),
  "terrain": "cave",
  "enemies": ["cardeal_aqua"],
  "enemy_count": 1,
  "description": "Águas bentas corrosivas. O cálice aguarda.",
  "music": "battle",
  "props": [
   {"texture": "calice_corrosivo", "pos": Vector2i(6, 5), "scale": 1.5}
  ],
  "traversal_nodes": [
   {
    "id": "corrente_subterranea",
    "ability": "ether_harpoon",
    "pos": Vector2i(3, 8),
    "label": "CORRENTE DE ÉTER — E para arpéu",
    "rewards": {"soul_ether": 10, "gold": 18, "xp": 110}
   }
  ],
  "puzzles": [
   {
    "id": "lago_eclipse",
    "type": "eclipse_timing",
    "light": Vector2i(1, 1),
    "target": Vector2i(10, 10),
    "clock": Vector2i(6, 1),
    "rewards": {"soul_ether": 12, "gold": 20, "xp": 130}
   }
  ],
  "tiles": generate_cave_map()
 },
 8: {
  "name": "Fortaleza de Mármore — Terra",
  "size": Vector2i(14, 14),
  "terrain": "castle",
  "enemies": ["cardeal_terra"],
  "enemy_count": 1,
  "description": "Muralhas vivas se fecham. Terra não cede.",
  "music": "battle",
  "props": [
   {"texture": "estatua_templo", "pos": Vector2i(3, 2), "scale": 1.7},
   {"texture": "estatua_templo", "pos": Vector2i(10, 2), "scale": 1.7}
  ],
  "traversal_nodes": [
   {
    "id": "muralha_terra",
    "ability": "climb",
    "pos": Vector2i(5, 4),
    "label": "MURALHA VIVA — E para escalar",
    "rewards": {"soul_ether": 10, "gold": 16, "xp": 120}
   }
  ],
  "puzzles": [
   {
    "id": "marmore_ponte",
    "type": "light_bridge",
    "light": Vector2i(1, 12),
    "target": Vector2i(12, 1),
    "mirrors": [
     {"id": "m1", "pos": Vector2i(4, 10), "angle": 1},
     {"id": "m2", "pos": Vector2i(7, 7), "angle": 1},
     {"id": "m3", "pos": Vector2i(10, 4), "angle": 1}
    ],
    "rewards": {"soul_ether": 14, "gold": 22, "xp": 150}
   }
  ],
  "tiles": generate_castle_map()
 },
 9: {
  "name": "Abismo das Sombras — Umbra",
  "size": Vector2i(14, 14),
  "terrain": "castle",
  "enemies": ["cardeal_umbra"],
  "enemy_count": 1,
  "description": "Ilusões de luz negra. A máscara aguarda.",
  "music": "battle",
  "props": [
   {"texture": "braseiro_solaris", "pos": Vector2i(3, 7), "scale": 1.4},
   {"texture": "braseiro_solaris", "pos": Vector2i(10, 7), "scale": 1.4}
  ],
  "traversal_nodes": [
   {
    "id": "fosso_umbra",
    "ability": "dash",
    "pos": Vector2i(6, 9),
    "label": "FOSSO DAS SOMBRAS — E para impulso",
    "rewards": {"soul_ether": 12, "gold": 20, "xp": 140}
   }
  ],
  "puzzles": [
   {
    "id": "sombra_umbra",
    "type": "shadow_reveal",
    "light": Vector2i(2, 7),
    "target": Vector2i(11, 7),
    "clock": Vector2i(8, 3),
    "mirrors": [
     {"id": "m1", "pos": Vector2i(6, 7), "angle": 2}
    ],
    "rewards": {"soul_ether": 14, "gold": 24, "xp": 160}
   }
  ],
  "tiles": generate_castle_map()
 },
  # ===== ATO IV — AURIUS =====
 10: {
  "name": "Solaria — Sala do Trono",
  "size": Vector2i(16, 16),
  "terrain": "castle",
  "enemies": ["aurius_fase1"],
  "enemy_count": 1,
  "description": "Trono monumental. O Falso Demiurgo aguarda.",
  "music": "battle",
  "props": [
   {"texture": "coluna_solaris", "pos": Vector2i(5, 4), "scale": 1.8},
   {"texture": "coluna_solaris", "pos": Vector2i(10, 4), "scale": 1.8},
   {"texture": "portal_solaria", "pos": Vector2i(8, 1), "scale": 1.6},
   {"texture": "braseiro_solaris", "pos": Vector2i(4, 7), "scale": 1.4},
   {"texture": "braseiro_solaris", "pos": Vector2i(11, 7), "scale": 1.4}
  ],
  "puzzles": [
   {
    "id": "trono_eclipse",
    "type": "eclipse_timing",
    "light": Vector2i(1, 14),
    "target": Vector2i(14, 1),
    "clock": Vector2i(13, 3),
    "rewards": {"soul_ether": 20, "gold": 30, "xp": 200}
   }
  ],
  "traversal_nodes": [
   {
    "id": "escada_trono",
    "ability": "climb",
    "pos": Vector2i(7, 10),
    "label": "ESCADADA DO TRONO — E para escalar",
    "rewards": {"soul_ether": 15, "gold": 25, "xp": 160}
   }
  ],
  "tiles": generate_castle_map()
 },
  11: {
   "name": "Solaria — Cúpula Solar",
   "size": Vector2i(16, 16),
   "terrain": "castle",
   "enemies": ["aurius_fase2"],
   "enemy_count": 1,
  "description": "Asas solares cortam o céu. O Serafim Tirano voa.",
  "music": "battle",
  "props": [
   {"texture": "coluna_solaris", "pos": Vector2i(4, 5), "scale": 1.8},
   {"texture": "coluna_solaris", "pos": Vector2i(11, 5), "scale": 1.8}
  ],
   "tiles": generate_castle_map()
  },
  12: {
   "name": "Solaria — Núcleo Instável",
   "size": Vector2i(16, 16),
   "terrain": "castle",
   "enemies": ["aurius_fase3"],
   "enemy_count": 1,
  "description": "O núcleo brilha. A Luz Desesperada aguarda.",
  "music": "battle",
  "props": [
   {"texture": "portal_solaria", "pos": Vector2i(8, 2), "scale": 1.8}
  ],
   "tiles": generate_castle_map()
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
