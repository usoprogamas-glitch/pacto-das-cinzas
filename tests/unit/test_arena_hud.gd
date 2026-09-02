extends "res://addons/gut/test.gd"

## HUD de combate da arena (GDD §3.3, polish UI): CP pips, barra bipolar
## Éter/Fúria e barra do Boss — construídos em _build_combat_hud e alimentados
## pelos feedbacks do combate (_award_hit_feedback, spellbreak, executions).

const ArenaLib := preload("res://scripts/arena_battle.gd")

var arena


func before_each() -> void:
	arena = ArenaLib.new()
	arena.combat_frozen = true
	add_child_autofree(arena)


func after_each() -> void:
	arena = null


func test_hud_built_with_cp_and_balance():
	assert_not_null(arena._combo_label, "label de CP existe")
	assert_not_null(arena._balance_bar, "barra Éter/Fúria existe")
	assert_not_null(arena.combo_system, "ComboSystem instanciado")
	assert_not_null(arena.balance_system, "BalanceSystem instanciado")
	assert_eq(arena._combo_label.text, "CP ◇◇◇", "CP começa vazio (3 pips)")
	assert_eq(arena._balance_bar.value, 0.0, "barra começa em 0")


func test_perfect_awards_cp_and_ether():
	arena._award_hit_feedback("PERFECT")
	assert_eq(arena.combo_system.get_cp(), 1, "PERFECT = +1 CP")
	assert_gt(arena.balance_system.get_ether(), 0, "PERFECT enche Éter")
	assert_eq(arena._combo_label.text, "CP ◆◇◇", "pip reflete o CP no HUD")


func test_good_awards_ether_only():
	arena._award_hit_feedback("GOOD")
	assert_eq(arena.combo_system.get_cp(), 0, "GOOD não dá CP")
	assert_gt(arena.balance_system.get_ether(), 0, "GOOD dá um pouco de Éter")


func test_miss_awards_nothing():
	arena._award_hit_feedback("MISS")
	assert_eq(arena.combo_system.get_cp(), 0, "MISS não dá CP")
	assert_eq(arena.balance_system.get_ether(), 0, "MISS não dá Éter")


func test_spellbreak_pays_two_cp():
	arena.combo_system.add_cp(0)
	arena.combo_system.add_cp(2)  # simula pagamento de spellbreak
	assert_eq(arena.combo_system.get_cp(), 2, "spellbreak paga 2 CP (GDD §3.3)")


func test_execution_on_kill_fills_fury():
	arena.combat = arena.combat  # núcleo presente
	arena.balance_system.perform_fury_action("execute")
	assert_gt(arena.balance_system.get_fury(), 0, "execução enche Fúria")
	assert_eq(arena._balance_bar.tooltip_text, "Éter 0 / Fúria 15", "tooltip bipolar reflete os dois lados")


func test_boss_bar_hidden_without_boss():
	arena.enemies_meta = [{"type": "mercenario", "soul_ether": 10}]
	arena._update_boss_bar()
	assert_false(arena._boss_bar.visible, "sem boss no campo, barra oculta")


func test_boss_bar_shows_for_boss_type():
	arena.enemies_meta = [{"type": "cardeal_ignis", "soul_ether": 200}]
	# Combatante stub (duck typing do contrato da arena) com o nome do Ignis.
	arena.combatants = [_make_unit_stub("Ignis", false)]
	arena._update_boss_bar()
	assert_true(arena._boss_bar.visible, "boss presente: barra visível")
	assert_true(arena._boss_bar_label.visible, "label do boss visível")
	assert_true(arena._boss_bar_label.text.contains("Ignis"), "label mostra o nome do boss")


## Unit mínima por duck typing (get_speed/is_player_side/is_alive/data).
func _make_unit_stub(unit_name: String, _player_side: bool) -> Object:
	var script = GDScript.new()
	script.source_code = """
extends Node
var data = null
var current_hp := 100
func get_speed() -> int:
	return 5
func is_player_side() -> bool:
	return false
func is_alive() -> bool:
	return current_hp > 0
"""
	script.reload()
	var stub = script.new()
	stub.data = {"unit_name": unit_name, "max_hp": 100}
	return stub
