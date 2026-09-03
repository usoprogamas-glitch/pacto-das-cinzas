extends "res://addons/gut/test.gd"

## Tutorial contextual (polish onboarding): dicas mostradas 1x por chave,
## flag persistida em game_data["tutorials"].

func before_each() -> void:
	GameManager.game_data.erase("tutorials")
	GameManager.game_data["current_map"] = 0
	GameManager.campaign_system.reset()
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	GameManager.game_data.erase("tutorials")


func test_tutorial_flag_persists():
	var arena = add_child_autofree(preload("res://scripts/arena_battle.gd").new())
	arena.combat_frozen = true
	arena.combatants = []
	arena.enemies_meta = []
	# Primeira chamada marca a flag.
	arena._show_tutorial_if_first("timed_hit")
	assert_true(GameManager.game_data["tutorials"].get("timed_hit", false), "flag marcada na 1ª vez")
	# Segunda chamada: sem nova exibição (flag já true — o guard cobre).
	arena._show_tutorial_if_first("timed_hit")
	assert_true(GameManager.game_data["tutorials"].get("timed_hit", false), "flag segue true")
	arena.free()


func test_movement_tutorial_shown_on_map_entry():
	GameManager.game_data.erase("tutorials")
	var scene = add_child_autofree(preload("res://scripts/explore_scene.gd").new())
	await wait_frames(2)
	assert_true(GameManager.game_data.get("tutorials", {}).get("movement", false), "banner de entrada mostra controles 1x")
	scene.free()


func wait_frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
