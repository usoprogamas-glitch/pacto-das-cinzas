extends "res://addons/gut/test.gd"
## Testes GUT: resolução de cardinal por NOME (P0-1 da auditoria)
## Bug: BOSS_CARDINAL_BY_CLASS mapeava classe "Boss" → "Ignis", então TODOS os
## chefes (Zephyr, Aqua, Terra, Umbra, Aurius 3 fases) usavam partes/spells de
## Ignis no runtime. Agora: nome da unit → cardinal data-driven.

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node

func before_each():
	# SEM add_child: _ready da cena exige $BattleGrid/$Camera2D e compila shaders.
	# setup_systems() constrói os sistemas puros (incl. boss_system) sem árvore.
	bs = BattleSceneScript.new()
	bs.setup_systems()

# === Resolução nome → cardinal ===

func test_cardinal_names_resolve_to_themselves():
	for cardinal in ["Ignis", "Zephyr", "Aqua", "Terra", "Umbra"]:
		assert_eq(bs._resolve_cardinal_name(cardinal), cardinal,
			"%s casa com a própria chave de CARDINALS" % cardinal)

func test_aurius_phases_all_resolve_to_aurius():
	# As 3 fases têm nomes distintos no EnemyDatabase; o BossSystem só conhece "Aurius".
	assert_eq(bs._resolve_cardinal_name("Aurius — Falso Demiurgo"), "Aurius")
	assert_eq(bs._resolve_cardinal_name("Aurius — Serafim Tirano"), "Aurius")
	assert_eq(bs._resolve_cardinal_name("Aurius — Luz Desesperada"), "Aurius")

func test_legacy_generic_cardinal_binds_to_ignis():
	# "Santo Cardeal" (mapa lateral 4) não é chave de CARDINALS → binding legado.
	assert_eq(bs._resolve_cardinal_name("Santo Cardeal"), "Ignis")

func test_non_boss_names_resolve_to_empty():
	assert_eq(bs._resolve_cardinal_name("Mercenário"), "")
	assert_eq(bs._resolve_cardinal_name("Kael"), "")
	assert_eq(bs._resolve_cardinal_name(""), "")

# === Spawn runtime integra a resolução (sem árvore: stubs mínimos) ===

class FakeGrid:
	extends RefCounted
	func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
		return Vector2(grid_pos.x * 32, grid_pos.y * 32)

func _stub_tree_deps():
	bs.set("grid", FakeGrid.new())
	bs.set("unit_container", Node2D.new())

func test_spawn_zephyr_binds_zephyr_not_ignis():
	_stub_tree_deps()
	BattleManager.enemy_units.clear()
	var unit = bs.spawn_enemy_unit(Vector2i(9, 5), "Zephyr", Color(0.3, 0.7, 1.0), "Boss", 450, 40, 20, 3, 4)
	assert_not_null(unit)
	assert_eq(bs.boss_system.get_current_boss_name(), "Zephyr", "painel/partes/spells de Zephyr, não Ignis")
	BattleManager.enemy_units.clear()

func test_spawn_aurius_phase1_binds_aurius():
	_stub_tree_deps()
	BattleManager.enemy_units.clear()
	var unit = bs.spawn_enemy_unit(Vector2i(9, 5), "Aurius — Falso Demiurgo", Color(1.0, 0.95, 0.3), "Boss", 800, 45, 40, 2, 4)
	assert_not_null(unit)
	assert_eq(bs.boss_system.get_current_boss_name(), "Aurius", "Aurius Fase 1 → sistema Aurius (3 fases)")
	BattleManager.enemy_units.clear()

func test_spawn_mercenary_does_not_touch_boss_system():
	_stub_tree_deps()
	BattleManager.enemy_units.clear()
	var unit = bs.spawn_enemy_unit(Vector2i(9, 5), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
	assert_not_null(unit)
	assert_false(bs.boss_system.is_boss_active(), "inimigo comum não ativa o BossSystem")
	BattleManager.enemy_units.clear()

func test_spawn_all_cardinals_binds_each_one():
	# Varre os 5 Cardeais: cada spawn deve bindeer o cardinal certo.
	_stub_tree_deps()
	BattleManager.enemy_units.clear()
	for cardinal in ["Ignis", "Zephyr", "Aqua", "Terra", "Umbra"]:
		var unit = bs.spawn_enemy_unit(Vector2i(9, 5), cardinal, Color.RED, "Boss", 500, 35, 30, 2, 3)
		assert_not_null(unit, "%s spawnou" % cardinal)
		assert_eq(bs.boss_system.get_current_boss_name(), cardinal,
			"%s bindeou o próprio cardinal" % cardinal)
	BattleManager.enemy_units.clear()
