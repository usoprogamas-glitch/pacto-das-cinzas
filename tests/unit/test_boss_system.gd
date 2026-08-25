extends "res://addons/gut/test.gd"

## Testes GUT para BossSystem (Chefes, GDD v2 §5)


func test_init_cardinal():
	var bs = BossSystem.new()
	bs.init_cardinal("Ignis")
	assert_eq(bs.get_current_boss_name(), "Ignis", "Boss = Ignis")
	assert_eq(bs.get_boss_hp(), 500, "HP = 500")


func test_get_cardinal_data():
	var bs = BossSystem.new()
	var data = bs.get_cardinal_data("Ignis")
	assert_eq(data.title, "Santo Cardeal do Fogo", "Título = Santo Cardeal do Fogo")
	assert_eq(data.element, "Fogo", "Elemento = Fogo")


func test_cardinal_has_parts():
	var bs = BossSystem.new()
	bs.init_cardinal("Zephyr")
	var parts = bs.get_current_parts()
	assert_eq(parts.size(), 2, "Zephyr tem 2 partes")


func test_damage_part():
	var bs = BossSystem.new()
	bs.init_cardinal("Ignis")
	var broken = bs.damage_part("Coroa Solar", 100)
	assert_eq(broken, false, "Não quebrou com 100 dano")
	assert_eq(bs.get_part_hp("Coroa Solar"), 50, "HP restante = 50")


func test_part_break():
	var bs = BossSystem.new()
	bs.init_cardinal("Ignis")
	watch_signals(bs)
	var broken = bs.damage_part("Coroa Solar", 150)
	assert_eq(broken, true, "Parte quebrada")
	assert_signal_emitted(bs, "boss_part_broken", "Sinal deve disparar")


func test_damage_boss():
	var bs = BossSystem.new()
	bs.init_cardinal("Aqua")
	bs.damage_boss(100)
	assert_eq(bs.get_boss_hp(), 380, "HP = 480 - 100 = 380")


func test_boss_defeated():
	var bs = BossSystem.new()
	bs.init_cardinal("Umbra")
	watch_signals(bs)
	bs.damage_boss(420)
	assert_signal_emitted(bs, "boss_defeated", "Boss derrotado")


func test_spell_counters_tick():
	var bs = BossSystem.new()
	bs.init_cardinal("Terra")
	var casted = bs.tick_spell_counters()
	assert_eq(casted.size(), 0, "Nenhuma magia liberada ainda")


func test_spell_counters_reach_zero():
	var bs = BossSystem.new()
	bs.init_cardinal("Terra")
	## Esmagar tem charge_turns=2, Terremoto tem charge_turns=4
	var casted1 = bs.tick_spell_counters()  ## counter: Esmagar=1, Terremoto=3
	var casted2 = bs.tick_spell_counters()  ## counter: Esmagar=0, Terremoto=2
	assert_eq(casted2.has("Esmagar"), true, "Esmagar deve ser lançada após 2 ticks")


func test_init_aurius():
	var bs = BossSystem.new()
	bs.init_aurius()
	assert_eq(bs.get_current_boss_name(), "Aurius", "Boss = Aurius")
	assert_eq(bs.get_current_phase(), 1, "Fase = 1")


func test_aurius_has_phases():
	var bs = BossSystem.new()
	bs.init_aurius()
	var phase_data = bs.get_aurius_phase_data()
	assert_eq(phase_data.name, "O Falso Demiurgo", "Fase 1 = O Falso Demiurgo")
	assert_eq(phase_data.hp, 800, "HP Fase 1 = 800")


func test_aurius_phase_transition():
	var bs = BossSystem.new()
	bs.init_aurius()
	watch_signals(bs)
	bs.damage_boss(800)  ## Destrói fase 1
	assert_eq(bs.get_current_phase(), 2, "Deve avançar para fase 2")
	assert_signal_emitted(bs, "boss_phase_changed", "Sinal de fase deve disparar")


func test_aurius_final_phase_defeat():
	var bs = BossSystem.new()
	bs.init_aurius()
	bs.damage_boss(800)  ## Fase 1 → 2
	bs.damage_boss(600)  ## Fase 2 → 3
	watch_signals(bs)
	bs.damage_boss(500)  ## Fase 3 → derrota
	assert_signal_emitted(bs, "boss_defeated", "Aurius derrotado na fase 3")


func test_get_all_cardinals():
	var bs = BossSystem.new()
	var all = bs.get_all_cardinals()
	assert_eq(all.size(), 5, "5 cardinais")


func test_is_boss_active():
	var bs = BossSystem.new()
	bs.init_cardinal("Ignis")
	assert_eq(bs.is_boss_active(), true, "Boss ativo")
	bs.damage_boss(500)
	assert_eq(bs.is_boss_active(), false, "Boss inativo")


func test_signal_spell_charging():
	var bs = BossSystem.new()
	bs.init_cardinal("Ignis")
	watch_signals(bs)
	## Ignis: Erupção Vulcânica=3, Lava Branca=4
	bs.tick_spell_counters()  ## Erupção=2, Lava=3
	bs.tick_spell_counters()  ## Erupção=1, Lava=2
	bs.tick_spell_counters()  ## Erupção=0 → emite sinal
	assert_signal_emitted(bs, "boss_spell_charging", "Sinal deve disparar quando magia é lançada")
