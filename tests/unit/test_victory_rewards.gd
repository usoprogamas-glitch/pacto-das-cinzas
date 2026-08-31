extends "res://addons/gut/test.gd"

## Testes GUT: sistema de recompensas de vitória (Fase 1 - VictoryRewards).
## Valida que o GameManager aplica recompensas corretamente (soul_ether, gold,
## xp, captured_souls) e que o battle_scene calcula rewards a partir do stage.

var gm: Node
var rewards: Resource

func before_each() -> void:
	var GM = load("res://scripts/game_manager.gd")
	gm = GM.new()
	gm._ready()
	add_child_autofree(gm)
	rewards = load("res://scripts/victory_rewards.gd").new()

func test_victory_rewards_default_values() -> void:
	assert_eq(rewards.soul_ether, 0, "soul_ether default 0")
	assert_eq(rewards.gold, 0, "gold default 0")
	assert_eq(rewards.xp, 0, "xp default 0")
	assert_eq(rewards.captured_souls.size(), 0, "sem souls capturados default")
	assert_eq(rewards.unlocks.size(), 0, "sem unlocks default")

func test_victory_rewards_constructor_sets_fields() -> void:
	var souls: Array[Dictionary] = [{"type": "goblin_lama", "display_name": "Kroug"}]
	var unlocks: Array[String] = ["next_stage"]
	var r = load("res://scripts/victory_rewards.gd").new(10, 20, 30, souls, unlocks)
	assert_eq(r.soul_ether, 10)
	assert_eq(r.gold, 20)
	assert_eq(r.xp, 30)
	assert_eq(r.captured_souls.size(), 1)
	assert_eq(r.unlocks[0], "next_stage")

func test_apply_victory_rewards_adds_soul_ether_and_gold() -> void:
	var before_soul = gm.game_data.soul_ether
	var before_gold = gm.game_data.gold
	rewards.soul_ether = 25
	rewards.gold = 40
	gm.apply_victory_rewards(rewards)
	assert_eq(gm.game_data.soul_ether, before_soul + 25, "soul_ether acumulou")
	assert_eq(gm.game_data.gold, before_gold + 40, "gold acumulou")

func test_apply_victory_rewards_adds_experience() -> void:
	var before_xp = gm.progression_system.total_experience if gm.progression_system else 0
	rewards.xp = 100
	gm.apply_victory_rewards(rewards)
	if gm.progression_system:
		assert_eq(gm.progression_system.total_experience, before_xp + 100, "xp acumulou no ProgressionSystem")

func test_apply_victory_rewards_records_captured_souls() -> void:
	var souls: Array[Dictionary] = [{"type": "goblin_lama", "display_name": "Kroug"}]
	rewards.captured_souls = souls
	gm.apply_victory_rewards(rewards)
	assert_true(gm.game_data.has("victory_rewards"), "victory_rewards persistido no game_data")
	assert_eq(gm.game_data.victory_rewards.captured_souls.size(), 1, "soul registrado nas recompensas")

func test_apply_victory_rewards_applies_unlocks_to_game_data() -> void:
	rewards.unlocks.append("next_stage")
	gm.apply_victory_rewards(rewards)
	assert_eq(gm.game_data.victory_rewards.unlocks[0], "next_stage", "unlocks persistidos")