extends "res://addons/gut/test.gd"

## Sistema de diálogo data-driven (SoS): páginas, first/repeat, sinais.

const DialogueLib := preload("res://scripts/dialogue_system.gd")

var dlg


func before_each() -> void:
	dlg = DialogueLib.new()


func after_each() -> void:
	dlg = null


func test_unknown_npc_rejected():
	assert_false(dlg.start("npc_inexistente"), "NPC sem diálogo recusado")


func test_first_dialogue_has_pages_and_signals():
	watch_signals(dlg)
	assert_true(dlg.start("brugaves_fronteira", false), "diálogo inicia")
	assert_true(dlg.is_active(), "ativo após start")
	assert_signal_emitted(dlg, "dialogue_started")
	assert_eq(dlg.get_npc_name(), "Brugaves")
	# Consome todas as páginas
	var pages := 1
	while dlg.advance():
		pages += 1
	assert_gt(pages, 2, "diálogo first tem várias páginas (lore GDD)")
	assert_signal_emitted(dlg, "dialogue_ended")
	assert_false(dlg.is_active(), "inativo no fim")


func test_repeat_dialogue_shorter_than_first():
	dlg.start("brugaves_fronteira", false)
	var first_pages := 1
	while dlg.advance():
		first_pages += 1
	dlg = DialogueLib.new()
	dlg.start("brugaves_fronteira", true)  # já viu o first
	var repeat_pages := 1
	while dlg.advance():
		repeat_pages += 1
	assert_lt(repeat_pages, first_pages, "repeat é mais curto que o first")


func test_advance_without_start_returns_false():
	assert_false(dlg.advance(), "advance sem start é no-op")
