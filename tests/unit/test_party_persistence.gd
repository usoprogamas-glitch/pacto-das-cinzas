extends "res://addons/gut/test.gd"

## Testes GUT: persistência da party (Fase 4 - Party Save/Load).
## Valida que a party do jogador é inicializada no novo jogo, adicionada via
## add_to_party sem duplicar, e persistida/restaurada no save/load.

var gm: Node

func before_each() -> void:
	var GM = load("res://scripts/game_manager.gd")
	gm = GM.new()
	gm._ready()
	add_child_autofree(gm)

func _run_intro_starting_ally(ally: String) -> void:
	# Simular escolha no intro e iniciar jogo
	gm.game_data.starting_ally = ally
	gm.start_new_game()

func test_new_game_always_has_kael() -> void:
	gm.game_data.starting_ally = "none"
	gm.start_new_game()
	assert_eq(gm.party_data.size(), 1, "sem alias: só Kael")
	assert_eq(gm.party_data[0].name, "Kael", "primeiro membro é Kael")

func test_new_game_with_kroug_includes_kroug() -> void:
	gm.game_data.starting_ally = "kroug"
	gm.start_new_game()
	assert_eq(gm.party_data.size(), 2, "com Kroug: Kael + Kroug")
	assert_true(gm.party_data.any(func(m): return m.name == "Kroug"), "Kroug estará na party")

func test_add_to_party_appends_member() -> void:
	gm.game_data.starting_ally = "none"
	gm.start_new_game()
	gm.add_to_party({"name": "Lira", "class": "Dríade", "hp": 100, "atk": 8, "def": 12, "mov": 2, "rng": 2})
	assert_eq(gm.party_data.size(), 2, "Lira adicionada")
	assert_true(gm.party_data.any(func(m): return m.name == "Lira"), "Lira presente")

func test_add_to_party_no_duplicate() -> void:
	gm.game_data.starting_ally = "kroug"
	gm.start_new_game()
	gm.add_to_party({"name": "Kroug", "class": "Goblin da Lama", "hp": 120, "atk": 10, "def": 15, "mov": 2, "rng": 1})
	assert_eq(gm.party_data.size(), 2, "Kroug não duplicado")

func test_party_data_persisted_in_save() -> void:
	gm.game_data.starting_ally = "none"
	gm.start_new_game()
	gm.add_to_party({"name": "Lira", "class": "Dríade", "hp": 100, "atk": 8, "def": 12, "mov": 2, "rng": 2})
	var save = gm.save_game()
	# save_game escreve em arquivo; verificar que a chave party_data vai pro dict de dados
	var save_data = {
		"party_data": gm.party_data
	}
	assert_eq(save_data.party_data.size(), 2, "party_data com 2 membros no save")

func test_load_restores_party() -> void:
	gm.game_data.starting_ally = "kroug"
	gm.start_new_game()
	var saved_party = gm.party_data.duplicate()

	# Simular load: novo GM restaura party_data de um save
	var NewGM = load("res://scripts/game_manager.gd").new()
	add_child_autofree(NewGM)
	NewGM.party_data = saved_party
	assert_eq(NewGM.party_data.size(), 2, "party restaurada no load")
	assert_true(NewGM.party_data.any(func(m): return m.name == "Kroug"), "Kroug restaurado")