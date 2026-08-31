extends "res://addons/gut/test.gd"

## Result screen dedicada (molde SoS, AUDIT 7d): vitória/derrota abrem um
## painel com título e recompensas; o sinal battle_ended só dispara quando o
## jogador clica "Continuar" — a campanha avança depois que o resultado é visto.

const ArenaScript := preload("res://scripts/arena_battle.gd")

var _arena: Node
var _sig := {"victory": null, "count": 0}


func before_each() -> void:
	_sig = {"victory": null, "count": 0}
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	if _arena and is_instance_valid(_arena):
		_arena.free()
	_arena = null


func _open() -> Node:
	_arena = add_child_autofree(ArenaScript.new())
	_arena.battle_ended.connect(func(v, _r):
		_sig["victory"] = v
		_sig["count"] += 1)
	return _arena


func test_victory_shows_result_screen_with_rewards_and_waits():
	var arena := _open()
	assert_false(arena.result_visible(), "sem result screen durante a batalha")
	for u in arena.combatants:
		if not u.is_player_side():
			u.current_hp = 0
	arena._check_end()
	assert_true(arena.result_visible(), "result screen dedicada aparece")
	assert_eq(arena.result_title.text, "VITÓRIA!")
	assert_true(arena.result_rewards.text.contains("Soul Éter"), "recompensas exibidas")
	assert_null(_sig["victory"], "battle_ended NÃO dispara antes de Continuar")


func test_continue_press_emits_battle_ended_once():
	var arena := _open()
	for u in arena.combatants:
		if not u.is_player_side():
			u.current_hp = 0
	arena._check_end()
	arena._on_result_continue_pressed()
	assert_eq(int(_sig["count"]), 1, "sinal emitido uma vez após Continuar")
	assert_true(_sig["victory"], "payload carrega a vitória")
	assert_false(arena.result_visible(), "painel fechado após Continuar")


func test_continue_press_is_ignored_without_result():
	var arena := _open()
	arena._on_result_continue_pressed()
	assert_eq(int(_sig["count"]), 0, "Continuar sem result screen não emite sinal")


func test_check_end_does_not_stack_result_screen():
	var arena := _open()
	for u in arena.combatants:
		if not u.is_player_side():
			u.current_hp = 0
	arena._check_end()
	arena._check_end()
	arena._check_end()
	assert_eq(int(_sig["count"]), 0, "sinal ainda pendente")
	assert_true(arena.result_visible(), "painel único mesmo com múltiplos _check_end")


func test_defeat_shows_defeat_screen_and_waits_for_continue():
	var arena := _open()
	for u in arena.combatants:
		if u.is_player_side():
			u.current_hp = 0
	arena._check_end()
	assert_true(arena.result_visible(), "result screen na derrota")
	assert_eq(arena.result_title.text, "DERROTA...")
	assert_null(_sig["victory"], "derrota também espera Continuar")
	arena._on_result_continue_pressed()
	assert_false(_sig["victory"], "payload carrega a derrota")
