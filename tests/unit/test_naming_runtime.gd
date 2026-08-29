extends "res://addons/gut/test.gd"
## Testes GUT: NamingSystem não deve estar órfão (ROADMAP #3) — o Pacto de Alma
## (mecânica-assinatura) precisa rodar de verdade no runtime.

var gm: Node

func before_each():
	# GameManager é autoload; p/ teste isolado instanciamos o script direto.
	var GM = load("res://scripts/game_manager.gd")
	gm = GM.new()
	add_child_autofree(gm)

# === NamingSystem não órfão: GameManager cria e é o dono ===

func test_game_manager_owns_naming_system():
	assert_not_null(gm.naming_system, "game_manager deve criar um NamingSystem")
	assert_true(gm.naming_system is NamingSystem)

# === Primeiro pacto (escolha da intro) nomeia Kroug de verdade ===

func test_first_pact_names_kroug_as_apostle():
	# reproduzir a escolha "first_pact" da intro
	gm._on_intro_completed({"choice": {"consequence": "first_pact"}})
	assert_true(gm.naming_system.get_souls_by_type("goblin").size() > 0, "primeiro pacto deve nomear um goblin")
	var kroug = null
	for soul in gm.naming_system.get_all_souls():
		if soul.name == "Kroug":
			kroug = soul
			break
	assert_not_null(kroug, "o nome Kroug deve existir e ser o da intro")
	assert_true(gm.faith_system.faith_data.has("Kroug"), "Kroug registrado como apóstolo")

# === name_soul + pacto de alma: mecânica viva ===

func test_name_soul_creates_and_pact():
	var res = gm.naming_system.name_soul("lobo_sombrio", "Fenrir")
	assert_eq(res.success, true)
	assert_eq(res.soul.name, "Fenrir")
	var pact = gm.naming_system.form_pact(res.soul.id)
	assert_eq(pact.success, true)
	assert_true(pact.pact_power >= 0)

# === save/load round-trip do naming_system ===

func test_save_contains_naming():
	gm.naming_system.name_soul("goblin_lama", "Kroug")
	var save_data = {
		"naming_system": gm.naming_system.save_data()
	}
	# reutilizar o save_data do game_manager (sem IO): serializa
	var gm2 = load("res://scripts/game_manager.gd").new()
	add_child_autofree(gm2)  # _ready roda → initialize_systems cria o naming_system
	gm2.naming_system.load_data(save_data.naming_system)
	assert_eq(gm2.naming_system.get_total_named(), 1)
	assert_eq(gm2.naming_system.get_souls_by_type("goblin").size(), 1)

func test_name_soul_unknown_type_fails():
	var res = gm.naming_system.name_soul("dragão", "Smaug")
	assert_eq(res.success, false)
	assert_eq(res.reason, "type_not_found")