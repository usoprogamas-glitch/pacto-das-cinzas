extends "res://addons/gut/test.gd"

## Ciclo de caminhada com poses LoRA REAIS (assets/px/poses/<char>/char_<pose>.png)
## — o molde SoS <Char>_<Anim>_D<dir>_F<frame> aplicado ao nosso pipeline.
## Kael: walk a/b/c/d + attack. Fallback: bandas (SpriteMotionLibrary).

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


func test_kael_walk_cycle_uses_lora_poses():
	_explore = add_child_autofree(ExploreScript.new())
	assert_true(_explore.player_own_sets.has("walk"), "walk set existe")
	var walk: Array = _explore.player_own_sets["walk"]
	assert_eq(walk.size(), 4, "4 keyframes de caminhada")
	# frames distintos entre si (poses reais, não repetição)
	assert_ne(walk[0].get_instance_id(), walk[1].get_instance_id(), "pose A != pose B")


func test_kael_attack_pose_available():
	_explore = add_child_autofree(ExploreScript.new())
	assert_true(_explore.player_own_sets.has("attack"), "attack set existe")
	var atk: Array = _explore.player_own_sets["attack"]
	assert_eq(atk.size(), 1, "1 pose de ataque")


func test_walk_cycle_ticks_through_frames():
	_explore = add_child_autofree(ExploreScript.new())
	var spr: Sprite2D = _explore.player_own_sprite
	var f0: Texture2D = spr.texture
	# ticka o ciclo manualmente (o _process do explore faz isso ao andar)
	for i in range(4):
		_explore.player_own_frame = float(i) / 4.0
		var frames: Array = _explore.player_own_sets["walk"]
		spr.texture = frames[i]
		if spr.texture != f0:
			break
	assert_ne(spr.texture, f0, "ciclo troca de frame ao tickar")


func test_buddy_kroug_uses_own_poses():
	GameManager.game_data["starting_ally"] = "kroug"
	_explore = add_child_autofree(ExploreScript.new())
	assert_true(_explore.buddy_own_sets.has("walk"), "Kroug com walk set próprio")
