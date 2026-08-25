extends "res://addons/gut/test.gd"

## Testes GUT para KaelenSystem (Interface Cognitiva de Kaelen, GDD v2 §3.4)


func test_analyze_target_returns_three_vectors():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"name": "Goblin", "type": "Goblin", "hp": 50, "max_hp": 50})
	assert_eq(result.has("biological"), true, "Deve ter vetor biológico")
	assert_eq(result.has("psychological"), true, "Deve ter vetor psicológico")
	assert_eq(result.has("tactical"), true, "Deve ter vetor tático")


func test_weakness_detected():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"name": "Goblin", "type": "Goblin", "hp": 50, "max_hp": 50})
	var weaknesses = result.biological.weaknesses
	assert_eq(weaknesses.size() > 0, true, "Goblin deve ter fraquezas")
	var has_fogo = false
	for w in weaknesses:
		if w.type == "Fogo":
			has_fogo = true
			assert_eq(w.bonus_percent, 40, "Goblin: Fogo +40%")
	assert_eq(has_fogo, true, "Goblin deve ser fraco a Fogo")


func test_fatigue_levels():
	var ks = KaelenSystem.new()
	var descansado = ks.analyze_target({"hp": 100, "max_hp": 100})
	assert_eq(descansado.biological.fatigue, KaelenSystem.FatigueLevel.DESCANSADO, "100% HP = Descansado")

	var critico = ks.analyze_target({"hp": 10, "max_hp": 100})
	assert_eq(critico.biological.fatigue, KaelenSystem.FatigueLevel.CRITICA, "10% HP = Crítica")


func test_armor_displayed():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"armor": 25})
	assert_eq(result.biological.armor, 25, "Armadura deve ser exibida")


func test_morale_levels():
	var ks = KaelenSystem.new()
	var alta = ks.analyze_target({"morale": 80})
	assert_eq(alta.psychological.morale, KaelenSystem.MoraleLevel.ALTA, "80 = Alta")

	var quebrada = ks.analyze_target({"morale": 10})
	assert_eq(quebrada.psychological.morale, KaelenSystem.MoraleLevel.QUEBRADA, "10 = Quebrada")


func test_flee_chance():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"morale": 10})
	assert_eq(result.psychological.flee_chance, 0.6, "Quebrada = 60% fuga")


func test_threat_level_locks():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({
		"locks": [{"type": "Corte", "remaining": 2}],
		"spell_counter": 1,
	})
	assert_eq(result.tactical.threat_level, "CRÍTICA", "Locks + counter 1 = Crítica")


func test_threat_level_no_locks():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"locks": [], "attack_range": 1})
	assert_eq(result.tactical.threat_level, "BAIXA", "Sem locks = Baixa")


func test_suggestions_generated():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({
		"locks": [{"type": "Corte", "remaining": 1}],
	})
	assert_eq(result.suggestions.size(), 1, "Deve gerar 1 sugestão")
	assert_eq(result.suggestions[0].lock_type, "Corte", "Sugestão para Corte")


func test_suggestion_text():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({
		"locks": [{"type": "Contusão", "remaining": 2}],
	})
	assert_eq(result.suggestions[0].suggestion.contains("Kroug"), true, "Contusão → Kroug")


func test_get_weaknesses():
	var ks = KaelenSystem.new()
	var weaknesses = ks.get_weaknesses("Harpias")
	assert_eq(weaknesses.size() >= 1, true, "Harpias deve ter fraquezas")


func test_get_weaknesses_unknown():
	var ks = KaelenSystem.new()
	var weaknesses = ks.get_weaknesses("Banana")
	assert_eq(weaknesses.size(), 0, "Tipo desconhecido = sem fraquezas")


func test_morale_name():
	var ks = KaelenSystem.new()
	assert_eq(ks.get_morale_name(KaelenSystem.MoraleLevel.ALTA), "Alta")
	assert_eq(ks.get_morale_name(KaelenSystem.MoraleLevel.QUEBRADA), "Quebrada")


func test_fatigue_name():
	var ks = KaelenSystem.new()
	assert_eq(ks.get_fatigue_name(KaelenSystem.FatigueLevel.DESCANSADO), "Descansado")
	assert_eq(ks.get_fatigue_name(KaelenSystem.FatigueLevel.CRITICA), "Crítica")


func test_signal_target_analyzed():
	var ks = KaelenSystem.new()
	watch_signals(ks)
	ks.analyze_target({"name": "Goblin", "type": "Goblin"})
	assert_signal_emitted(ks, "target_analyzed", "Sinal deve disparar ao analisar")


func test_signal_suggestion_when_locks():
	var ks = KaelenSystem.new()
	watch_signals(ks)
	ks.analyze_target({"locks": [{"type": "Éter", "remaining": 1}]})
	assert_signal_emitted(ks, "suggestion_generated", "Sinal deve disparar com locks")
