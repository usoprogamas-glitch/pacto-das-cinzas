extends "res://addons/gut/test.gd"

## Testes GUT para TurnOrderManager (velocity-based, empate = player primeiro).
## Contrato de unidade fake: get_speed() / is_player_side() / is_alive()

var _next_id: int = 0


func _make_unit(speed: int, player_side: bool, alive: bool = true):
	# Stub leve via GDScript: classe anônima com o contrato do TurnOrderManager.
	var unit = RefCounted.new()
	unit.set_script(preload("res://tests/unit/stubs/fake_unit.gd"))
	unit.speed = speed
	unit.player_side = player_side
	unit.alive = alive
	_next_id += 1
	return unit


func test_faster_unit_acts_first():
	var slow = _make_unit(5, true)
	var fast = _make_unit(12, false)
	var order = TurnOrderManager.build_order([slow, fast])
	assert_eq(order[0], fast, "Unidade mais veloz deve agir primeiro")
	assert_eq(order[1], slow)


func test_tie_player_goes_first():
	var enemy = _make_unit(10, false)
	var player = _make_unit(10, true)
	var order = TurnOrderManager.build_order([enemy, player])
	assert_eq(order[0], player, "Empate: jogador age antes")


func test_dead_units_excluded():
	var dead = _make_unit(99, true, false)
	var living = _make_unit(3, false)
	var order = TurnOrderManager.build_order([dead, living])
	assert_eq(order.size(), 1, "Mortos não entram na ordem")
	assert_eq(order[0], living)


func test_null_entries_ignored():
	var u = _make_unit(7, true)
	var order = TurnOrderManager.build_order([null, u, null])
	assert_eq(order.size(), 1)


func test_order_is_descending_by_speed():
	var units := [
		_make_unit(2, true),
		_make_unit(20, false),
		_make_unit(8, true),
		_make_unit(15, false),
	]
	var order = TurnOrderManager.build_order(units)
	for i in range(order.size() - 1):
		assert_true(order[i].get_speed() >= order[i + 1].get_speed(),
			"Ordem deve ser decrescente por velocidade")
