extends "res://addons/gut/test.gd"

## QuestSystem data-driven: add idempotente, complete idempotente, log, sinais.

const QuestLib := preload("res://scripts/quest_system.gd")

var qs


func before_each() -> void:
	qs = QuestLib.new()


func after_each() -> void:
	qs = null


func test_add_quest_idempotent():
	watch_signals(qs)
	assert_true(qs.add("fronteira_liberdade"), "1ª add: nova")
	assert_false(qs.add("fronteira_liberdade"), "2ª add: idempotente")
	assert_signal_emit_count(qs, "quest_added", 1)
	assert_true(qs.is_active("fronteira_liberdade"))


func test_unknown_quest_rejected():
	assert_false(qs.add("quest_fantasma"), "quest inexistente recusada")
	assert_false(qs.is_active("quest_fantasma"))


func test_complete_pays_once_and_emits_once():
	watch_signals(qs)
	qs.add("fronteira_liberdade")
	assert_true(qs.complete("fronteira_liberdade"), "1ª conclusão")
	assert_false(qs.complete("fronteira_liberdade"), "2ª conclusão ignorada")
	assert_signal_emit_count(qs, "quest_completed", 1)
	assert_true(qs.is_completed("fronteira_liberdade"))
	assert_eq(qs.get_reward_gold("fronteira_liberdade"), 15, "ouro da recompensa")


func test_log_reflects_state():
	qs.add("ignis_caido")
	qs.add("provisoes_sobrevivente")
	var log: Array = qs.get_log()
	assert_eq(log.size(), 2, "duas quests no log")
	qs.complete("provisoes_sobrevivente")
	var done_count := 0
	for q: Dictionary in qs.get_log():
		if bool(q["done"]):
			done_count += 1
	assert_eq(done_count, 1, "uma concluída no log")
