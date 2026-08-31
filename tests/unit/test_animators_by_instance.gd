extends "res://addons/gut/test.gd"
## Testes GUT: unit_animators por instância (P0-2 da auditoria)
## Bug: dicionário chaveado por unit.name — 2 inimigos "Mercenário" na mesma
## batalha colidiam (1 entrada sobrescrevia a outra) e as animações tocavam na
## unidade errada. Agora a chave é o instance_id da Unit.

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node

class FakeGrid:
	extends RefCounted
	func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
		return Vector2(grid_pos.x * 32, grid_pos.y * 32)

func before_each():
	bs = BattleSceneScript.new()
	bs.setup_systems()
	bs.set("grid", FakeGrid.new())
	bs.set("unit_container", Node2D.new())
	BattleManager.player_units.clear()
	BattleManager.enemy_units.clear()

func after_each():
	BattleManager.player_units.clear()
	BattleManager.enemy_units.clear()
	# unit_container é Node2D standalone (não filho de bs) → liberar manualmente
	# para não orfanar as units filhas.
	var container = bs.get("unit_container")
	if is_instance_valid(container):
		container.free()
	if is_instance_valid(bs):
		bs.free()

func _spawn_two_same_name_enemies() -> Array:
	var a = bs.spawn_enemy_unit(Vector2i(8, 4), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
	var b = bs.spawn_enemy_unit(Vector2i(9, 5), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
	return [a, b]

func test_duplicate_names_get_distinct_animators():
	var units = _spawn_two_same_name_enemies()
	assert_eq(bs.unit_animators.size(), 2, "2 units = 2 entradas (sem colisão)")
	var anim_a = bs._get_animator(units[0])
	var anim_b = bs._get_animator(units[1])
	assert_not_null(anim_a)
	assert_not_null(anim_b)
	assert_ne(anim_a, anim_b, "cada unit tem o PRÓPRIO animator")

func test_get_animator_returns_right_instance():
	var units = _spawn_two_same_name_enemies()
	# Assinatura do animator é o próprio Node filho "Animator" — comparar instâncias.
	assert_eq(bs._get_animator(units[0]), units[0].get_node("Animator"))
	assert_eq(bs._get_animator(units[1]), units[1].get_node("Animator"))

func test_get_animator_unknown_unit_returns_null():
	var unit_script = load("res://scripts/units/unit.gd")
	var stranger = unit_script.new()
	autofree(stranger)
	var result = bs._get_animator(stranger)
	assert_null(result, "unit sem animator → null, sem crash")

func test_player_units_also_get_instance_keyed_animators():
	BattleManager.player_units.clear()
	var kael = bs.spawn_player_unit(Vector2i(2, 6), "Kael", Color(0.2, 0.8, 0.3), "Imp Menor", 80, 12, 8, 3, 1)
	var kroug = bs.spawn_player_unit(Vector2i(1, 7), "Kroug", Color(0.8, 0.3, 0.1), "Goblin da Lama", 120, 10, 15, 2, 1)
	assert_not_null(bs._get_animator(kael))
	assert_not_null(bs._get_animator(kroug))
	assert_ne(bs._get_animator(kael), bs._get_animator(kroug))
