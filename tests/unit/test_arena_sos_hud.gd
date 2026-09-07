extends "res://addons/gut/test.gd"

## HUD de combate réplica Sea of Stars (referência do usuário, 2026-09-07):
## placas PV/PM com retrato (bottom-left), menu de ação contextual com nome
## âmbar (ATACAR/HABILIDADES/COMBO/ITENS/FUGIR), banner de comando + slot
## EFEITO (topo), badge COMBO diamante com os pips de CP.

const ArenaLib := preload("res://scripts/arena_battle.gd")

var arena


func before_each() -> void:
	arena = ArenaLib.new()
	arena.combat_frozen = true
	add_child_autofree(arena)


func after_each() -> void:
	arena = null


func test_banner_and_effect_slot_exist():
	assert_not_null(arena._banner_label, "banner de comando existe")
	assert_not_null(arena._banner_effect, "slot EFEITO existe")
	arena._set_command("Atacar", "CORTE")
	assert_eq(arena._banner_label.text, "Atacar", "banner reflete o comando")
	assert_eq(arena._banner_effect.text, "CORTE", "slot EFEITO reflete o tipo")


func test_menu_has_sos_items():
	var texts: Array = []
	for btn in arena.action_menu.get_children():
		texts.append(btn.text)
	assert_has(texts, "ATACAR")
	assert_has(texts, "HABILIDADES")
	assert_has(texts, "COMBO")
	assert_has(texts, "ITENS")
	assert_has(texts, "FUGIR")
	for btn in arena.action_menu.get_children():
		if btn.text == "ITENS":
			assert_true(btn.disabled, "ITENS desabilitado (sem inventário na arena)")


func test_party_plates_created_for_players():
	# _ready já montou Kael (setup de campanha); adicionamos Kroug dummy.
	var kroug = arena._make_combatant("Kroug", true, 120, 10, 15, 8, 20)
	arena.combatants.append(kroug)
	arena._ensure_party_plates()
	var plate_units: Array = arena._party_plates.map(func(p): return p["unit"])
	assert_has(plate_units, arena.combatants[0], "Kael tem placa")
	assert_has(plate_units, kroug, "Kroug ganha placa")
	for p in arena._party_plates:
		assert_eq(p["pv_bar"].max_value, p["unit"].data.max_hp, "PV barra usa max_hp")
		assert_eq(p["pm_bar"].max_value, p["unit"].data.max_mp, "PM barra usa max_mp")
	var kael_plate: Dictionary = arena._party_plates[0]
	arena.combatants[0].current_hp = 40
	arena._refresh_party_plates()
	assert_eq(kael_plate["pv_val"].text, "PV 40", "placa reflete o HP atual")


func test_ensure_party_plates_is_idempotent():
	arena.combatants = [arena._make_combatant("Kael", true, 80, 12, 5, 11, 25)]
	arena._ensure_party_plates()
	var names_before: Array = arena._party_plates.map(func(p): return p["unit"].data.unit_name)
	arena._ensure_party_plates()
	arena._ensure_party_plates()
	var names_after: Array = arena._party_plates.map(func(p): return p["unit"].data.unit_name)
	assert_eq(names_after, names_before, "placas não duplicam (mesmos units)")


func test_portrait_for_unknown_name_is_null_safe():
	assert_eq(arena._portrait_for("InimigoInexistente"), null, "sem sprite → null sem crash")
	var tex = arena._portrait_for("Kael")
	assert_ne(tex, null, "Kael tem retrato (sprite ou pintado)")


func test_combo_item_requires_two_cp():
	arena.combatants = [arena._make_combatant("Kael", true, 80, 12, 5, 11, 25)]
	arena.current_actor = arena.combatants[0]
	arena._show_action_menu(true)
	assert_true(arena.menu_root.visible, "menu_root abre junto do action_menu")
	assert_eq(arena._menu_name_label.text, "KAEL", "nome do ator em uppercase âmbar")
	arena.combo_system.reset()
	arena._on_combo_pressed()
	assert_eq(arena.combo_system.get_cp(), 0, "sem CP, combo não gasta")
	arena.combo_system.add_cp(2)
	arena._on_combo_pressed()
	assert_eq(arena.combo_system.get_cp(), 0, "combo consome os 2 CP")
	assert_eq(arena._combo_boost, 1.5, "boost de dano armado para o timed hit")
	assert_false(arena.menu_root.visible, "menu fecha ao escolher COMBO")


func test_combo_boost_applies_and_resets():
	arena._combo_boost = 1.5
	# Simula o caminho do dano físico (sem animador: _animator_for → null).
	arena.combatants = [
		arena._make_combatant("Kael", true, 80, 12, 5, 11, 25),
		arena._make_combatant("Alvo", false, 100, 8, 0, 5, 10),
	]
	arena.current_actor = arena.combatants[0]
	arena._pending_target = arena.combatants[1]
	var before: int = arena.combatants[1].current_hp
	arena._resolve_action(1.0, "GOOD")
	assert_lt(arena.combatants[1].current_hp, before, "dano aplicado")
	assert_eq(arena._combo_boost, 1.0, "boost reseta após o golpe")
