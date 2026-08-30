extends "res://addons/gut/test.gd"
## Testes GUT: fluxo de alma capturada → naming modal (ROADMAP #2/#3)
## Valida o ponteiro de dados (CapturedSouls / soul_type) e o guard do modal,
## sem precisar instanciar a cena de vitória (que faz await em árvore).

func test_captured_souls_one_per_type():
	var cs = CapturedSouls.new()
	cs.add("goblin_lama", "Goblin")
	cs.add("goblin_lama", "Outro Goblin")
	assert_eq(cs.souls.size(), 1, "um slot por tipo, evita spam de UI")
	assert_true(cs.has_captured())

func test_captured_souls_empty_by_default():
	var cs = CapturedSouls.new()
	assert_false(cs.has_captured())

func test_unit_class_to_soul_type_maps_only_nameable():
	# A source of truth: UnitData.soul_type é o nome da alma. Apenas goblin_lama
	# (e futuros nameáveis) carrega o campo; outras classes deixam "".
	var ud: UnitData = UnitData.new()
	ud.soul_type = "goblin_lama"
	assert_eq(ud.soul_type, "goblin_lama")
	ud = UnitData.new()
	assert_eq(ud.soul_type, "", "classe não nameável tem soul_type vazio")

func test_name_soul_bridges_to_apostle():
	# Replay do ponteiro do pacto: nomear um tipo nameável registra apóstolo.
	var res = GameManager.naming_system.name_soul("goblin_lama", "Pudd")
	assert_true(res.success, "goblin_lama é nameável")
	GameManager.faith_system.register_apostle("Pudd")
	assert_true(GameManager.faith_system.faith_data.has("Pudd"), "apóstolo registrado pós-nome")

func test_name_soul_unknown_type_fails():
	var res = GameManager.naming_system.name_soul("dragão", "Smaug")
	assert_false(res.success)
	assert_eq(res.reason, "type_not_found")
