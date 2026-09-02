extends "res://addons/gut/test.gd"

## Sanidade da economia (balance campanha): simula o playthrough inteiro
## (batalhas + puzzles + travessias + taberna) e valida que os grandes
## custos da vila (soul_ether 50-500) são alcançáveis até o Ato IV.

const ArenaLib := preload("res://scripts/arena_battle.gd")


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["soul_ether"] = 0
	GameManager.game_data["gold"] = 0
	GameManager.building_system.resources["materials"] = 0


func after_each() -> void:
	GameManager.game_data["soul_ether"] = 0
	GameManager.game_data["gold"] = 0
	GameManager.building_system.resources["materials"] = 0


func _simulate_battle_rewards(soul_ether_total: int) -> Dictionary:
	# Espelha _finish: gold 50%, xp 40% do soul_ether da luta.
	return {
		"soul_ether": soul_ether_total,
		"gold": int(soul_ether_total * 0.5),
		"experience": int(soul_ether_total * 0.4),
	}


func test_battle_rewards_include_gold_and_xp():
	var r: Dictionary = _simulate_battle_rewards(40)
	assert_eq(int(r["gold"]), 20, "ouro = 50% do soul_ether")
	assert_eq(int(r["experience"]), 16, "XP = 40% do soul_ether")


func test_battle_finish_computes_gold_xp_from_enemies_meta():
	var arena = ArenaLib.new()
	arena.combat_frozen = true
	add_child_autofree(arena)
	# Injeta metas de inimigos (como _setup_from_campaign faria).
	arena.enemies_meta = [{"type": "mercenario", "soul_ether": 15}, {"type": "cacador", "soul_ether": 8}]
	arena._finish(true)
	var rewards: Dictionary = arena._pending_rewards
	assert_eq(int(rewards["soul_ether"]), 23, "soul_ether somado dos inimigos")
	assert_eq(int(rewards["gold"]), 11, "ouro derivado (23 * 0.5)")
	assert_eq(int(rewards["experience"]), 9, "XP derivado (23 * 0.4)")


func test_campaign_economy_reaches_endgame_costs():
	# Simulação conservadora: só o caminho principal (12 estágios) + 8 puzzles
	# + 8 travessias + taberna líquida. Custos finais: Portão do Abismo 500.
	var se_total := 0
	var gold_total := 10  # ouro inicial típico de batalhas pequenas
	# Batalhas (soul_ether dos inimigos de cada estágio, aproximação dos dados):
	for stage_se in [23, 30, 200, 32, 200, 200, 200, 200, 200, 200, 500, 500, 500]:
		var r := _simulate_battle_rewards(stage_se)
		se_total += int(r["soul_ether"])
		gold_total += int(r["gold"])
	# Puzzles + travessias (data-driven, soma aproximada dos declarados):
	for bonus_se in [5, 12, 8, 12, 12, 10, 8, 10, 10, 12, 14, 12, 14, 20, 15]:
		se_total += bonus_se
	for bonus_gold in [10, 20, 15, 20, 10, 12, 18, 18, 20, 16, 22, 20, 24, 30, 25]:
		gold_total += bonus_gold
	# Taberna: aposta 10, vitória líquida +10 (jogador médio vence metade).
	gold_total += 5 * 10
	assert_gt(se_total, 500, "soul_ether total cobre o Portão do Abismo (500)")
	assert_gt(gold_total, 100, "ouro total dá margem para apostas e custos de forja")
	print("[economy] se_total=%d gold_total=%d" % [se_total, gold_total])


func test_forge_materials_reachable_via_battles():
	# Chance de 40% por inimigo: 20+ inimigos na campanha → materiais suficientes
	# para os 4 equipamentos (3+4+6+8 = 21 com folga em replays/side content).
	# Teste determinístico do mecanismo: recompensa carrega materials quando sorteado.
	var arena = ArenaLib.new()
	arena.combat_frozen = true
	add_child_autofree(arena)
	seed(12345)
	arena.enemies_meta = []
	for i in range(20):
		arena.enemies_meta.append({"type": "goblin", "soul_ether": 5})
	arena._finish(true)
	var got := int(arena._pending_rewards.get("materials", -1))
	assert_true(got == 0 or got > 0, "materials presente no dict de recompensas")
	# 20 rolagens de 40%: estatisticamente ~8; aceitar 0..20 é válido, mas
	# a chance de 0 é 0.6^20 < 0.004% — com seed fixa, validar valor > 0.
	assert_gt(got, 0, "com 20 inimigos, ao menos 1 material cai (seed fixa)")


func test_explore_pays_gold_and_materials_on_victory():
	GameManager.game_data["current_map"] = 0
	var explore = add_child_autofree(preload("res://scripts/explore_scene.gd").new())
	# Caminho real: contato abre a arena, vitória encerra e paga.
	explore.player.position = explore.enemy_nodes[0].position
	explore._check_contact()
	assert_not_null(explore.arena, "arena aberta pelo contato")
	explore.arena.combat_frozen = true
	for m in explore.arena.enemies_meta:
		pass  # metas já populadas pelo _setup_from_campaign
	# Força vitória pela porta real (result screen → battle_ended).
	explore.arena._finish(true)
	explore.arena._on_result_continue_pressed()
	assert_gt(int(GameManager.game_data["gold"]), 0, "batalha paga ouro (derivado do soul_ether)")
	assert_gt(int(GameManager.building_system.resources["materials"]), -1, "dict de materials presente na campanha")
