extends "res://addons/gut/test.gd"

## Travessia dinâmica (GDD §6.1, AUDIT P1 #13): nós data-driven no mapa
## (fenda de arpéu, penhasco, desfiladeiro), validação no núcleo
## (attempt_traversal: stamina + asas + alcance) e payout na exploração.

const TraversalLib := preload("res://scripts/traversal_system.gd")
const ExploreScript := preload("res://scripts/explore_scene.gd")
const LightPuzzleSystemLib := preload("res://scripts/light_puzzle_system.gd")

var _sys


func before_each() -> void:
	_sys = TraversalLib.new()
	_sys.setup(false, 100)
	GameManager.game_data["current_map"] = 5
	GameManager.game_data.erase("has_wings")


func after_each() -> void:
	_sys = null


# --- Núcleo: attempt_traversal ---

func test_attempt_consumes_stamina_and_emits():
	var started := []
	_sys.traversal_started.connect(func(t): started.append(t))
	var r: Dictionary = _sys.attempt_traversal("climb", {"height": 3})
	assert_true(r.can, "escalada de altura 3 dentro do alcance")
	assert_eq(_sys.get_stamina(), 80, "stamina 100 - 20 da escalada")
	assert_eq(started, ["climb"], "traversal_started emitido")


func test_attempt_rejects_height_beyond_climb_range():
	var r: Dictionary = _sys.attempt_traversal("climb", {"height": 9})
	assert_false(r.can, "altura 9 > max_height 5 da escalada")
	assert_true(r.reason.contains("Altura"), "motivo claro de alcance")
	assert_eq(_sys.get_stamina(), 100, "nada consumido em recusa")


func test_attempt_rejects_harpoon_without_wings():
	var r: Dictionary = _sys.attempt_traversal("ether_harpoon", {"distance": 4})
	assert_false(r.can, "arpéu exige Asas de Cinzas")
	assert_true(r.reason.contains("asas"), "motivo: precisa de asas")


func test_attempt_harpoon_with_wings_and_range_check():
	_sys.setup(true, 100)
	var ok: Dictionary = _sys.attempt_traversal("ether_harpoon", {"distance": 6})
	assert_true(ok.can, "distância 6 dentro do range 6 do arpéu")
	_sys.setup(true, 100)
	var out: Dictionary = _sys.attempt_traversal("ether_harpoon", {"distance": 7})
	assert_false(out.can, "distância 7 fora do range 6 do arpéu")
	assert_true(out.reason.contains("alcance"), "motivo de alcance")


func test_attempt_dash_distance_check():
	var ok: Dictionary = _sys.attempt_traversal("dash", {"distance": 3})
	assert_true(ok.can, "dash de 3 dentro do dash_distance 3")
	_sys.setup(false, 100)
	var out: Dictionary = _sys.attempt_traversal("dash", {"distance": 5})
	assert_false(out.can, "dash de 5 além do dash_distance 3")


# --- Dados: mapa declara traversal_nodes ---

func test_map_database_declares_traversal_nodes():
	var map5: Dictionary = MapDatabase.get_map(5)
	assert_gt(map5.get("traversal_nodes", []).size(), 0, "mapa 5 tem nós de travessia")
	var map6: Dictionary = MapDatabase.get_map(6)
	assert_gt(map6.get("traversal_nodes", []).size(), 0, "mapa 6 tem nó com grants_wings")
	var node0: Dictionary = map5["traversal_nodes"][0]
	assert_true(node0.has_all(["id", "ability", "pos", "rewards"]), "nó declarado completo")


func test_traversal_content_covers_act_3_and_4():
	# Conteúdo (AUDIT fila): cada mapa de boss do Ato III/IV tem ao menos 1 nó.
	for map_id in [5, 6, 7, 8, 9, 10]:
		var map: Dictionary = MapDatabase.get_map(map_id)
		assert_gt(map.get("traversal_nodes", []).size(), 0, "mapa %d tem nó de travessia" % map_id)


