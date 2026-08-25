extends "res://addons/gut/test.gd"

## Testes GUT para CampfireSystem (Acampamento, GDD v2 §7.1)


func test_register_apostle():
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	assert_eq(cs.get_bond_level("Kroug"), 1, "Nível inicial = 1")


func test_bond_points_gained():
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	cs.rest_at_campfire("camp1", [])
	var bond = cs.get_bond("Kroug")
	assert_eq(bond.points, 5, "5 pontos de vínculo ganhos")


func test_bond_level_up():
	var cs = CampfireSystem.new()
	cs.register_apostle("Lira")
	## 20 pontos para nível 2, descansar 4 vezes = 20 pontos
	for i in range(4):
		cs.rest_at_campfire("camp1", [])
	assert_eq(cs.get_bond_level("Lira"), 2, "Nível 2 após 20 pontos")


func test_bond_max_level():
	var cs = CampfireSystem.new()
	cs.register_apostle("Thal'kor")
	for i in range(100):
		cs.rest_at_campfire("camp1", [])
	var level = cs.get_bond_level("Thal'kor")
	assert_eq(level, 10, "Nível máximo = 10")


func test_get_available_dialogues():
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	var dialogues = cs.get_available_dialogues("Kroug")
	assert_eq(dialogues.size(), 2, "2 diálogos no nível 1")


func test_dialogue_not_repeated():
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	cs.start_dialogue("Kroug", "kroug_1_1")
	var dialogues = cs.get_available_dialogues("Kroug")
	assert_eq(dialogues.size(), 1, "1 diálogo restante após usar 1")


func test_dialogue_signal():
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	watch_signals(cs)
	cs.start_dialogue("Kroug", "kroug_1_1")
	assert_signal_emitted(cs, "dialogue_started", "Sinal deve disparar")


func test_rest_completed_signal():
	var cs = CampfireSystem.new()
	watch_signals(cs)
	cs.rest_at_campfire("camp1", [])
	assert_signal_emitted(cs, "rest_completed", "Sinal deve disparar")


func test_bond_level_changed_signal():
	var cs = CampfireSystem.new()
	cs.register_apostle("Lira")
	watch_signals(cs)
	for i in range(4):
		cs.rest_at_campfire("camp1", [])
	assert_signal_emitted(cs, "bond_level_changed", "Sinal deve disparar")


func test_rests_count():
	var cs = CampfireSystem.new()
	cs.rest_at_campfire("camp1", [])
	cs.rest_at_campfire("camp2", [])
	assert_eq(cs.get_rests_count(), 2, "2 descansos")


func test_no_dialogues_for_unknown_apostle():
	var cs = CampfireSystem.new()
	var dialogues = cs.get_available_dialogues("Unknown")
	assert_eq(dialogues.size(), 0, "Sem diálogos para apóstolo desconhecido")


func test_invalid_dialogue():
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	var result = cs.start_dialogue("Kroug", "invalid_id")
	assert_eq(result, {}, "Diálogo inválido retorna vazio")


func test_get_all_bonds():
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	cs.register_apostle("Lira")
	var bonds = cs.get_all_bonds()
	assert_eq(bonds.size(), 2, "2 apóstolos registrados")


func test_get_config():
	var cs = CampfireSystem.new()
	var config = cs.get_config()
	assert_eq(config.hp_regen_percent, 50, "HP regen = 50%")
