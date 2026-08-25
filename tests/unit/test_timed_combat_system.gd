extends "res://addons/gut/test.gd"

## Testes GUT para TimedCombatSystem (Timed Hits & Blocks, GDD v2 §3.1)


# --- Timed Hit grades ---

func test_perfect_attack():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_timing(0.05)
	assert_eq(result.grade, "PERFECT", "0.05s = PERFECT")
	assert_eq(result.multiplier, 1.5, "PERFECT = 1.5x")


func test_great_attack():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_timing(0.15)
	assert_eq(result.grade, "GREAT", "0.15s = GREAT")
	assert_eq(result.multiplier, 1.25, "GREAT = 1.25x")


func test_good_attack():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_timing(0.25)
	assert_eq(result.grade, "GOOD", "0.25s = GOOD")
	assert_eq(result.multiplier, 1.1, "GOOD = 1.1x")


func test_miss_attack():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_timing(0.5)
	assert_eq(result.grade, "MISS", "0.5s = MISS")
	assert_eq(result.multiplier, 0.5, "MISS = 0.5x")


func test_perfect_boundary():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_timing(0.1)
	assert_eq(result.grade, "PERFECT", "0.1s exato = PERFECT")


func test_great_boundary():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_timing(0.2)
	assert_eq(result.grade, "GREAT", "0.2s exato = GREAT")


# --- Timed Block grades ---

func test_perfect_block():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_block_timing(0.03)
	assert_eq(result.grade, "PERFECT", "0.03s = PERFECT block")
	assert_eq(result.reduction, 0.5, "PERFECT block = -50%")


func test_great_block():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_block_timing(0.08)
	assert_eq(result.grade, "GREAT", "0.08s = GREAT block")
	assert_eq(result.reduction, 0.3, "GREAT block = -30%")


func test_good_block():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_block_timing(0.15)
	assert_eq(result.grade, "GOOD", "0.15s = GOOD block")
	assert_eq(result.reduction, 0.1, "GOOD block = -10%")


func test_miss_block():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_block_timing(0.3)
	assert_eq(result.grade, "MISS", "0.3s = MISS block")
	assert_eq(result.reduction, 0.0, "MISS block = sem redução")


# --- apply_block ---

func test_apply_block_perfect():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_block_timing(0.01)
	var final_damage = tc.apply_block(100, result)
	assert_eq(final_damage, 50, "100 dano com PERFECT block = 50")


func test_apply_block_miss():
	var tc = TimedCombatSystem.new()
	var result = tc.resolve_block_timing(0.5)
	var final_damage = tc.apply_block(100, result)
	assert_eq(final_damage, 100, "100 dano com MISS = 100 (sem bloqueio)")


# --- Sinais ---

func test_signal_timed_hit_fires():
	var tc = TimedCombatSystem.new()
	watch_signals(tc)
	tc.resolve_timing(0.1)
	assert_signal_emitted(tc, "timed_hit_resolved", "Sinal deve disparar ao resolver hit")


func test_signal_timed_block_fires():
	var tc = TimedCombatSystem.new()
	watch_signals(tc)
	tc.resolve_block_timing(0.05)
	assert_signal_emitted(tc, "timed_block_resolved", "Sinal deve disparar ao resolver block")