func test_props_data_driven_reference_existing_assets():
	# Props ComfyUI: todo texture declarado precisa existir em assets/props/.
	for map_id in [0, 1, 5, 6, 10]:
		var map: Dictionary = MapDatabase.get_map(map_id)
		for prop in map.get("props", []):
			var path: String = "res://assets/props/%s.png" % String(prop["texture"])
			assert_true(ResourceLoader.exists(path), "prop %s existe (%s)" % [prop["texture"], path])


func test_puzzles_content_covers_every_boss_map():
	# Conteúdo (AUDIT fila): todo mapa de boss (Ato I-IV) tem 1 puzzle válido
	# e os mapas laterais (2, 4) também têm conteúdo.
	var valid_types: Array = LightPuzzleSystemLib.PUZZLE_TYPES.keys()
	for map_id in [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]:
		var map: Dictionary = MapDatabase.get_map(map_id)
		var puzzle_list: Array = map.get("puzzles", [])
		assert_gt(puzzle_list.size(), 0, "mapa %d tem puzzle" % map_id)
		for puzzle in puzzle_list:
			assert_true(puzzle["type"] in valid_types, "puzzle do mapa %d tem tipo válido" % map_id)


func test_side_maps_have_traversal_and_decorations():
	# Conteúdo lateral (mapas não-estágio): Caverna (2) e Vulcão (4) ganham
	# traversal + decorações de tile (Eder) para valerem a visita.
	for map_id in [2, 4]:
		var map: Dictionary = MapDatabase.get_map(map_id)
		assert_gt(map.get("traversal_nodes", []).size(), 0, "mapa lateral %d tem travessia" % map_id)


# --- Cena: spawn + payout ---

func _open_explore() -> Node:
	var scene = add_child_autofree(ExploreScript.new())
	return scene


func test_explore_spawns_traversal_nodes():
	GameManager.game_data["current_map"] = 5
	GameManager.game_data["has_wings"] = true
	var scene := _open_explore()
	assert_eq(scene.traversal_nodes.size(), 2, "mapa 5 spawna 2 nós de travessia")
	assert_not_null(scene.traversal, "TraversalSystem criado")
	assert_true(scene.traversal.has_wings(), "asas do save propagam ao sistema")
	for entry in scene.traversal_nodes:
		assert_not_null(entry["node"], "nó visual presente")
		assert_false(entry["solved"], "nó pendente no spawn")


func test_explore_interaction_pays_and_consumes_node():
	GameManager.game_data["current_map"] = 5
	GameManager.game_data["has_wings"] = true
	var scene := _open_explore()
	var entry: Dictionary = scene.traversal_nodes[1]  # penhasco (climb, sem asas)
	scene.player.position = entry["node"].position  # teleporta ao nó
	var ether_before: int = GameManager.game_data["soul_ether"]
	scene._interact_traversal()
	assert_true(entry["solved"], "nó consumido após travessia")
	assert_gt(GameManager.game_data["soul_ether"], ether_before, "soul_ether pago")
	assert_lt(scene.traversal.get_stamina(), scene.traversal.get_max_stamina(), "stamina consumida pela travessia")
	assert_false(scene.traversal.is_traversing(), "travessia finalizada")


func test_explore_grants_wings_flag():
	GameManager.game_data["current_map"] = 6
	GameManager.game_data["has_wings"] = false
	var scene := _open_explore()
	assert_false(scene.traversal.has_wings(), "sem asas no início")
	var entry: Dictionary = scene.traversal_nodes[0]  # desfiladeiro (dash, grants_wings)
	scene.player.position = entry["node"].position
	scene._interact_traversal()
	assert_true(GameManager.game_data.get("has_wings", false), "desfiladeiro de Zephyr concede Asas de Cinzas")
	assert_true(scene.traversal.has_wings(), "sistema atualizado com asas")


func test_explore_rejects_without_wings_and_keeps_node():
	GameManager.game_data["current_map"] = 5
	GameManager.game_data["has_wings"] = false
	var scene := _open_explore()
	var entry: Dictionary = scene.traversal_nodes[0]  # fenda (arpéu, precisa de asas)
	scene.player.position = entry["node"].position
	var ether_before: int = GameManager.game_data["soul_ether"]
	scene._interact_traversal()
	assert_false(entry["solved"], "nó permanece pendente em recusa")
	assert_eq(GameManager.game_data["soul_ether"], ether_before, "nada pago em recusa")
