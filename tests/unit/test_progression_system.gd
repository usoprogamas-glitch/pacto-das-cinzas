extends GutTest
## Testes para ProgressionSystem (§8 Progressão Global)
## Valida curva de experiência, avanço de Atos, e integração com CharacterProgression

var progression: ProgressionSystem
var char_progression: CharacterProgression


func before_each() -> void:
	char_progression = CharacterProgression.new()
	progression = ProgressionSystem.new(char_progression)


func after_each() -> void:
	progression = null
	char_progression = null


# === Curva de Experiência ===

func test_xp_curve_increases_exponentially() -> void:
	var xp_level_1 = progression.get_xp_for_level(1)
	var xp_level_10 = progression.get_xp_for_level(10)
	var xp_level_20 = progression.get_xp_for_level(20)

	assert_gt(xp_level_10, xp_level_1, "XP para level 10 deve ser maior que level 1")
	assert_gt(xp_level_20, xp_level_10, "XP para level 20 deve ser maior que level 10")

	# Diferença deve ser exponencial (level 20 > 2x level 10)
	assert_gt(xp_level_20, xp_level_10 * 2, "Curva deve ser exponencial")


func test_initial_level_is_1() -> void:
	assert_eq(progression.get_current_level(), 1, "Nível inicial deve ser 1")


func test_add_experience_increases_level() -> void:
	# Level 1 -> 2 precisa de 100 XP (base * 1^1.5)
	progression.add_experience(100)
	assert_eq(progression.get_current_level(), 2, "Com 100 XP deve estar no level 2")


func test_level_up_multiple_times() -> void:
	# Adicionar XP suficiente para chegar no level 5
	for level in range(1, 6):
		progression.add_experience(progression.get_xp_for_level(level))

	assert_eq(progression.get_current_level(), 6, "Deve estar no level 6")


func test_max_level_is_50() -> void:
	# Adicionar XP massivo
	progression.add_experience(999999999)
	assert_eq(progression.get_current_level(), 50, "Nível máximo deve ser 50")


# === Sistema de Atos ===

func test_initial_act_is_1() -> void:
	assert_eq(progression.current_act, 1, "Ato inicial deve ser 1")


func test_act_info_contains_expected_keys() -> void:
	var act_info = progression.get_current_act_info()
	assert_has(act_info, "name")
	assert_has(act_info, "protagonist_form")
	assert_has(act_info, "memory_percent")
	assert_has(act_info, "focus")


func test_act_1_has_correct_form() -> void:
	var act_info = progression.get_act_info(1)
	assert_eq(act_info["protagonist_form"], "Imp Menor", "Ato 1 deve ter forma Imp Menor")


func test_act_2_has_correct_memory() -> void:
	var act_info = progression.get_act_info(2)
	assert_eq(act_info["memory_percent"], 25, "Ato 2 deve ter 25% de memória")


# === Memória e Avanço de Atos ===

func test_add_memory_increases_total() -> void:
	progression.add_memory(10)
	assert_eq(progression.total_memory, 10, "Memória deve ser 10%")


func test_memory_caps_at_100() -> void:
	progression.add_memory(150)
	assert_eq(progression.total_memory, 100, "Memória deve estar limitada a 100%")


func test_25_percent_memory_unlocks_act_2() -> void:
	watch_signals(progression)
	progression.add_memory(25)

	assert_signal_emitted(progression, "act_unlocked")
	assert_eq(progression.current_act, 2, "25% de memória deve desbloquear Ato 2")


func test_75_percent_memory_unlocks_act_3() -> void:
	watch_signals(progression)
	progression.add_memory(75)

	assert_signal_emitted(progression, "act_unlocked")
	assert_eq(progression.current_act, 3, "75% de memória deve desbloquear Ato 3")


func test_100_percent_memory_unlocks_act_4() -> void:
	watch_signals(progression)
	progression.add_memory(100)

	assert_signal_emitted(progression, "act_unlocked")
	assert_eq(progression.current_act, 4, "100% de memória deve desbloquear Ato 4")


# === Almas Nomeadas ===

func test_add_named_soul_increases_count() -> void:
	progression.add_named_soul()
	assert_eq(progression.named_souls, 1, "Deve ter 1 alma nomeada")


func test_10_named_souls_unlock_act_2() -> void:
	watch_signals(progression)

	for i in range(10):
		progression.add_named_soul()

	# 10 almas permitem unlock de Ato 2
	var can_unlock = progression.try_advance_to_act(2)
	assert_true(can_unlock, "10 almas devem permitir unlock do Ato 2")


func test_named_souls_grant_faith_to_apostles() -> void:
	watch_signals(progression)

	# Adicionar 10 almas (múltiplo de 10 dá fé aos apóstolos)
	for i in range(10):
		progression.add_named_soul()

	assert_signal_emitted(progression, "apostle_faith_gained")


# === Integração com CharacterProgression ===

func test_act_advancement_evolves_protagonist_form() -> void:
	progression.add_memory(25)

	# CharacterProgression deve ter evoluído para Nobre Abissal
	assert_eq(char_progression.protagonist_stats.form, "Nobre Abissal",
		"Protagonista deve evoluir para Nobre Abissal no Ato 2")


func test_level_10_triggers_act_2() -> void:
	# Adicionar XP suficiente para level 10
	for level in range(1, 11):
		progression.add_experience(progression.get_xp_for_level(level))

	# Deve ter tentado avançar para Ato 2
	assert_gte(progression.current_act, 2, "Level 10 deve tentar desbloquear Ato 2")


# === Serialização ===

func test_serialize_preserves_state() -> void:
	progression.add_experience(500)
	progression.add_memory(30)
	progression.add_named_soul()

	var data = progression.serialize()

	assert_has(data, "current_act")
	assert_has(data, "total_memory")
	assert_has(data, "named_souls")
	assert_has(data, "total_experience")
	assert_eq(data["named_souls"], 1)


func test_deserialize_restores_state() -> void:
	var save_data = {
		"current_act": 3,
		"total_memory": 80,
		"named_souls": 150,
		"total_experience": 5000
	}

	progression.deserialize(save_data)

	assert_eq(progression.current_act, 3)
	assert_eq(progression.total_memory, 80)
	assert_eq(progression.named_souls, 150)
	assert_eq(progression.total_experience, 5000)


# === Sumário de Progresso ===

func test_progress_summary_contains_all_info() -> void:
	progression.add_experience(300)
	progression.add_memory(10)

	var summary = progression.get_progress_summary()

	assert_has(summary, "current_act")
	assert_has(summary, "act_name")
	assert_has(summary, "memory_percent")
	assert_has(summary, "named_souls")
	assert_has(summary, "total_xp")
	assert_has(summary, "level")
	assert_has(summary, "protagonist_form")

	assert_eq(summary["total_xp"], 300)
	assert_eq(summary["memory_percent"], 10)
