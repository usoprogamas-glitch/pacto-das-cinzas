extends "res://addons/gut/test.gd"

## Testes GUT para EtherSystem (Éter / Boost de Éter, GDD v2 §3.3).
## Contrato de unidade fake: get_ether() / set_ether(n) / is_alive()


func _make_unit(ether: int = 0, alive: bool = true):
	var unit = RefCounted.new()
	unit.set_script(preload("res://tests/unit/stubs/fake_unit_ether.gd"))
	unit.ether = ether
	unit.alive = alive
	return unit


# --- Gerar Éter ao acertar ---

func test_generate_on_hit_gives_1_charge():
	var ether = EtherSystem.new()
	var unit = _make_unit(0)
	ether.generate_on_hit(unit)
	assert_eq(unit.get_ether(), 1, "Deve gerar 1 carga ao acertar")


func test_generate_does_not_exceed_max():
	var ether = EtherSystem.new()
	var unit = _make_unit(3)
	var result = ether.generate_on_hit(unit)
	assert_false(result, "Não deve gerar quando já está no máximo")
	assert_eq(unit.get_ether(), 3, "Deve permanecer no máximo (3)")


func test_generate_ignores_dead_unit():
	var ether = EtherSystem.new()
	var unit = _make_unit(0, false)
	var result = ether.generate_on_hit(unit)
	assert_false(result, "Unidade morta não gera Éter")


func test_generate_ignores_null():
	var ether = EtherSystem.new()
	var result = ether.generate_on_hit(null)
	assert_false(result, "Null não gera Éter")


# --- Regeneração no início do turno ---

func test_regen_turn_start_gives_1_charge():
	var ether = EtherSystem.new()
	var unit = _make_unit(0)
	ether.regen_turn_start(unit)
	assert_eq(unit.get_ether(), 1, "Regen deve dar 1 carga")


func test_regen_does_not_exceed_max():
	var ether = EtherSystem.new()
	var unit = _make_unit(2)
	ether.regen_turn_start(unit)
	assert_eq(unit.get_ether(), 3, "Não deve passar de 3")


func test_regen_skips_when_already_max():
	var ether = EtherSystem.new()
	var unit = _make_unit(3)
	var result = ether.regen_turn_start(unit)
	assert_false(result, "Não deve regenerar quando já está no máximo")


# --- Gastar Éter ---

func test_spend_reduces_charges():
	var ether = EtherSystem.new()
	var unit = _make_unit(3)
	var spent = ether.spend(unit, 1)
	assert_eq(spent, 1, "Deve gastar 1 carga")
	assert_eq(unit.get_ether(), 2, "Deve restar 2")


func test_spend_cannot_go_below_zero():
	var ether = EtherSystem.new()
	var unit = _make_unit(1)
	var spent = ether.spend(unit, 5)
	assert_eq(spent, 1, "Deve gastar apenas o disponível")
	assert_eq(unit.get_ether(), 0, "Não deve ficar negativo")


func test_spend_zero_returns_zero():
	var ether = EtherSystem.new()
	var unit = _make_unit(2)
	var spent = ether.spend(unit, 0)
	assert_eq(spent, 0, "Gastar 0 retorna 0")


func test_spend_all():
	var ether = EtherSystem.new()
	var unit = _make_unit(3)
	var spent = ether.spend(unit, 3)
	assert_eq(spent, 3, "Deve gastar todas as 3 cargas")
	assert_eq(unit.get_ether(), 0, "Deve ficar sem Éter")


func test_spend_ignores_dead_unit():
	var ether = EtherSystem.new()
	var unit = _make_unit(2, false)
	var spent = ether.spend(unit, 1)
	assert_eq(spent, 0, "Unidade morta não gasta Éter")


# --- Multiplicadores ---

func test_physical_multiplier_no_boost():
	var ether = EtherSystem.new()
	assert_eq(ether.get_physical_multiplier(0), 1.0, "Sem boost = 1.0x")


func test_physical_multiplier_1_charge():
	var ether = EtherSystem.new()
	assert_eq(ether.get_physical_multiplier(1), 1.3, "1 carga = 1.3x")


func test_physical_multiplier_3_charges():
	var ether = EtherSystem.new()
	assert_eq(ether.get_physical_multiplier(3), 1.9, "3 cargas = 1.9x")


func test_magic_multiplier_no_boost():
	var ether = EtherSystem.new()
	assert_eq(ether.get_magic_multiplier(0), 1.0, "Sem boost = 1.0x")


func test_magic_multiplier_1_charge():
	var ether = EtherSystem.new()
	assert_eq(ether.get_magic_multiplier(1), 1.5, "1 carga = 1.5x")


func test_magic_multiplier_2_charges():
	var ether = EtherSystem.new()
	assert_eq(ether.get_magic_multiplier(2), 2.0, "2 cargas = 2.0x")


func test_magic_multiplier_3_charges():
	var ether = EtherSystem.new()
	assert_eq(ether.get_magic_multiplier(3), 2.5, "3 cargas = 2.5x")


# --- Sinais ---

func test_signal_ether_changed_fires():
	var ether = EtherSystem.new()
	var unit = _make_unit(0)
	watch_signals(ether)
	ether.generate_on_hit(unit)
	assert_signal_emitted(ether, "ether_changed", "Sinal ether_changed deve disparar ao gerar")


func test_signal_ether_spent_fires():
	var ether = EtherSystem.new()
	var unit = _make_unit(2)
	watch_signals(ether)
	ether.spend(unit, 1)
	assert_signal_emitted(ether, "ether_spent", "Sinal ether_spent deve disparar ao gastar")


# --- Round end regen ---

func test_regen_round_end_all_living_units():
	var ether = EtherSystem.new()
	var u1 = _make_unit(1)
	var u2 = _make_unit(2)
	var dead = _make_unit(3, false)
	ether.regen_round_end([u1, u2, dead])
	assert_eq(u1.get_ether(), 2, "u1 deve regenerar 1 (1->2)")
	assert_eq(u2.get_ether(), 3, "u2 deve regenerar 1 (2->3, cap)")
	assert_eq(dead.get_ether(), 3, "Dead não deve mudar (ignorado)")
