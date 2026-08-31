extends "res://addons/gut/test.gd"

## Polimento visual SoS (AUDIT 7d): o fundo chapado da exploração vira uma
## grade 10x6 de tiles decorados gerados pelo PixelArtRenderer (TERRAINS
## data-driven), com shaders de água/grama nos tiles elegíveis do mapa.

const ExploreScript := preload("res://scripts/explore_scene.gd")

var _explore: Node


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	if _explore and is_instance_valid(_explore):
		_explore.free()
	_explore = null


func _open() -> Node:
	_explore = add_child_autofree(ExploreScript.new())
	return _explore


func test_terrain_grid_10x6_built_from_valid_kinds():
	var scene := _open()
	assert_eq(scene.terrain_tiles.size(), 60, "grade 10x6 de tiles decorados")
	var valid := ["grass", "stone", "water", "forest", "cave", "castle", "lava"]
	for t in scene.terrain_tiles:
		assert_true(valid.has(String(t["kind"])), "tipo de terreno válido: %s" % t["kind"])
		assert_true(t["node"].texture != null, "tile com textura procedural")


func test_volcanic_map_uses_lava_and_stone_only_without_shaders():
	GameManager.game_data["current_map"] = 5
	var scene := _open()
	var kinds := {}
	var with_shader := 0
	for t in scene.terrain_tiles:
		kinds[String(t["kind"])] = true
		if t["node"].material != null:
			with_shader += 1
	assert_true(kinds.has("lava"), "vulcão usa tiles de lava")
	assert_true(kinds.has("stone"), "vulcão usa tiles de pedra")
	assert_false(kinds.has("water"), "vulcão não tem água")
	assert_false(kinds.has("grass"), "vulcão não tem grama")
	assert_eq(with_shader, 0, "lava/pedra não recebem shader")


func test_mixed_map_applies_shaders_to_water_or_grass_tiles():
	var scene := _open()
	var with_shader := 0
	for t in scene.terrain_tiles:
		if t["node"].material != null:
			with_shader += 1
	assert_gt(with_shader, 0, "shaders de água/grama aplicados nos tiles elegíveis (determinístico por seed)")


func test_terrain_kind_is_seeded_and_stable():
	var scene := _open()
	var kinds_first: Array = []
	for t in scene.terrain_tiles:
		kinds_first.append(String(t["kind"]))
	_explore.free()
	_explore = null
	var scene2 := _open()
	var kinds_second: Array = []
	for t in scene2.terrain_tiles:
		kinds_second.append(String(t["kind"]))
	assert_eq(kinds_first, kinds_second, "layout de tiles estável entre visitas (seed por mapa)")
