extends "res://addons/gut/test.gd"

## Testes GUT para LineageSystem (Árvore de Linhagens, GDD v2 §3.4)


func test_register_creature():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	assert_eq(ls.get_current_form("Kroug"), "Goblin da Lama", "Forma inicial = Goblin da Lama")


func test_get_evolution_path():
	var ls = LineageSystem.new()
	var path = ls.get_evolution_path("Kroug")
	assert_eq(path.size(), 3, "Kroug tem 3 formas")
	assert_eq(path[0].form, "Goblin da Lama", "Forma 0 = Goblin da Lama")
	assert_eq(path[1].form, "Hobgoblin de Ferro", "Forma 1 = Hobgoblin de Ferro")
	assert_eq(path[2].form, "Rei Ogro de Fogo", "Forma 2 = Rei Ogro de Fogo")


func test_evolve_creature():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	var evolved = ls.evolve_creature("Kroug", 1)
	assert_eq(evolved, true, "Deve evoluir no Ato 1")
	assert_eq(ls.get_current_form("Kroug"), "Hobgoblin de Ferro", "Forma = Hobgoblin de Ferro")


func test_evolve_wrong_act():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	var evolved = ls.evolve_creature("Kroug", 0)
	assert_eq(evolved, false, "Não deve evoluir no Ato 0")


func test_evolve_chain():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	ls.evolve_creature("Kroug", 1)  # → Hobgoblin de Ferro
	ls.evolve_creature("Kroug", 3)  # → Rei Ogro de Fogo
	assert_eq(ls.get_current_form("Kroug"), "Rei Ogro de Fogo", "Forma final = Rei Ogro de Fogo")


func test_evolve_max_form():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	ls.evolve_creature("Kroug", 1)
	ls.evolve_creature("Kroug", 3)
	var evolved = ls.evolve_creature("Kroug", 3)
	assert_eq(evolved, false, "Não deve evoluir além da forma máxima")


func test_lira_evolution():
	var ls = LineageSystem.new()
	ls.register_creature("Lira")
	ls.evolve_creature("Lira", 1)
	assert_eq(ls.get_current_form("Lira"), "Dríade Sombria", "Lira Ato 1 = Dríade Sombria")
	ls.evolve_creature("Lira", 3)
	assert_eq(ls.get_current_form("Lira"), "Rainha Ent Primordial", "Lira Ato 3 = Rainha Ent Primordial")


func test_thalkor_evolution():
	var ls = LineageSystem.new()
	ls.register_creature("Thal'kor")
	ls.evolve_creature("Thal'kor", 2)
	assert_eq(ls.get_current_form("Thal'kor"), "Harpia Noturna", "Thal'kor Ato 2 = Harpia Noturna")


func test_choose_branch():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	var chosen = ls.choose_branch("Kroug", "Xamãs do Éter")
	assert_eq(chosen, true, "Deve aceitar ramificação")


func test_get_branch():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	ls.choose_branch("Kroug", "Vanguarda de Ferro")
	assert_eq(ls.get_branch("Kroug"), "Vanguarda de Ferro", "Ramificação = Vanguarda de Ferro")


func test_get_available_branches():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	var branches = ls.get_available_branches("Kroug")
	assert_eq(branches.size(), 2, "Goblin da Lama tem 2 ramificações")


func test_stat_modifiers_base():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	var mods = ls.get_stat_modifiers("Kroug")
	assert_eq(mods.hp, 0, "Base = 0 HP modifier")
	assert_eq(mods.def, 0, "Base = 0 DEF modifier")


func test_stat_modifiers_after_evolution():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	ls.evolve_creature("Kroug", 1)
	var mods = ls.get_stat_modifiers("Kroug")
	assert_eq(mods.hp, 50, "Hobgoblin = +50 HP")
	assert_eq(mods.def, 25, "Hobgoblin = +25 DEF")


func test_stat_modifiers_with_branch():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	ls.choose_branch("Kroug", "Vanguarda de Ferro")
	var mods = ls.get_stat_modifiers("Kroug")
	assert_eq(mods.hp, 80, "Vanguarda = +80 HP")
	assert_eq(mods.def, 35, "Vanguarda = +35 DEF")


func test_can_evolve():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	assert_eq(ls.can_evolve("Kroug", 1), true, "Pode evoluir no Ato 1")
	assert_eq(ls.can_evolve("Kroug", 0), false, "Não pode evoluir no Ato 0")


func test_is_max_form():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	assert_eq(ls.is_max_form("Kroug"), false, "Base não é máxima")
	ls.evolve_creature("Kroug", 1)
	ls.evolve_creature("Kroug", 3)
	assert_eq(ls.is_max_form("Kroug"), true, "Rei Ogro é forma máxima")


func test_get_creature_state():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	var state = ls.get_creature_state("Kroug")
	assert_eq(state.current_form_index, 0, "Índice inicial = 0")
	assert_eq(state.branch, null, "Sem ramificação")


func test_get_all_creatures():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	ls.register_creature("Lira")
	var all = ls.get_all_creatures()
	assert_eq(all.size(), 2, "2 criaturas registradas")


func test_signal_evolved_fires():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	watch_signals(ls)
	ls.evolve_creature("Kroug", 1)
	assert_signal_emitted(ls, "creature_evolved", "Sinal deve disparar ao evoluir")


func test_signal_branch_fires():
	var ls = LineageSystem.new()
	ls.register_creature("Kroug")
	watch_signals(ls)
	ls.choose_branch("Kroug", "Xamãs do Éter")
	assert_signal_emitted(ls, "branch_chosen", "Sinal deve disparar ao escolher ramo")
