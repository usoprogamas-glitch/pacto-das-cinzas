extends "res://addons/gut/test.gd"
## Testes GUT: ativação do LineageSystem canônico no runtime
## Valida que a evolução dos apóstolos por ato agora flui pelo sistema canônico
## do GDD (antes órfão/instanciado-e-ignorado), incluindo Garm e os gates de ato.

var gm: Node


func before_each():
	var GM = load("res://scripts/game_manager.gd")
	gm = GM.new()
	add_child_autofree(gm)


# === GameManager é o dono persistente e registra os 4 apóstolos ===

func test_game_manager_owns_and_registers_lineage():
	assert_not_null(gm.lineage_system, "game_manager deve criar um LineageSystem")
	var ls = gm.lineage_system
	assert_eq(ls.get_all_creatures().size(), 4, "os 4 apóstolos registrados (incl. Garm)")
	assert_true(ls.get_all_creatures().has("Garm"), "Garm registrado (falta em todo lugar)")
	assert_eq(gm.progression_system._lineage_system, ls, "ProgressionSystem deve ter o LineageSystem conectado")


# === Avanço de ato dirige a evolução dos apóstolos (gates respeitados) ===

func test_advancing_act_evolves_apostle():
	var ps = gm.progression_system
	var ls = gm.lineage_system
	assert_eq(ls.get_current_form("Kroug"), "Goblin da Lama")

	ps.add_memory(25)  # ato 2

	assert_eq(ps.current_act, 2)
	assert_eq(ls.get_current_form("Kroug"), "Hobgoblin de Ferro", "Kroug evolui no ato 2 (gate act 1)")
	assert_eq(ls.get_current_form("Lira"), "Dríade Sombria", "Lira evolui no ato 2 (gate act 1)")
	assert_eq(ls.get_current_form("Thal'kor"), "Harpia Noturna", "Thal'kor evolui (gate é act 2, atingido)")
	assert_eq(ls.get_current_form("Garm"), "Cão do Inferno Sombrio", "Garm evolve no ato 2 (gate act 1)")


# === Ato mais alto alcança a forma de gate superior ===

func test_force_act_evolves_high_gate():
	var ps = gm.progression_system
	var ls = gm.lineage_system

	ps.add_memory(75)  # atravessa 25→ato2 e 75→ato3 em sequência

	assert_eq(ps.current_act, 3)
	assert_eq(ls.get_current_form("Kroug"), "Rei Ogro de Fogo", "Kroug atinge a forma do ato 3")
	assert_eq(ls.get_current_form("Thal'kor"), "Serafim Negro", "Thal'kor atinge a forma máxima no ato 3")


# === Round-trip de save/load ===

func test_lineage_serialize_roundtrip():
	var ls = gm.lineage_system
	gm.progression_system.add_memory(25)  # evolui p/ formas do ato 2

	var data = ls.serialize()

	var ls2 = LineageSystem.new()
	for name in LineageSystem.APOSTLE_EVOLUTIONS:
		ls2.register_creature(name)
	ls2.deserialize(data)

	assert_eq(ls2.get_current_form("Kroug"), "Hobgoblin de Ferro", "forma dos apóstolos persistida e restaurada")
	assert_eq(ls2.get_current_form("Thal'kor"), "Harpia Noturna", "forma do ato 2 persistida e restaurada")
