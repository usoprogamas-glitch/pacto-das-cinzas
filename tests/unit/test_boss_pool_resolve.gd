extends "res://addons/gut/test.gd"
## Testes GUT: pool de inimigos data-driven (ROADMAP #8)
## Valida _resolve_enemy_pool do battle_scene: estágio de campanha pode declarar
## "boss_enemy" (Ato I, mapa compartilhado); Atos II-IV usam o pool próprio do
## mapa (Cardeais/Aurius). Sem hardcode de chefe na lógica.

const BattleSceneScript := preload("res://scripts/battle_scene.gd")

var bs: Node

func before_each() -> void:
	bs = BattleSceneScript.new()
	GameManager.campaign_system.reset()

func after_each() -> void:
	GameManager.campaign_system.reset()
	if is_instance_valid(bs):
		bs.free()

func _map_pool() -> Dictionary:
	return MapDatabase.get_map(0)

func test_act1_final_stage_resolves_to_declared_boss_enemy():
	# Ato I, stage 1 (chefe orc): estágio declara boss_enemy → pool substituído.
	GameManager.campaign_system.advance_stage()
	var pool = bs._resolve_enemy_pool(_map_pool())
	assert_eq(pool.enemies, ["orc_chefe"], "chefe do Ato I spawna orc_chefe declarado no estágio")
	assert_eq(pool.count, 1, "chefe de ato é 1 unidade")

func test_act1_common_stage_uses_map_pool():
	# Ato I, stage 0 (não-boss): pool normal do mapa 0.
	var pool = bs._resolve_enemy_pool(_map_pool())
	assert_eq(pool.enemies, ["mercenario", "cacador"], "batalha comum usa o pool do mapa")
	assert_eq(pool.count, 3, "contagem de inimigos do mapa preservada")

func test_act2_cardeal_pool_comes_from_map_not_hardcode():
	# Ato II stage 0 (Ignis, boss não-final): SEM boss_enemy no estágio → o pool
	# do mapa 5 (cardeal_ignis) vale. Antes do fix, todo final vira orc_chefe.
	GameManager.campaign_system.complete_act()  # ato 2, stage 0
	var pool = bs._resolve_enemy_pool(MapDatabase.get_map(5))
	assert_eq(pool.enemies, ["cardeal_ignis"], "Cardeal Ignis vem do mapa, não de hardcode")
	assert_eq(pool.count, 1)

func test_act4_final_stage_aurius_from_map():
	# Ato IV, stage 2 (Aurius Fase 3, final): sem boss_enemy → pool do mapa 12.
	GameManager.campaign_system.complete_act()
	GameManager.campaign_system.mark_act_intro_seen()
	GameManager.campaign_system.complete_act()
	GameManager.campaign_system.mark_act_intro_seen()
	GameManager.campaign_system.complete_act()
	GameManager.campaign_system.mark_act_intro_seen()
	GameManager.campaign_system.complete_act()  # fim: current_stage = 0 do ato 4
	# Reposiciona no último estágio do Ato IV para inspecionar a decisão
	GameManager.campaign_system.current_stage = 2
	var pool = bs._resolve_enemy_pool(MapDatabase.get_map(12))
	assert_eq(pool.enemies, ["aurius_fase3"], "Aurius Fase 3 vem do mapa")
	assert_eq(pool.count, 1)

func test_resolve_pool_without_campaign_uses_map_pool():
	# Caminho defensivo: sem CampaignSystem, o pool do mapa vale (não crasha).
	# (Mesmo padrão do teste do epílogo: nula a propriedade do autoload.)
	var cs_backup = GameManager.campaign_system
	GameManager.campaign_system = null
	var pool = bs._resolve_enemy_pool(_map_pool())
	GameManager.campaign_system = cs_backup
	assert_eq(pool.enemies, ["mercenario", "cacador"])
	assert_eq(pool.count, 3)

func test_resolve_pool_with_empty_map_returns_empty_pool():
	# Mapa inexistente → pool vazio; o chamador (setup_battle) não itera.
	var pool = bs._resolve_enemy_pool({})
	assert_eq(pool.enemies.size(), 0)
	assert_eq(pool.count, 1, "default defensivo de contagem")

func test_all_act_final_bosses_exist_in_enemy_database():
	# Contrato de conteúdo: todo boss_enemy declarado na campanha existe no
	# EnemyDatabase e todo mapa de ato II-IV aponta para um inimigo existente.
	var cs = CampaignSystem.new()
	for act in cs.ACT_STAGES.keys():
		for stage in cs.ACT_STAGES[act]:
			if stage.get("boss_enemy", "") != "":
				assert_false(EnemyDatabase.get_enemy(stage.boss_enemy).is_empty(),
					"boss_enemy '%s' existe no EnemyDatabase" % stage.boss_enemy)
	for map_id in [5, 6, 7, 8, 9, 10, 11, 12]:
		var map = MapDatabase.get_map(map_id)
		assert_eq(map.enemies.size(), 1, "mapa de chefe tem exatamente 1 inimigo")
		assert_false(EnemyDatabase.get_enemy(map.enemies[0]).is_empty(),
			"chefe do mapa %d existe no EnemyDatabase" % map_id)
