class_name CartographerCore
extends RefCounted
## Cartographer (ferramenta dev): geração determinística de mapas 2D por bioma
## para o MapDatabase, usando FastNoiseLite com seed fixa.
##
## Saída compatível com map.tiles: Array de linhas, cada linha Array[String]
## com os kinds de tile conhecidos (grass/stone/water/lava/path).
##
## Regras de jogabilidade embutidas:
## - Borda do mapa sempre caminhável (grass) — spawns/entradas nunca bloqueiam.
## - Determinístico: mesma seed + bioma + size → mesmos tiles.
## - Densidades por bioma (lava só em volcanic, água ausente em castle).

const BIOMES := {
 "mixed": {"water": 0.10, "stone": 0.18, "noise_scale": 0.09},
 "forest": {"water": 0.14, "stone": 0.14, "noise_scale": 0.08},
 "cave": {"water": 0.08, "stone": 0.45, "noise_scale": 0.11},
 "castle": {"water": 0.0, "stone": 0.42, "noise_scale": 0.07},
 "volcanic": {"water": 0.0, "stone": 0.34, "noise_scale": 0.10},
}

const BORDER := 1  # anel caminhável nas bordas do mapa


## Gera o mapa completo. config: {terrain, size: Vector2i, seed: int, params: Dictionary?}
## params opcionais sobrepõem o bioma: {"water": 0.2, "stone": 0.3, "noise_scale": 0.1}
func generate(config: Dictionary) -> Dictionary:
 var terrain: String = String(config.get("terrain", "mixed"))
 var biome: Dictionary = BIOMES.get(terrain, BIOMES.mixed)
 var params: Dictionary = config.get("params", {})
 var water_density: float = float(params.get("water", biome["water"]))
 var stone_density: float = float(params.get("stone", biome["stone"]))
 var noise_scale: float = float(params.get("noise_scale", biome["noise_scale"]))
 var size: Vector2i = config.get("size", Vector2i(10, 10))
 var seed: int = int(config.get("seed", 0))

 var noise := FastNoiseLite.new()
 noise.seed = seed
 noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
 noise.frequency = noise_scale
 noise.fractal_octaves = 3

 var rng := RandomNumberGenerator.new()
 rng.seed = seed

 var counts := {}
 var tiles: Array = []
 for y in range(size.y):
  var row: Array = []
  for x in range(size.x):
   var kind := _tile_at(x, y, size, noise, rng, water_density, stone_density, terrain, counts)
   row.append(kind)
  tiles.append(row)

 return {"tiles": tiles, "terrain": terrain, "size": size, "seed": seed, "stats": counts}


func _tile_at(x: int, y: int, size: Vector2i, noise: FastNoiseLite, rng: RandomNumberGenerator,
 water_density: float, stone_density: float, terrain: String, counts: Dictionary) -> String:
 # Anel de borda sempre caminhável (spawns, entradas, fluxo linear).
 if x < BORDER or y < BORDER or x >= size.x - BORDER or y >= size.y - BORDER:
  return _count("grass", counts)
 var v: float = noise.get_noise_2d(x, y)  # -1..1
 var roll: float = rng.randf()
 # Vazios (água/lava): só existem se houver densidade. No volcanic o canal
 # de vazios é a lava — presente mesmo sem água configurada.
 var void_density := water_density
 if terrain == "volcanic" and void_density <= 0.0:
  void_density = 0.18
 if void_density > 0.0 and v < -0.30 + void_density * 0.25:
  var wet := "lava" if terrain == "volcanic" else "water"
  return _count(wet, counts)
 # Médio = pedra; alto = piso principal.
 if v < 0.05 + stone_density * 0.25 or roll < stone_density:
  return _count("stone", counts)
 return _count("grass", counts)


func _count(kind: String, counts: Dictionary) -> String:
 counts[kind] = int(counts.get(kind, 0)) + 1
 return kind


## Preview visual (ferramenta dev): PNG colorido por kind. Cores fixas por tile.
const PREVIEW_COLORS := {
 "grass": Color(0.24, 0.45, 0.18),
 "stone": Color(0.42, 0.42, 0.45),
 "water": Color(0.15, 0.35, 0.6),
 "lava": Color(0.85, 0.3, 0.08),
 "path": Color(0.62, 0.52, 0.35),
}

func render_preview(tiles: Array, cell: int = 16) -> Image:
 var h := tiles.size()
 var w: int = tiles[0].size() if h > 0 else 0
 var img := Image.create(w * cell, h * cell, false, Image.FORMAT_RGBA8)
 for y in range(h):
  for x in range(w):
   var kind: String = tiles[y][x]
   var color: Color = PREVIEW_COLORS.get(kind, Color.MAGENTA)
   var jitter := 0.94 + fmod(float(x * 7 + y * 13), 12.0) / 100.0
   var c := Color(minf(color.r * jitter, 1.0), minf(color.g * jitter, 1.0), minf(color.b * jitter, 1.0))
   for cy in range(cell):
    for cx in range(cell):
     img.set_pixel(x * cell + cx, y * cell + cy, c)
 return img
