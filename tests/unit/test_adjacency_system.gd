extends "res://addons/gut/test.gd"

## Testes GUT para AdjacencySystem (Elos Sinérgicos, GDD v2 §4)


var _adj: AdjacencySystem


func _ready():
	_adj = AdjacencySystem.new()


func _make_apostle(name: String, pos: Vector2i):
	var unit = RefCounted.new()
	unit.set_script(preload("res://tests/unit/stubs/fake_unit_adjacency.gd"))
	unit.unit_name = name
	unit.is_player = false
	unit.grid_position = pos
	return unit


func _make_hero(pos: Vector2i):
	var unit = RefCounted.new()
	unit.set_script(preload("res://tests/unit/stubs/fake_unit_adjacency.gd"))
	unit.unit_name = "Querubim"
	unit.is_player = true
	unit.grid_position = pos
	return unit


# --- Adjacência básica ---

func test_adjacent_horizontal():
	assert_true(_adj.are_adjacent(Vector2i(5, 5), Vector2i(6, 5)), "Horizontal adjacente")


func test_adjacent_vertical():
	assert_true(_adj.are_adjacent(Vector2i(5, 5), Vector2i(5, 6)), "Vertical adjacente")


func test_not_adjacent_diagonal():
	assert_false(_adj.are_adjacent(Vector2i(5, 5), Vector2i(6, 6)), "Diagonal não é adjacente")


func test_not_adjacent_two_tiles():
	assert_false(_adj.are_adjacent(Vector2i(5, 5), Vector2i(7, 5)), "Dois tiles não é adjacente")


# --- Kroug: +15% DEF ---

func test_kroug_adjacent_defense_bonus():
	var hero = _make_hero(Vector2i(5, 5))
	var kroug = _make_apostle("Kroug", Vector2i(6, 5))
	var mult = _adj.get_defense_multiplier(hero.grid_position, [kroug])
	assert_eq(mult, 1.15, "Kroug adjacente: +15% DEF")


func test_kroug_far_no_defense_bonus():
	var hero = _make_hero(Vector2i(5, 5))
	var kroug = _make_apostle("Kroug", Vector2i(8, 5))
	var mult = _adj.get_defense_multiplier(hero.grid_position, [kroug])
	assert_eq(mult, 1.0, "Kroug longe: sem bônus DEF")


# --- Lira: 2% HP regen ---

func test_lira_adjacent_hp_regen():
	var hero = _make_hero(Vector2i(5, 5))
	hero.max_hp = 100
	var lira = _make_apostle("Lira", Vector2i(4, 5))
	var regen = _adj.get_hp_regen(hero.grid_position, [lira], hero.max_hp)
	assert_eq(regen, 2, "Lira adjacente: 2% de 100 = 2 HP")


func test_lira_far_no_regen():
	var hero = _make_hero(Vector2i(5, 5))
	hero.max_hp = 100
	var lira = _make_apostle("Lira", Vector2i(3, 5))
	var regen = _adj.get_hp_regen(hero.grid_position, [lira], hero.max_hp)
	assert_eq(regen, 0, "Lira longe: sem regen")


# --- Thal'kor: +10% ATK ---

func test_thalkor_adjacent_attack_bonus():
	var hero = _make_hero(Vector2i(5, 5))
	var thalkor = _make_apostle("Thal'kor", Vector2i(5, 6))
	var mult = _adj.get_attack_multiplier(hero.grid_position, [thalkor])
	assert_eq(mult, 1.10, "Thal'kor adjacente: +10% ATK")


# --- Múltiplos apóstolos ---

func test_multiple_apostles_stack():
	var hero = _make_hero(Vector2i(5, 5))
	hero.max_hp = 100
	var kroug = _make_apostle("Kroug", Vector2i(6, 5))
	var lira = _make_apostle("Lira", Vector2i(4, 5))
	var thalkor = _make_apostle("Thal'kor", Vector2i(5, 6))
	var allies = [kroug, lira, thalkor]
	assert_eq(_adj.get_defense_multiplier(hero.grid_position, allies), 1.15, "DEF: só Kroug")
	assert_eq(_adj.get_attack_multiplier(hero.grid_position, allies), 1.10, "ATK: só Thal'kor")
	assert_eq(_adj.get_hp_regen(hero.grid_position, allies, hero.max_hp), 2, "Regen: só Lira")


# --- get_adjacent_apostles ---

func test_get_adjacent_apostles():
	var hero = _make_hero(Vector2i(5, 5))
	var kroug = _make_apostle("Kroug", Vector2i(6, 5))
	var lira = _make_apostle("Lira", Vector2i(10, 10))
	var adjacent = _adj.get_adjacent_apostles(hero.grid_position, [kroug, lira])
	assert_eq(adjacent.size(), 1, "Só 1 apóstolo adjacente")


# --- has_synergy ---

func test_has_synergy_kroug():
	assert_true(_adj.has_synergy("Kroug"), "Kroug tem elo sinérgico")


func test_has_synergy_unknown():
	assert_false(_adj.has_synergy("Garm"), "Garm não tem elo definido")
