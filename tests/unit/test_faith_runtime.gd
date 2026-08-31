extends "res://addons/gut/test.gd"
## Testes GUT: fé runtime dos apóstolos ao vencer batalha
## Valida que _commit_progression() do battle_scene fortalece o pacto: cada
## vitória dá +10 de fé a TODOS os apóstolos registrados no FaithSystem.
## Fecha o loop: antes a fé era estática (só +25 no start_new_game), e os sinais
## faith_changed/faith_level_up nunca disparam em runtime.

const BattleSceneScript := preload("res://scripts/battle_scene.gd")

var bs: Node

func before_each() -> void:
	bs = BattleSceneScript.new()
	bs.progression_system = preload("res://scripts/progression_system.gd").new()
	# Estado determinístico (não somar): FaithSystem do GameManager é autoload
	# persistente que acumula entre testes — seta Kroug direto em 25/Neutro.
	GameManager.faith_system.faith_data["Kroug"] = {"faith": 25, "level": "Neutro", "bonuses": {}}

func after_each() -> void:
	if is_instance_valid(bs):
		bs.free()

func test_registered_apostles_gain_faith_on_victory():
	var before_faith: int = GameManager.faith_system.get_faith("Kroug")
	bs._commit_progression()
	assert_eq(GameManager.faith_system.get_faith("Kroug"), before_faith + 10,
		"Apóstolo registrado ganha +10 fé por vitória")

func test_faith_crosses_level_and_emits_faith_level_up():
	var faith: FaithSystem = GameManager.faith_system
	# Kroug 25 (Neutro); +10 = 35 cruza o nível "Leal" (30)
	assert_eq(faith.get_faith_level(faith.get_faith("Kroug")), "Neutro",
		"pré-condição: fé base 25 é Neutro")
	watch_signals(faith)
	bs._commit_progression()
	assert_eq(faith.get_faith_level(faith.get_faith("Kroug")), "Leal",
		"+10 leva Kroug de Neutro para Leal")
	assert_signal_emitted(faith, "faith_level_up",
		"cruzar o threshold de nível dispara o sinal (antes nunca disparava)")

func test_unregistered_soul_does_not_gain_faith():
	# Um nome que jamais foi apóstolo não deve ser criado de graça pela vitória
	var faith: FaithSystem = GameManager.faith_system
	faith.faith_data.erase("zz_nao_apostolo")
	bs._commit_progression()
	assert_false(faith.faith_data.has("zz_nao_apostolo"),
		"get_all_apostles só cobre registrados — nome fictício não entra")

func test_faith_noops_when_faith_system_missing():
	# Autoload ausente em cenário alternativo → commit não crasha
	var saved: FaithSystem = GameManager.faith_system
	GameManager.faith_system = null
	bs._commit_progression()
	GameManager.faith_system = saved
	assert_true(true, "sem FaithSystem, commit de fé é no-op seguro")
