extends "res://addons/gut/test.gd"

## Testes GUT: NarrativeSystem sincronizado com canon GDD v2 "O Deus Despedaçado"
## Valida fases do protagonista, evolução por fragmentos, dados dos Apóstolos.

var narrative: NarrativeSystem


func before_each():
	narrative = NarrativeSystem.new()
	add_child_autofree(narrative)


func test_form_names_match_gdd_v2():
	assert_eq(narrative.get_form_name(NarrativeSystem.ProtagonistForm.QUERUBIM_FRATURADO), "Querubim Fraturado")
	assert_eq(narrative.get_form_name(NarrativeSystem.ProtagonistForm.SERAFIM_DAS_CINZAS), "Serafim das Cinzas")
	assert_eq(narrative.get_form_name(NarrativeSystem.ProtagonistForm.TRONO_COSMICO), "Trono Cósmico / Arquidemônio")
	assert_eq(narrative.get_form_name(NarrativeSystem.ProtagonistForm.AVATAR_PRIMORDIAL), "Avatar Primordial")


func test_initial_form_is_querubim_fraturado():
	assert_eq(narrative.current_form, NarrativeSystem.ProtagonistForm.QUERUBIM_FRATURADO,
		"Jogo começa com Querubim Fraturado (0% memória)")


func test_evolution_thresholds_v2():
	# 3 fragmentos -> Serafim das Cinzas (25% memória)
	for i in range(3):
		narrative.collect_fragment()
	assert_eq(narrative.current_form, NarrativeSystem.ProtagonistForm.SERAFIM_DAS_CINZAS)

	# 7 fragmentos -> Trono Cósmico/Arquidemônio (75% memória)
	for i in range(4):
		narrative.collect_fragment()
	assert_eq(narrative.current_form, NarrativeSystem.ProtagonistForm.TRONO_COSMICO)

	# 12 fragmentos -> Avatar Primordial (100% memória)
	for i in range(5):
		narrative.collect_fragment()
	assert_eq(narrative.current_form, NarrativeSystem.ProtagonistForm.AVATAR_PRIMORDIAL)


func test_evolution_signal_emitted_with_v2_name():
	watch_signals(narrative)
	narrative.collect_fragment()
	narrative.collect_fragment()
	narrative.collect_fragment()
	assert_signal_emitted(narrative, "protagonist_evolved")
	assert_signal_emitted_with_parameters(narrative, "protagonist_evolved", ["Serafim das Cinzas"])


func test_four_apostles_present_in_canon():
	var expected := ["kroug", "lira", "thalkor", "garm"]
	for id in expected:
		var info = narrative.get_character_info(id)
		assert_false(info.is_empty(), "Apóstolo '%s' deve existir no canon" % id)
	# Garm é o 4º apóstolo adicionado no v2
	var garm = narrative.get_character_info("garm")
	assert_true(garm.has("evolution"), "Garm deve ter linha evolutiva definida")


func test_act_names_match_master_doc():
	assert_eq(narrative.get_act_info(1).get("name", ""), "A Fronteira Cinzenta")
	assert_eq(narrative.get_act_info(4).get("name", ""), "A Queda de Solaria")


func test_start_act_recovers_memories_and_fires_events():
	watch_signals(narrative)
	narrative.start_act(1)
	assert_eq(narrative.current_act, 1)
	assert_signal_emitted(narrative, "act_started")
	assert_true(narrative.memories_recovered.has("mem_silhueta_antiga"),
		"Ato 1 recupera memórias do prólogo")


func test_kaelen_secret_is_v2_truth():
	# Canon v2: Kaelen é a personificação do trauma/fúria da traição, não voz benevolente
	var kaelen = narrative.get_character_info("kaelen")
	assert_true(kaelen.get("secret", "").contains("fúria"),
		"Segredo de Kaelen deve refletir a revelação do Ato IV (v2)")
