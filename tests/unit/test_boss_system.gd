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


func test_spawn_runtime_boss():
	var bs = BossSystem.new()
	# HP real da Unit do mapa (300 no santo_cardeal) sobreescreve o do cardinal (500)
	bs.spawn_runtime_boss("Ignis", 300)
	assert_eq(bs.get_boss_hp(), 300, "HP vem da Unit, não do cardinal")
	assert_true(bs.is_boss_active(), "boss ativo pós-runtime")
	watch_signals(bs)
	bs.spawn_runtime_boss("Ignis", 300)
	assert_signal_emitted_with_parameters(bs, "boss_hp_changed", ["Ignis", 300, 500],
		"max do cardinal mantido = 500")


func test_sync_runtime_hp_defeats():
	var bs = BossSystem.new()
	bs.spawn_runtime_boss("Ignis", 300)
	watch_signals(bs)
	bs.sync_runtime_hp(0)  # Unit morreu em campo
	assert_signal_emitted(bs, "boss_defeated", "sincronizar HP 0 derrota o boss")


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


# --- ROADMAP #8: Conteúdo de chefes de verdade (5 Cardeais + Aurius) ---

func test_cardinal_enemy_database_entries_exist():
	# Verifica que os 5 Cardeais existem no EnemyDatabase com classe Boss
	var cardinals = ["cardeal_ignis", "cardeal_zephyr", "cardeal_aqua", "cardeal_terra", "cardeal_umbra"]
	for c in cardinals:
		var data = EnemyDatabase.get_enemy(c)
		assert_false(data.is_empty(), "EnemyDatabase deve ter %s" % c)
		assert_eq(data["class"], "Boss", "%s deve ser da classe Boss" % c)
		assert_eq(data["ai_type"], "boss", "%s deve ter ai_type boss" % c)

func test_aurius_phases_enemy_database_entries_exist():
	# Verifica que as 3 fases de Aurius existem no EnemyDatabase
	var phases = ["aurius_fase1", "aurius_fase2", "aurius_fase3"]
	for p in phases:
		var data = EnemyDatabase.get_enemy(p)
		assert_false(data.is_empty(), "EnemyDatabase deve ter %s" % p)
		assert_eq(data["class"], "Boss", "%s deve ser da classe Boss" % p)

func test_boss_maps_exist_in_map_database():
	# Verifica que os mapas de boss (5-12) existem no MapDatabase
	for map_id in range(5, 13):
		var map_data = MapDatabase.get_map(map_id)
		assert_false(map_data.is_empty(), "MapDatabase deve ter map_id %d" % map_id)
		assert_eq(map_data["enemy_count"], 1, "mapa de boss deve ter 1 inimigo")
