extends "res://addons/gut/test.gd"

## Fluxo linear de enredo (decisão 2026-08-31): intro/cutscene/pós-vitória
## entram direto na batalha do estágio atual da campanha — map_select fica fora
## do caminho principal. O sync do map_id é a cola entre CampaignSystem e a
## batalha (setup_battle lê game_data["current_map"]).

func before_each() -> void:
	GameManager.campaign_system.reset()


func after_each() -> void:
	GameManager.campaign_system.reset()


func test_sync_follows_first_stage_of_act_i():
	GameManager.sync_current_map_from_campaign()
	assert_eq(GameManager.game_data.get("current_map"), 0, "Ato I estágio 1 (Socorro aos Goblins) = map 0")


func test_sync_follows_next_act_stage():
	# Simula o avanço para o Ato II (Ignis, map 5).
	GameManager.campaign_system.current_act = 2
	GameManager.campaign_system.current_stage = 0
	GameManager.sync_current_map_from_campaign()
	assert_eq(GameManager.game_data.get("current_map"), 5, "Ato II estágio 1 (Ignis) = map 5")


func test_sync_noop_when_stage_list_exhausted():
	# Defensivo: estágio inexistente não deve crashar nem sobrescrever o map atual.
	GameManager.game_data["current_map"] = 3
	GameManager.campaign_system.current_act = 9
	GameManager.campaign_system.current_stage = 5
	GameManager.sync_current_map_from_campaign()
	assert_eq(GameManager.game_data.get("current_map"), 3, "estágio vazio = map atual preservado")


# === Molde SoS (opção 3): caminho principal usa EXPLORAÇÃO, não grid ===

func test_linear_flow_routes_to_explore_scene():
	var bs: Node = load("res://scripts/battle/battle_scene.gd").new()
	GameManager.campaign_system.reset()
	assert_eq(bs._get_post_victory_destination(), "explore", "ato em curso → exploração do próximo estágio")
	bs.free()


func test_scene_manager_knows_explore():
	assert_true(SceneManager.scenes.has("explore"), "cena de exploração registrada")
	assert_eq(SceneManager.scenes["explore"], "res://scenes/battle/explore_scene.tscn")
