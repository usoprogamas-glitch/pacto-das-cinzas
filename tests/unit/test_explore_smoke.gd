extends "res://addons/gut/test.gd"

## Smoke da exploração (molde SoS): cena carrega, party spawna, inimigos
## registram no SeamlessEncounterSystem e o contato abre a arena in-place.

const ExploreScript := preload("res://scripts/explore_scene.gd")

var _explore: Node
var _won: bool = false  # lambdas capturam locais por valor: flag precisa ser membro


func before_each() -> void:
	_won = false
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	if _explore and is_instance_valid(_explore):
		_explore.free()
	_explore = null


func _open() -> Node:
	_explore = add_child_autofree(ExploreScript.new())
	return _explore


func test_explore_scene_builds_party_and_enemies():
	var scene := _open()
	assert_not_null(scene.player, "party (Kael) spawna no mapa")
	var has_sprite := false
	for child in scene.player.get_children():
		if child is Sprite2D:
			has_sprite = true
	assert_true(has_sprite, "sprite do Kael presente")
	assert_eq(scene.enemy_nodes.size(), scene.encounter.get_enemy_count(), "inimigos registrados no SeamlessEncounterSystem")


func test_explore_kroug_follows_when_canonical():
	var scene := _open()
	var has_buddy := false
	for child in scene.player.get_children():
		if child is Node2D:
			has_buddy = true
	assert_true(has_buddy, "Kroug acompanha o Kael (starting_ally=kroug)")


func test_contact_opens_arena_in_place():
	var scene := _open()
	assert_null(scene.arena, "sem arena antes do contato")
	scene.player.position = scene.enemy_nodes[0].position  # teleporte no inimigo
	scene._check_contact()
	assert_not_null(scene.arena, "contato abre a arena IN-PLACE (sem trocar de cena)")
	assert_gt(scene.arena.combatants.size(), 0, "arena tem combatentes")


func test_arena_battle_ends_and_awards_soul_ether():
	var scene := _open()
	scene.player.position = scene.enemy_nodes[0].position
	scene._check_contact()
	var arena: Node = scene.arena
	arena.battle_ended.connect(func(v, _r): _won = v)
	# Mata todos os inimigos direto no núcleo (caminho de vitória).
	for c in arena.combatants:
		if not c.is_player_side():
			c.current_hp = 0
	arena._check_end()
	assert_true(_won, "núcleo resolve vitória")
