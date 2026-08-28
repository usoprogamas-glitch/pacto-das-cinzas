extends "res://addons/gut/test.gd"
## Testes GUT: fluxo da intro (first time no jogo)
## Valida o handler _on_intro_completed do GameManager — fonte de verdade única das
## consequências das escolhas. Antes: a intro visível emitia o sinal para zero
## listeners (INTRO duplicada no _ready + .tscn sem conexão) → tela preta;
## e o handler chamava .consequence em chaves auxiliares (crash) + a mana era
## mexida na intro E aqui (dupla aplicação).

func make_gm() -> Node:
	var gm = load("res://scripts/game_manager.gd").new()
	add_child_autofree(gm)
	return gm


# === Handler tolera as chaves auxiliares reais do emit ===

func test_handler_ignores_auxiliary_keys_without_crashing():
	var gm = make_gm()
	var game_data_original = gm.game_data.duplicate(true)

	# Deve sobreviver a chaves não-Dictionary ("inferno": primeiro dict da intro)
	gm._on_intro_completed({
		"inferno": {"consequence": "NULL"},
		"real_key": {"consequence": "none"}
	})

	assert_eq(gm.game_data.mana, game_data_original.mana, "handler não deve crashar nem mexer em mana")
	assert_false(gm.game_data.first_pact, "choice inválida não deve marcar pacto")
	assert_eq(gm.game_data.starting_ally, game_data_original.starting_ally)


# === Mono-aplicação: o estado é aplicado APENAS no handler ===

func test_first_pact_applies_once():
	var gm = make_gm()
	gm.game_data.mana = 120  # estado determinístico

	var choices = {
		"question": {
			"consequence": "first_pact"
		}
	}
	gm._on_intro_completed(choices)

	assert_eq(gm.game_data.mana, 105, "±15 uma única vez (foi -15 na intro E -15 aqui)")
	assert_true(gm.game_data.first_pact)
	assert_eq(gm.game_data.starting_ally, "kroug")


func test_lone_survivor_sets_hard_difficulty():
	var gm = make_gm()

	var choices = {"q": {"consequence": "lone_survivor"}}
	gm._on_intro_completed(choices)

	assert_eq(gm.game_data.starting_ally, "none")
	assert_eq(gm.game_data.kaelen_approval, -10)
	assert_eq(gm.game_data.difficulty, "hard")


func test_knowledge_bonus_context_does_not_double_apply():
	var gm = make_gm()

	var choices = {"q": {"consequence": "cautious_start"}}
	gm._on_intro_completed(choices)

	assert_eq(gm.game_data.knowledge_bonus, true)
	assert_eq(gm.game_data.difficulty, "normal")


# === start_new_game registra o aliado da escolha (remoção da intro duplicada) ===

func test_first_pact_new_game_registers_kroug():
	var gm = make_gm()
	gm.start_new_game()

	# Sem escolha: nenhum pacto → Kroug não é apóstolo ainda
	assert_false(gm.faith_system.faith_data.has("Kroug"))

	# Handler roda start_new_game() com first_pact → Kroug deve existir
	gm._on_intro_completed({"q": {"consequence": "first_pact"}})

	assert_true(gm.faith_system.faith_data.has("Kroug"), "start_new_game registra Kroug após first_pact")
	assert_true(gm.game_data.first_pact)

	# Lira/Thal'kor sempre registrados
	assert_true(gm.faith_system.faith_data.has("Lira"))
	assert_true(gm.faith_system.faith_data.has("Thal'kor"))