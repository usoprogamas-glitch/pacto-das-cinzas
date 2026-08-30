extends "res://addons/gut/test.gd"
## Testes GUT: persistência do campaign_system (ROADMAP #2)
## O save_game() nunca foi chamado em produção; o wiring agora existe, então
## validar a serialização sem tocar em user://.

func test_campaign_system_serializes_and_restores():
	var cs = CampaignSystem.new()
	cs.advance_stage()
	cs.complete_act()  # act 2
	var data = cs.serialize()
	var cs2 = CampaignSystem.new()
	cs2.deserialize(data)
	assert_eq(cs2.current_act, 2, "ato restaurado pelo save")
	assert_eq(cs2.current_stage, 0, "stage zera ao avançar de ato")

func test_game_manager_save_game_carries_campaign_system():
	# GameManager é autoload em GUT headless. build_game() não é público, então
	# validamos que o campo existe e serializa — sem chamar save_game (que faz IO).
	assert_not_null(GameManager.campaign_system, "GameManager deve criar o CampaignSystem")
	var data = GameManager.campaign_system.serialize()
	assert_true(data.has("current_act"), "save data carrega estado de ato")
