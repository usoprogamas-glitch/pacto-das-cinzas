extends "res://addons/gut/test.gd"
## Testes GUT: LineageSystem canônico ativado no runtime pelo GameManager.
## Valida: registro dos 4 apóstolos (incl. Garm), evolução dirigida por ato
## (com gates respeitados — Thal'kor só evolui no ato 2), e round-trip
## serialize/deserialize do save/load — sem tocar IO (user://).

var gm: Node


func before_each():
	var GM = load("res://scripts/game_manager.gd")
	gm = GM.new()
	add_child_autofree(gm)


# === GameManager é dono e registra os 4 apóstolos canônicos ===

func test_game_manager_owns_and_registers_lineage():
	assert_not_null(gm.lineage_system, "game_manager deve criar um LineageSystem canônico")
	var creatures = gm.lineage_system.get_all_creatures()
	assert_eq(creatures.size(), 4, "devem ter 4 apóstolos registrados (Kroug, Lira, Thal'kor, Garm)")
	assert_has(creatures, "Kroug")
	assert_has(creatures, "Lira")
	assert_has(creatures, "Thal'kor")
	assert_has(creatures, "Garm")
	# ProgressionSystem está conectado ao LineageSystem (fonte de verdade da evolução)
	assert_not_null(gm.progression_system._lineage_system, "ProgressionSystem deve ter _lineage_system conectado")
	assert_eq(gm.progression_system._lineage_system, gm.lineage_system)


# === Evolução dirigida por ato (gates respeitados) ===

func test_advancing_act_evolves_apostle():
	var ls = gm.lineage_system
	assert_eq(ls.get_current_form("Kroug"), "Goblin da Lama", "Kroug começa na base (act 0)")
	assert_eq(ls.get_current_form("Lira"), "Muda Mágica", "Lira começa na base (act 0)")
	assert_eq(ls.get_current_form("Thal'kor"), "Corvo Bestial", "Thal'kor começa na base (act 0)")

	gm.progression_system.add_memory(25)  # cruza threshold → Avanço Ato 2 → evolui forma

	var ps = gm.progression_system
	assert_eq(ps.current_act, 2, "memória 25% → ato 2")

	# Kroug: act 1 → Hobgoblin de Ferro
	assert_eq(ls.get_current_form("Kroug"), "Hobgoblin de Ferro", "Kroug evolui p/ act 1")
	# Lira: act 1 → Dríade Sombria
	assert_eq(ls.get_current_form("Lira"), "Dríade Sombria", "Lira evolui p/ act 1")
	# Thal'kor: GATE é act 2 — evolui p/ Harpia Noturna (act 2, form_index 1)
	assert_eq(ls.get_current_form("Thal'kor"), "Harpia Noturna", "Thal'kor evolui p/ act 2 (gate respeitado)")


# === Force advance e gates altos (act 3/4) ===

func test_force_act_evolves_high_gate():
	var ls = gm.lineage_system
	# Garm: act 0→1 na primeira evolução, act 1→2 na segunda (gate act 3)
	assert_eq(ls.get_current_form("Garm"), "Lobo Caolho", "Garm começa na base (act 0)")

	# add_memory(25) → ato 2 → Kroug/Lira/Garm evoluem p/ act 1; Thal'kor p/ act 2
	gm.progression_system.add_memory(25)
	assert_eq(gm.progression_system.current_act, 2, "memória 25% → ato 2")
	assert_eq(ls.get_current_form("Kroug"), "Hobgoblin de Ferro", "Kroug ato 1")
	assert_eq(ls.get_current_form("Garm"), "Cão do Inferno Sombrio", "Garm ato 1")

	# add_memory(50) total → ato 3 → todos evoluem p/ forma act 3
	gm.progression_system.add_memory(50)  # 25 + 50 = 75 → threshold 75 → ato 3
	assert_eq(gm.progression_system.current_act, 3, "memória 75% → ato 3")
	assert_eq(ls.get_current_form("Kroug"), "Rei Ogro de Fogo", "Kroug atinge forma act 3")
	assert_eq(ls.get_current_form("Garm"), "Fenrir Menor", "Garm atinge forma act 3")
	assert_eq(gm.progression_system.current_act, 3)
	# Thal'kor já era Harpia (act 2); agora evolui p/ Serafim (act 3)
	assert_eq(ls.get_current_form("Thal'kor"), "Serafim Negro", "Thal'kor atinge forma act 3")


# === Round-trip serialize/deserialize (sem IO) ===

func test_lineage_serialize_roundtrip():
	var ls = gm.lineage_system
	# add_memory(25) → ato 2; add_memory(50) mais → 75 → ato 3; add_memory(25) → 100 → ato 4
	gm.progression_system.add_memory(25)  # ato 2
	gm.progression_system.add_memory(50)  # ato 3
	gm.progression_system.add_memory(25)  # ato 4

	var data = ls.serialize()
	assert_eq(data["Kroug"]["current_form_index"], 2, "Kroug em índice 2 (Rei Ogro) antes de salvar")
	assert_eq(data["Thal'kor"]["current_form_index"], 2, "Thal'kor em índice 2 (Serafim Negro) antes de salvar")
	assert_eq(data["Lira"]["current_form_index"], 2, "Lira em índice 2 (Rainha Ent Primordial)")

	# Nova instância + restaurar estado
	var ls2 = LineageSystem.new()
	for creature_name in LineageSystem.APOSTLE_EVOLUTIONS:
		ls2.register_creature(creature_name)
	ls2.deserialize(data)

	assert_eq(ls2.get_current_form("Kroug"), "Rei Ogro de Fogo", "forma de Kroug persistida")
	assert_eq(ls2.get_current_form("Thal'kor"), "Serafim Negro", "forma de Thal'kor persistida")
	assert_eq(ls2.get_current_form("Lira"), "Rainha Ent Primordial", "Lira também deve ter evoluído no save")
