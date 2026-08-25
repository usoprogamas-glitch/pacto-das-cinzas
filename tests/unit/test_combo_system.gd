extends "res://addons/gut/test.gd"

## Testes GUT para ComboSystem (Pontos de Combo, GDD v2 §3.3)


func test_initial_cp_is_zero():
	var cs = ComboSystem.new()
	assert_eq(cs.get_cp(), 0, "CP inicial deve ser 0")


func test_add_cp():
	var cs = ComboSystem.new()
	cs.add_cp(2)
	assert_eq(cs.get_cp(), 2, "Adicionar 2 CP")


func test_add_cp_clamps_max():
	var cs = ComboSystem.new()
	cs.add_cp(5)
	assert_eq(cs.get_cp(), 3, "CP deve ser limitado a 3")


func test_earn_from_timed_hit_perfect():
	var cs = ComboSystem.new()
	cs.earn_from_timed_hit("PERFECT")
	assert_eq(cs.get_cp(), 1, "PERFECT = +1 CP")


func test_earn_from_timed_hit_great():
	var cs = ComboSystem.new()
	cs.earn_from_timed_hit("GREAT")
	assert_eq(cs.get_cp(), 0, "GREAT = +0 CP")


func test_earn_from_timed_hit_miss():
	var cs = ComboSystem.new()
	cs.earn_from_timed_hit("MISS")
	assert_eq(cs.get_cp(), 0, "MISS = +0 CP")


func test_earn_from_lock_break():
	var cs = ComboSystem.new()
	cs.earn_from_lock_break()
	assert_eq(cs.get_cp(), 2, "Lock Break = +2 CP")


func test_spend_cp_success():
	var cs = ComboSystem.new()
	cs.add_cp(3)
	var ok = cs.spend_cp(1, "Erupção de Éter")
	assert_eq(ok, true, "Deve gastar CP com sucesso")
	assert_eq(cs.get_cp(), 2, "CP deve ser 2")


func test_spend_cp_insufficient():
	var cs = ComboSystem.new()
	cs.add_cp(1)
	var ok = cs.spend_cp(3, "Tempestade das Cinzas")
	assert_eq(ok, false, "Não deve gastar CP insuficiente")
	assert_eq(cs.get_cp(), 1, "CP deve permanecer 1")


func test_can_use_combo_true():
	var cs = ComboSystem.new()
	cs.add_cp(1)
	var combo = {"name": "Erupção de Éter", "cost": 1, "participants": ["Querubim", "Kroug"]}
	assert_eq(cs.can_use_combo(combo, ["Querubim", "Kroug"]), true, "Deve poder usar combo")


func test_can_use_combo_missing_participant():
	var cs = ComboSystem.new()
	cs.add_cp(1)
	var combo = {"name": "Erupção de Éter", "cost": 1, "participants": ["Querubim", "Kroug"]}
	assert_eq(cs.can_use_combo(combo, ["Querubim"]), false, "Faltando Kroug")


func test_can_use_combo_insufficient_cp():
	var cs = ComboSystem.new()
	var combo = {"name": "Tempestade das Cinzas", "cost": 3, "participants": ["Querubim", "Lira", "Thal'kor"]}
	assert_eq(cs.can_use_combo(combo, ["Querubim", "Lira", "Thal'kor"]), false, "CP insuficiente")


func test_get_available_combos():
	var cs = ComboSystem.new()
	cs.add_cp(3)
	var available = cs.get_available_combos(["Querubim", "Kroug", "Lira", "Thal'kor"])
	assert_eq(available.size(), 2, "Deve retornar 2 combos disponíveis")


func test_reset():
	var cs = ComboSystem.new()
	cs.add_cp(3)
	cs.reset()
	assert_eq(cs.get_cp(), 0, "Reset deve zerar CP")


func test_signal_cp_changed_fires():
	var cs = ComboSystem.new()
	watch_signals(cs)
	cs.add_cp(1)
	assert_signal_emitted(cs, "cp_changed", "Sinal deve disparar ao mudar CP")


func test_signal_cp_spent_fires():
	var cs = ComboSystem.new()
	cs.add_cp(2)
	watch_signals(cs)
	cs.spend_cp(1, "Erupção de Éter")
	assert_signal_emitted(cs, "cp_spent", "Sinal deve disparar ao gastar CP")
