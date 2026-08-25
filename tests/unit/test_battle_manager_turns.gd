extends "res://addons/gut/test.gd"

## Testes GUT: integração TurnOrderManager + BattleManager
## (turnos individuais velocity-based dentro do round)

var bm: Node


func before_each():
	# BattleManager é autoload; para teste isolado instanciamos o script direto.
	var BM = load("res://scripts/battle/BattleManager.gd")
	bm = BM.new()
	add_child_autofree(bm)


func _make_unit(speed: int, player_side: bool, hp: int = 50) -> Unit:
	var data: UnitData = UnitData.new()
	data.speed = speed
	data.is_player = player_side
	data.max_hp = hp
	data.current_hp = hp
	var unit: Unit = Unit.new()
	unit.data = data
	unit.current_hp = hp
	return unit


func test_round_order_follows_speed():
	var fast_player := _make_unit(20, true)
	var slow_enemy := _make_unit(5, false)
	bm.register_unit(fast_player)
	bm.register_unit(slow_enemy)
	bm.start_round()
	assert_eq(bm.current_turn_unit(), fast_player, "Mais veloz abre o round")


func test_advance_gives_turn_to_next_in_order():
	var u1 := _make_unit(20, true)
	var u2 := _make_unit(8, false)
	var u3 := _make_unit(12, true)
	for u in [u1, u2, u3]:
		bm.register_unit(u)
	bm.start_round()
	assert_eq(bm.current_turn_unit(), u1)
	bm.advance_turn()
	assert_eq(bm.current_turn_unit(), u3, "Ordem: 20 -> 12 -> 8")
	bm.advance_turn()
	assert_eq(bm.current_turn_unit(), u2)


func test_dead_units_skipped_mid_round():
	var a := _make_unit(15, true)
	var b := _make_unit(10, false)
	var c := _make_unit(5, true)
	for u in [a, b, c]:
		bm.register_unit(u)
	bm.start_round()
	bm.advance_turn()          # agora é a vez de b (10)
	b.current_hp = 0           # b morre antes de agir
	bm.advance_turn()
	assert_eq(bm.current_turn_unit(), c, "Morto no meio do round deve ser pulado")


func test_new_round_after_last_unit():
	watch_signals(bm)
	var a := _make_unit(15, true)
	bm.register_unit(a)
	bm.start_round()
	assert_eq(bm.turn_count, 1)
	bm.advance_turn()
	assert_eq(bm.turn_count, 2, "Round acabou -> novo round incrementa contador")
	assert_eq(bm.current_turn_unit(), a, "Unidade viva recebe turno no novo round")


func test_individual_turn_signal_emitted():
	watch_signals(bm)
	var a := _make_unit(15, true)
	var b := _make_unit(9, false)
	bm.register_unit(a)
	bm.register_unit(b)
	bm.start_round()
	assert_signal_emitted(bm, "individual_turn_started")
	assert_signal_emitted_with_parameters(bm, "individual_turn_started", [a])


func test_phase_matches_side_of_current_unit():
	var e := _make_unit(30, false)
	bm.register_unit(e)
	bm.start_round()
	assert_eq(bm.current_phase, bm.Phase.ENEMY_TURN,
		"Unidade inimiga mais rápida abre em ENEMY_TURN")
