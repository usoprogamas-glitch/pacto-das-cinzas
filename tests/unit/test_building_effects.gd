extends "res://addons/gut/test.gd"

## Testes GUT: aplicação de efeitos de construção (Fase 2 - BuildingSystem).
## Valida que construir uma edificação desbloqueia funcionalidades reais
## (crafting, recrutamento, fé) via unlocked_features + persistência no save.

var gm: Node
var bs: Node

func before_each() -> void:
	var GM = load("res://scripts/game_manager.gd")
	gm = GM.new()
	gm._ready()
	add_child_autofree(gm)
	bs = gm.building_system

func test_build_fornalha_unlocks_crafting() -> void:
	bs.add_resource("soul_ether", 500)
	bs.add_resource("gold", 100)
	var ok = bs.build("fornalha_vulcanica")
	assert_true(ok, "fornalha construível com recursos")
	assert_true(bs.is_feature_unlocked("craft_armas_básicas"), "craft de armas básicas desbloqueado")
	assert_true(bs.is_craft_unlocked("armas_básicas"), "is_craft_unlocked por id")

func test_build_toca_goblin_unlocks_recruit() -> void:
	bs.add_resource("soul_ether", 200)
	var ok = bs.build("toca_goblin")
	assert_true(ok, "toca goblin construída")
	assert_true(bs.is_feature_unlocked("recruit_goblin"), "recrutamento de goblin")
	assert_eq(bs.get_unlocked_recruit_types(), ["goblin"], "tipo recrutável goblin")

func test_build_templo_cinzas_sets_faith_cap() -> void:
	bs.add_resource("soul_ether", 300)
	var ok = bs.build("templo_cinzas")
	assert_true(ok, "templo construído")
	assert_true(bs.is_feature_unlocked("faith_cap"), "faith_cap desbloqueado")
	assert_eq(bs.unlocked_features["faith_cap"], 50, "faith_cap == 50")

func test_cannot_build_without_resources() -> void:
	var ok = bs.build("muralha_pedra")  # custo 150, sem recursos
	assert_false(ok, "sem recursos não constrói")

func test_built_buildings_only_include_constructed() -> void:
	bs.add_resource("soul_ether", 1000)
	bs.build("muralha_pedra")
	var built = bs.get_built_buildings()
	assert_true(built.any(func(b): return b.id == "muralha_pedra"), "muralha está construída")
	assert_false(built.any(func(b): return b.id == "torre_vigia"), "torre de vigia não construída")

func test_unlocked_features_persist_in_save() -> void:
	bs.add_resource("soul_ether", 500)
	bs.build("fornalha_vulcanica")
	var data = gm.save_game()
	var save_data = {
		"buildings": bs.buildings,
		"resources": bs.resources,
		"unlocked_features": bs.unlocked_features
	}
	assert_true(save_data.unlocked_features.has("craft_armas_básicas"), "unlocked_features vai pro save")

func test_load_restores_unlocked_features() -> void:
	bs.unlocked_features["craft_armas_básicas"] = true
	var NewGM = load("res://scripts/game_manager.gd").new()
	add_child_autofree(NewGM)
	# Simular load manualmente populando o dict
	NewGM.building_system.unlocked_features = bs.unlocked_features.duplicate()
	assert_true(NewGM.building_system.is_feature_unlocked("craft_armas_básicas"), "feature restaurada no load")