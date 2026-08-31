extends "res://addons/gut/test.gd"

## Testes GUT: fonte única de stages para o mapa (Fase 3 - Map Select Data-Driven).
## Valida que CampaignSystem.get_campaign_stages() expõe os stages com ato/bloqueio,
## e que select_map sincroniza o estágio corrente.

var cs: RefCounted

func before_each() -> void:
	var CS = load("res://scripts/campaign/campaign_system.gd")
	cs = CS.new()

func test_get_campaign_stages_lists_all_acts() -> void:
	var stages = cs.get_campaign_stages()
	assert_eq(stages.size(), 7, "7 stages: 2(AtoI)+2(AtoII)+2(AtoIII)+1(AtoIV)")
	assert_eq(stages[0].name, "Socorro aos Goblins", "primeiro stage é o Ato I")
	assert_eq(stages[0].act, 1, "stage carrega ato")

func test_stages_have_locked_flag() -> void:
	var stages = cs.get_campaign_stages()
	var first = stages[0]
	var later = stages[2]
	assert_false(first.locked, "primeiro stage (mapa 0 do ato 1) desbloqueado")
	assert_true(later.locked, "stage futuro bloqueado")

func test_select_map_syncs_current_stage() -> void:
	cs.select_map(0)
	assert_eq(cs.get_current_stage().name, "Socorro aos Goblins", "selecionar mapa 0 -> stage 0")

func test_select_map_boss_stage() -> void:
	# Avançar para o stage do chefe do Ato I (map_id 0, boss=true = índice 1)
	cs.select_map(0)  # stage 0
	cs.advance_stage()  # stage 1 = O Chefe Orc
	assert_true(cs.is_act_boss_stage(), "stage do chefe marcado como boss")

func test_select_map_unknown_falls_back() -> void:
	cs.advance_stage()  # vai para stage 1
	cs.select_map(999)  # id inexistente
	assert_eq(cs.current_stage, 1, "seleção desconhecida não altera estágio")
