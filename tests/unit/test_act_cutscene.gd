extends "res://addons/gut/test.gd"
## Testes GUT: cutscene de abertura de ato (ROADMAP #2)
## Valida o ciclo act_intro_pending no CampaignSystem, o roteamento pós-vitória
## do battle_scene e o conteúdo data-driven da cena. Não chama _finish() da cena
## (trocaria de cena em teste headless) — o efeito observable do _finish é o
## mark_act_intro_seen(), testado direto na campanha.

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")
const ActCutsceneScript := preload("res://scripts/ui/act_cutscene.gd")

func _make_campaign() -> CampaignSystem:
	return CampaignSystem.new()

func after_each() -> void:
	# Autoloads são compartilhados entre todos os arquivos de teste — nunca vazar
	# estado de campanha mutado aqui.
	GameManager.campaign_system.reset()

# === Ciclo do flag na campanha ===

func test_complete_act_marks_pending_intro():
	var cs = _make_campaign()
	assert_false(cs.has_pending_act_intro(), "ato 1 começa sem cutscene pendente")
	cs.complete_act()
	assert_true(cs.has_pending_act_intro(), "chefe do ato 1 morto → cutscene do ato 2 pendente")
	assert_eq(cs.current_act, 2)

func test_each_act_transition_sets_pending():
	var cs = _make_campaign()
	for expected_act in [2, 3, 4]:
		cs.mark_act_intro_seen()
		cs.complete_act()
		assert_true(cs.has_pending_act_intro(), "ato %d aberto → cutscene pendente" % expected_act)
		assert_eq(cs.current_act, expected_act)

func test_final_act_does_not_set_pending():
	# Jogo completo vai para o epílogo — não pode pedir cutscene de "ato 5".
	var cs = _make_campaign()
	for i in range(3):
		cs.complete_act()
		cs.mark_act_intro_seen()
	cs.complete_act()
	assert_true(cs.is_game_complete())
	assert_false(cs.has_pending_act_intro(), "fim de jogo ≠ cutscene de ato")

func test_mark_seen_clears_pending():
	var cs = _make_campaign()
	cs.complete_act()
	cs.mark_act_intro_seen()
	assert_false(cs.has_pending_act_intro())

func test_reset_clears_pending():
	var cs = _make_campaign()
	cs.complete_act()
	cs.reset()
	assert_false(cs.has_pending_act_intro())

func test_pending_survives_save_roundtrip():
	# Player vence chefe de ato e fecha o jogo antes de ver a cutscene: ao
	# carregar o save, a cutscene continua pendente.
	var cs = _make_campaign()
	cs.complete_act()
	var cs2 = _make_campaign()
	cs2.deserialize(cs.serialize())
	assert_true(cs2.has_pending_act_intro())
	assert_eq(cs2.current_act, 2)

func test_deserialize_without_key_defaults_to_false():
	# Saves antigos (antes da feature) não têm a chave — não podem iniciar pendente.
	var cs = _make_campaign()
	cs.deserialize({"current_act": 2, "current_stage": 0})
	assert_false(cs.has_pending_act_intro())

# === Roteamento pós-vitória no battle_scene ===

func test_post_victory_routes_pending_to_cutscene():
	var bs: Node = BattleSceneScript.new()
	GameManager.campaign_system.reset()
	GameManager.campaign_system.complete_act()
	assert_eq(bs._get_post_victory_destination(), "act_cutscene", "abertura de ato pendente → cutscene")
	GameManager.campaign_system.reset()
	bs.free()

func test_post_victory_priority_epilogue_over_cutscene():
	var bs: Node = BattleSceneScript.new()
	GameManager.campaign_system.reset()
	GameManager.campaign_system.complete_act()          # pending = true
	GameManager.campaign_system.game_completed = true   # fim de jogo (defensivo)
	assert_eq(bs._get_post_victory_destination(), "epilogue", "epílogo tem prioridade sobre cutscene")
	GameManager.campaign_system.reset()
	bs.free()

func test_post_victory_routes_to_next_battle_when_nothing_pending():
	var bs: Node = BattleSceneScript.new()
	GameManager.campaign_system.reset()
	# Fluxo linear de enredo: sem cutscene pendente → próxima batalha da campanha.
	assert_eq(bs._get_post_victory_destination(), "explore", "ato em curso, cutscene já vista → exploração")
	bs.free()

# === Conteúdo data-driven da cena ===

func test_cutscene_has_pages_for_acts_2_3_4():
	var scene = ActCutsceneScript.new()
	assert_false(scene.ACT_PAGES.get(2, []).is_empty(), "Ato II tem páginas")
	assert_false(scene.ACT_PAGES.get(3, []).is_empty(), "Ato III tem páginas")
	assert_false(scene.ACT_PAGES.get(4, []).is_empty(), "Ato IV tem páginas")
	scene.free()

func test_cutscene_has_no_page_for_act_1():
	# A abertura do Ato I é a intro_story — cutscene não pode duplicar.
	var scene = ActCutsceneScript.new()
	assert_true(scene.ACT_PAGES.get(1, []).is_empty(), "Ato I não tem cutscene")
	scene.free()

func test_cutscene_instantiates_and_shows_act2_page():
	var scene = ActCutsceneScript.new()
	GameManager.campaign_system.reset()
	GameManager.campaign_system.complete_act()  # ato 2
	add_child_autofree(scene)
	# _ready roda: páginas do ato 2 exibidas, sem crash
	assert_eq(scene.act_label.text, scene.ACT_TITLES[2])
	assert_eq(scene.text_label.text, scene.ACT_PAGES[2][0])
	assert_eq(scene.page_counter.text, "1/3")

func test_cutscene_unknown_act_has_no_pages():
	# Ato sem conteúdo (ex.: 99): _pages_for_current_act() vazio → no runtime
	# _show_current_page() cai no _finish() e segue para o map_select sem
	# bloquear o fluxo. Não instanciamos a cena aqui: _finish trocaria de
	# cena em teste headless.
	var scene = ActCutsceneScript.new()
	GameManager.campaign_system.reset()
	GameManager.campaign_system.current_act = 99
	assert_true(scene._pages_for_current_act().is_empty(), "ato desconhecido → sem páginas → segue o fluxo")
	scene.free()

func test_scene_manager_knows_act_cutscene():
	assert_true(SceneManager.scenes.has("act_cutscene"), "cena registrada no SceneManager")
	assert_eq(SceneManager.scenes["act_cutscene"], "res://scenes/ui/act_cutscene.tscn")
