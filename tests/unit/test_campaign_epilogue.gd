extends "res://addons/gut/test.gd"
## Testes GUT: fim de campanha + epílogo (ROADMAP #2)
## Valida o ciclo game_completed no CampaignSystem, o roteamento pós-vitória
## do battle_scene e a cena de epílogo.

const BattleSceneScript := preload("res://scripts/battle_scene.gd")

func _make_campaign() -> CampaignSystem:
	return CampaignSystem.new()

func test_complete_acts_one_to_three_does_not_end_game():
	var cs = _make_campaign()
	for i in range(3):
		cs.complete_act()
	assert_eq(cs.current_act, 4)
	assert_false(cs.is_game_complete(), "ato 4 ainda jogável — jogo não acabou")

func test_complete_final_act_marks_game_complete():
	var cs = _make_campaign()
	for i in range(4):
		cs.complete_act()
	assert_true(cs.is_game_complete(), "Aurius Fase 3 derrotado — campanha completa")

func test_serialize_roundtrip_carries_completion():
	var cs = _make_campaign()
	for i in range(4):
		cs.complete_act()
	var cs2 = _make_campaign()
	cs2.deserialize(cs.serialize())
	assert_true(cs2.is_game_complete(), "game_completed sobrevive ao save/load")

func test_reset_clears_completion():
	var cs = _make_campaign()
	for i in range(4):
		cs.complete_act()
	cs.reset()
	assert_false(cs.is_game_complete(), "novo jogo limpa o fim de campanha")

func test_post_victory_destination_routes_to_epilogue():
	var bs: Node = BattleSceneScript.new()
	GameManager.campaign_system.reset()
	# Fluxo linear de enredo: campanha em curso → próxima batalha.
	assert_eq(bs._get_post_victory_destination(), "explore", "campanha em curso → exploração")
	GameManager.campaign_system.game_completed = true
	assert_eq(bs._get_post_victory_destination(), "epilogue", "campanha completa → epílogo")
	GameManager.campaign_system.reset()
	bs.free()

func test_post_victory_destination_safe_without_campaign():
	var bs: Node = BattleSceneScript.new()
	var cs_backup = GameManager.campaign_system
	GameManager.campaign_system = null
	# Sem campanha, o fallback linear continua sendo a próxima batalha.
	assert_eq(bs._get_post_victory_destination(), "explore", "sem campaign_system → exploração (fallback linear)")
	GameManager.campaign_system = cs_backup
	bs.free()

func test_epilogue_scene_instantiates_with_canonical_text():
	var scene = load("res://scenes/epilogue.tscn").instantiate()
	add_child_autofree(scene)
	assert_eq(scene.epilogue_label.text, scene.EPILOGUE_TEXT, "texto do epílogo canônico")
	assert_true(scene.EPILOGUE_TEXT.contains("Tratado do Éter e da Carne"), "lore GDD v2 §1.5")
	assert_true(scene.EPILOGUE_TEXT.contains("Kaelen"), "revelação de Kaelen")
	assert_false(scene.credits_label.text.is_empty(), "créditos presentes")
	assert_false(scene.menu_button.text.is_empty(), "botão de retorno ao menu")

func test_scene_manager_knows_epilogue():
	assert_true(SceneManager.scenes.has("epilogue"), "cena registrada no SceneManager")
	assert_eq(SceneManager.scenes["epilogue"], "res://scenes/epilogue.tscn")
