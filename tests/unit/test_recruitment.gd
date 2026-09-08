extends "res://addons/gut/test.gd"

## Recrutamento de aliados (GDD §3): Valera na Fronteira, Brugaves pós-Ignis.
## party_data alimenta o spawn da arena e o flag persiste no save.

const ExploreScript := preload("res://scripts/explore_scene.gd")

var _explore: Node


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["starting_ally"] = "none"
	GameManager.game_data.get_or_add("party_recruited", {}).clear()


func after_each() -> void:
	if _explore and is_instance_valid(_explore):
		_explore.free()
	_explore = null


func test_recruit_ally_adds_to_party_once():
	_explore = add_child_autofree(ExploreScript.new())
	var before: int = GameManager.party_data.size()
	_explore._recruit_ally("valera", "Valera", "Cavaleira da Ordem Caída")
	_explore._recruit_ally("valera", "Valera", "Cavaleira da Ordem Caída")  # reinteração
	assert_eq(GameManager.party_data.size(), before + 1, "aliado entra 1x só")
	var member: Dictionary = GameManager.party_data.back()
	assert_eq(member["name"], "Valera", "aliado com o nome certo")
	assert_true(GameManager.game_data["party_recruited"]["valera"], "flag persistida")


func test_recruit_brugaves_registers_apostle():
	_explore = add_child_autofree(ExploreScript.new())
	var faith_count: int = GameManager.faith_system.faith_data.size()
	_explore._recruit_ally("brugaves", "Brugaves", "Mercador Sábio")
	assert_gt(GameManager.faith_system.faith_data.size(), faith_count, "recruta vira apóstolo (GDD 2.1)")
	assert_true(GameManager.faith_system.faith_data.has("Brugaves"), "Brugaves registrado")


func test_dialogue_has_recruit_pages():
	var dlg: Dictionary = preload("res://scripts/dialogue_system.gd").DIALOGUES
	var b_first: Array = dlg["brugaves_fronteira"]["first"]
	assert_true(b_first.back().contains("VALERA"), "Brugaves apresenta Valera")
	var g_first: Array = dlg["guia_ignis"]["first"]
	assert_true(g_first.back().contains("BRUGAVES"), "Sobrevivente apresenta Brugaves")
