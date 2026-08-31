extends "res://addons/gut/test.gd"

## Wiring GDD §6.3 na exploração contínua (molde SoS): puzzles de luz declarados
## no MapDatabase spawnam no mapa (espelhos de obsidiana + relógio cósmico),
## interagem com E e pagam as recompensas data-driven ao serem resolvidos.

const ExploreScript := preload("res://scripts/explore_scene.gd")

var _explore: Node


func before_each() -> void:
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


## Gira o espelho até o ângulo alvo (2 = 90°, Leste → alvo), teleportando o
## jogador para o nó correspondente (o mesmo caminho do E no jogo).
func _align_mirror(scene: Node, entry: Dictionary, mirror_id: String, target_angle: int = 2) -> void:
	var mirror: Dictionary = entry["system"].get_mirror(mirror_id)
	var needed: int = (target_angle - int(mirror["angle"]) + 8) % 8
	var node: Node2D = entry["nodes"][mirror_id]
	scene.player.position = node.position
	for i in range(needed):
		scene._interact_puzzles()


func test_maps_act1_and_act2_declare_puzzles_data_driven():
	assert_eq(MapDatabase.get_map(0).get("puzzles", []).size(), 1, "Ato I (mapa 0) declara 1 puzzle")
	assert_eq(MapDatabase.get_map(5).get("puzzles", []).size(), 1, "Ato II (mapa 5) declara 1 puzzle")
	assert_eq(MapDatabase.get_map(1).get("puzzles", []).size(), 0, "mapa sem puzzle não declara")
	for map_id in [0, 5]:
		for cfg in MapDatabase.get_map(map_id)["puzzles"]:
			assert_true(LightPuzzleSystem.PUZZLE_TYPES.has(String(cfg["type"])), "tipo válido: %s" % cfg["type"])
			assert_has(cfg, "rewards", "recompensa declarada nos dados")


func test_puzzle_spawns_mirrors_and_pedestals_in_explore():
	var scene := _open()
	assert_eq(scene.puzzles.size(), 1, "puzzle do mapa spawha na exploração")
	var entry: Dictionary = scene.puzzles[0]
	assert_eq(String(entry["id"]), "fronteira_espelhos")
	assert_eq(entry["nodes"].size(), 2, "2 espelhos de obsidiana no mapa")
	assert_not_null(entry["light_node"], "pedestal de luz presente")
	assert_not_null(entry["target_node"], "pedestal alvo presente")
	assert_false(entry["solved"], "puzzle começa não resolvido")


func test_mirror_rotation_updates_pointer_and_alignment():
	var scene := _open()
	var entry: Dictionary = scene.puzzles[0]
	_align_mirror(scene, entry, "m1")
	var mirror: Dictionary = entry["system"].get_mirror("m1")
	assert_eq(int(mirror["angle"]), 2, "espelho chegou ao ângulo do alvo")
	assert_true(bool(mirror["aligned"]), "espelho alinhado com o alvo")
	var node: Node2D = entry["nodes"]["m1"]
	assert_eq(float(node.get_meta("pointer").rotation), deg_to_rad(0.0), "ponteiro aponta para o alvo (Leste)")


func test_solving_puzzle_pays_rewards_and_projects_beam():
	var scene := _open()
	var entry: Dictionary = scene.puzzles[0]
	var ether_before: int = int(GameManager.game_data["soul_ether"])
	var gold_before: int = int(GameManager.game_data["gold"])
	_align_mirror(scene, entry, "m1")
	_align_mirror(scene, entry, "m2")
	assert_true(entry["solved"], "puzzle marcado como resolvido na cena")
	assert_eq(int(GameManager.game_data["soul_ether"]), ether_before + 5, "soul ether pago")
	assert_eq(int(GameManager.game_data["gold"]), gold_before + 10, "ouro pago")
	assert_true(entry.has("beam"), "feixe de luz projetado")
	assert_eq(entry["beam"].points.size(), 4, "feixe liga luz → 2 espelhos → alvo")


func test_clock_puzzle_solves_with_eclipse_timing():
	GameManager.game_data["current_map"] = 5
	var scene := _open()
	assert_eq(scene.puzzles.size(), 1, "puzzle de sombra spawha no Ato II")
	var entry: Dictionary = scene.puzzles[0]
	assert_not_null(entry.get("clock_node"), "relógio cósmico presente")
	var clock: Node2D = entry["clock_node"]
	scene.player.position = clock.position
	for i in range(3):
		scene._interact_puzzles()
	assert_true(entry["system"].is_eclipse_active(), "eclipse ativo no tempo 3")
	assert_true(entry["solved"], "shadow_reveal resolvido (espelho + eclipse)")


func test_solved_puzzle_does_not_double_reward():
	GameManager.game_data["current_map"] = 5
	var scene := _open()
	var entry: Dictionary = scene.puzzles[0]
	var clock: Node2D = entry["clock_node"]
	scene.player.position = clock.position
	for i in range(3):
		scene._interact_puzzles()
	var ether_after_solve: int = int(GameManager.game_data["soul_ether"])
	for i in range(3):
		scene._interact_puzzles()
	assert_eq(int(GameManager.game_data["soul_ether"]), ether_after_solve, "sem recompensa duplicada")
	assert_true(entry["solved"], "puzzle continua resolvido")
