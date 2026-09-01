extends "res://addons/gut/test.gd"

## Persistência de estado do mundo (§6.1/§6.3, AUDIT P1 conteúdo): puzzles e
## nós de travessia resolvidos ficam em game_data["world_state"] por mapa e
## reaparecem resolvidos (sem recompensa dupla) ao revisitar o estágio.

const ExploreScript := preload("res://scripts/explore_scene.gd")


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["has_wings"] = true
	GameManager.game_data.erase("world_state")


func after_each() -> void:
	GameManager.game_data.erase("world_state")


# --- Núcleo: world_state no GameManager ---

func test_world_state_starts_unsolved():
	assert_false(GameManager.is_puzzle_solved(0, "fronteira_espelhos"), "puzzle pendente por padrão")
	assert_false(GameManager.is_traversal_done(5, "fenda_ignis"), "travessia pendente por padrão")


func test_mark_puzzle_solved_persists():
	GameManager.mark_puzzle_solved(0, "fronteira_espelhos")
	assert_true(GameManager.is_puzzle_solved(0, "fronteira_espelhos"), "marcado como resolvido")
	assert_false(GameManager.is_puzzle_solved(5, "despojos_sombras"), "outro mapa permanece pendente")


func test_mark_traversal_done_persists():
	GameManager.mark_traversal_done(5, "fenda_ignis")
	assert_true(GameManager.is_traversal_done(5, "fenda_ignis"), "travessia marcada")


# --- Cena: spawn restaura e interação marca ---

func _open_explore() -> Node:
	return add_child_autofree(ExploreScript.new())


func test_explore_restores_solved_puzzle_without_rewards():
	GameManager.mark_puzzle_solved(0, "fronteira_espelhos")
	var ether_before: int = int(GameManager.game_data["soul_ether"])
	var scene := _open_explore()
	var solved_found := false
	for entry in scene.puzzles:
		if String(entry["id"]) == "fronteira_espelhos":
			solved_found = true
			assert_true(entry["solved"], "puzzle restaura resolvido do save")
	assert_true(solved_found, "puzzle do mapa 0 presente")
	assert_eq(int(GameManager.game_data["soul_ether"]), ether_before, "sem recompensa dupla no spawn")


func test_explore_restores_done_traversal_node():
	GameManager.game_data["current_map"] = 5
	GameManager.mark_traversal_done(5, "penhasco_ignis")
	var ether_before: int = int(GameManager.game_data["soul_ether"])
	var scene := _open_explore()
	for entry in scene.traversal_nodes:
		if String(entry["id"]) == "penhasco_ignis":
			assert_true(entry["solved"], "nó restaura resolvido do save")
	assert_eq(int(GameManager.game_data["soul_ether"]), ether_before, "sem recompensa dupla no spawn")


func test_explore_interaction_marks_world_state():
	GameManager.game_data["current_map"] = 5
	var scene := _open_explore()
	var entry: Dictionary = scene.traversal_nodes[1]  # penhasco (climb)
	scene.player.position = entry["node"].position
	assert_false(GameManager.is_traversal_done(5, "penhasco_ignis"), "pendente antes")
	scene._interact_traversal()
	assert_true(GameManager.is_traversal_done(5, "penhasco_ignis"), "marcado no world_state após travessia")


func test_world_state_saved_to_disk():
	GameManager.mark_puzzle_solved(0, "fronteira_espelhos")
	GameManager.save_game()
	assert_true(GameManager.game_data.get("world_state", {}).has("0"), "world_state entra no save_data via game_data")
