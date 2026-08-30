extends "res://addons/gut/test.gd"
## Testes GUT: CampaignSystem (ROADMAP #2) — gating de atos + serialização.

func _make_campaign() -> CampaignSystem:
	return CampaignSystem.new()

func test_initial_state_act1_map0_only():
	var cs = _make_campaign()
	assert_eq(cs.current_act, 1)
	assert_eq(cs.current_stage, 0)
	assert_eq(cs.get_current_stage().map_id, 0)
	assert_false(cs.is_act_boss_stage())

func test_advance_stage_returns_between_steps():
	var cs = _make_campaign()
	cs.advance_stage()
	assert_eq(cs.current_stage, 1)
	assert_true(cs.is_act_boss_stage())
	assert_true(cs.get_current_stage().get("final", false))
	# at the last stage, advance is a no-op
	cs.advance_stage()
	assert_eq(cs.current_stage, 1)

func test_complete_act_unlocks_next():
	var cs = _make_campaign()
	cs.complete_act()
	assert_eq(cs.current_act, 2)
	assert_eq(cs.current_stage, 0)
	assert_true(cs.is_stage_playable(1))
	assert_true(cs.is_stage_playable(0))  # map 0 still reachable
	assert_false(cs.is_stage_playable(2))  # map 2 belongs to act 3

func test_is_stage_playable_respects_act_locking():
	var cs = _make_campaign()
	# At act 1, only map 0 is reachable.
	assert_true(cs.is_stage_playable(0))
	assert_false(cs.is_stage_playable(1))
	assert_false(cs.is_stage_playable(2))
	assert_false(cs.is_stage_playable(3))
	assert_false(cs.is_stage_playable(4))

func test_maps_unlock_after_act_complete():
	var cs = _make_campaign()
	cs.complete_act()  # act 2 now reachable
	assert_true(cs.is_stage_playable(0))
	assert_true(cs.is_stage_playable(1))
	assert_false(cs.is_stage_playable(2))
	assert_false(cs.is_stage_playable(3))
	# map 4 belongs to act 4 (act 3), locked until act 3
	assert_false(cs.is_stage_playable(4))

func test_serialize_roundtrip():
	var cs = _make_campaign()
	cs.advance_stage()
	cs.complete_act()
	var data = cs.serialize()
	var cs2 = _make_campaign()
	cs2.deserialize(data)
	assert_eq(cs2.current_act, cs.current_act)
	assert_eq(cs2.current_stage, cs.current_stage)

func test_full_act_run_progresses_stage_then_completes_act():
	# Contrato que o battle_scene._on_battle_won segue: vitória em estágio NÃO-boss
	# avança o estágio (advance_stage); vitória em estágio boss completa o ato.
	var cs = _make_campaign()
	# 1º estágio do ato 1 (não é boss) não pode ser pulado: avanço = stage 1.
	assert_false(cs.is_act_boss_stage())
	cs.advance_stage()
	assert_eq(cs.current_stage, 1, "vitória normal avança para o estágio do chefe")
	assert_true(cs.is_act_boss_stage())
	# vitória do chefe: completa o ato → ato 2, stage 0, desbloqueia map 1.
	cs.complete_act()
	assert_eq(cs.current_act, 2, "chefe encerra o ato")
	assert_eq(cs.current_stage, 0, "novo ato recomeça no 1º estágio")
	assert_true(cs.is_stage_playable(1), "map do ato 2 agora jogável")
