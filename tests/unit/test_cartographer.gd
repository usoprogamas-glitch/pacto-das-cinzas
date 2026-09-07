extends "res://addons/gut/test.gd"

## Cartographer (ferramenta dev): geração determinística de mapas por bioma
## com FastNoiseLite + seed, borda caminhável e override JSON no MapDatabase.

const Core := preload("res://scripts/dev/cartographer_core.gd")

var core


func before_each() -> void:
	core = Core.new()


func after_each() -> void:
	core = null


func test_same_seed_produces_identical_tiles():
	var cfg := {"terrain": "volcanic", "size": Vector2i(12, 12), "seed": 611}
	var a: Dictionary = core.generate(cfg)
	var b: Dictionary = core.generate(cfg)
	assert_eq(JSON.stringify(a["tiles"]), JSON.stringify(b["tiles"]), "mesma seed → mesmos tiles")


func test_different_seed_changes_tiles():
	var a: Dictionary = core.generate({"terrain": "forest", "size": Vector2i(10, 10), "seed": 1})
	var b: Dictionary = core.generate({"terrain": "forest", "size": Vector2i(10, 10), "seed": 2})
	assert_ne(JSON.stringify(a["tiles"]), JSON.stringify(b["tiles"]), "seeds distintas → mapas distintos")


func test_border_is_always_walkable():
	var res: Dictionary = core.generate({"terrain": "volcanic", "size": Vector2i(12, 12), "seed": 99})
	var tiles: Array = res["tiles"]
	for x in range(12):
		assert_eq(tiles[0][x], "grass", "borda superior caminhável")
		assert_eq(tiles[11][x], "grass", "borda inferior caminhável")
	for y in range(12):
		assert_eq(tiles[y][0], "grass", "borda esquerda caminhável")
		assert_eq(tiles[y][11], "grass", "borda direita caminhável")


func test_volcanic_has_lava_and_stats():
	var res: Dictionary = core.generate({"terrain": "volcanic", "size": Vector2i(14, 14), "seed": 42})
	assert_true(res["stats"].has("lava"), "volcanic tem lava (noise de vazios)")
	assert_gt(int(res["stats"].get("lava", 0)), 0, "lava presente no bioma vulcânico")


func test_castle_has_no_water():
	var res: Dictionary = core.generate({"terrain": "castle", "size": Vector2i(14, 14), "seed": 7})
	assert_false(res["stats"].has("water"), "castle não gera água (densidade 0)")


func test_cave_is_stone_dominant():
	var res: Dictionary = core.generate({"terrain": "cave", "size": Vector2i(14, 14), "seed": 5})
	var stone: int = int(res["stats"].get("stone", 0))
	var grass: int = int(res["stats"].get("grass", 0))
	assert_gt(stone, grass, "caverna dominada por pedra")


func test_size_respected():
	var res: Dictionary = core.generate({"terrain": "mixed", "size": Vector2i(8, 6), "seed": 3})
	assert_eq(res["tiles"].size(), 6, "linhas = size.y")
	for row in res["tiles"]:
		assert_eq(row.size(), 8, "colunas = size.x")


func test_render_preview_produces_image():
	var res: Dictionary = core.generate({"terrain": "forest", "size": Vector2i(10, 10), "seed": 11})
	var img: Image = core.render_preview(res["tiles"], 16)
	assert_eq(img.get_width(), 160, "preview 160px de largura")
	assert_eq(img.get_height(), 160, "preview 160px de altura")
