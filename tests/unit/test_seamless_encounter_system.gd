extends "res://addons/gut/test.gd"

## Testes GUT para SeamlessEncounterSystem (GDD v2 §6.2)


func test_register_enemy():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	assert_eq(ses.get_enemy_count(), 1, "1 inimigo registrado")


func test_unregister_enemy():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.unregister_enemy("e1")
	assert_eq(ses.get_enemy_count(), 0, "0 inimigos após remoção")


func test_player_position_update():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	var result = ses.update_player_position(Vector2i(10, 10))
	assert_eq(result.encountered, false, "Sem encontro a longa distância")


func test_proximity_triggers_chase():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.update_player_position(Vector2i(7, 5))  ## Distância 2 (aggro, não contact)
	var enemies = ses.get_active_enemies()
	assert_eq(enemies[0].state, "chasing", "Inimigo deve perseguir")


func test_contact_triggers_encounter():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	watch_signals(ses)
	ses.update_player_position(Vector2i(5, 5))  ## Posição igual = contato
	assert_signal_emitted(ses, "encounter_started", "Encontro deve iniciar")


func test_no_encounter_while_in_battle():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.register_enemy("e2", Vector2i(5, 5), "orc", 2)
	ses.update_player_position(Vector2i(5, 5))  ## Primeiro encontro
	var result = ses.update_player_position(Vector2i(5, 5))  ## Segundo tentativa
	assert_eq(result.encountered, false, "Não deve encontrar enquanto em batalha")


func test_end_encounter_victory():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.update_player_position(Vector2i(5, 5))
	watch_signals(ses)
	ses.end_encounter(true, {"gold": 50})
	assert_eq(ses.is_in_battle(), false, "Não está mais em batalha")
	assert_signal_emitted(ses, "encounter_ended", "Sinal deve disparar")


func test_end_encounter_defeat():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.update_player_position(Vector2i(5, 5))
	ses.end_encounter(false, {})
	assert_eq(ses.is_in_battle(), false, "Batalha encerrada")


func test_enemy_removed_on_victory():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.update_player_position(Vector2i(5, 5))
	ses.end_encounter(true, {})
	assert_eq(ses.get_enemy_count(), 0, "Inimigo removido após vitória")


func test_enemy_kept_on_defeat():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.update_player_position(Vector2i(5, 5))
	ses.end_encounter(false, {})
	assert_eq(ses.get_enemy_count(), 1, "Inimigo mantido após derrota")


func test_encounter_history():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.update_player_position(Vector2i(5, 5))
	ses.end_encounter(true, {})
	var history = ses.get_encounter_history()
	assert_eq(history.size(), 1, "1 encontro no histórico")
	assert_eq(history[0], "goblin", "Tipo = goblin")


func test_boss_encounter_type():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("boss1", Vector2i(5, 5), "boss_ignis", 10)
	ses.update_player_position(Vector2i(5, 5))
	var encounter = ses.get_current_encounter()
	assert_eq(encounter.type, "boss", "Tipo = boss")


func test_manhattan_distance():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(0, 0), "goblin", 1)
	ses.update_player_position(Vector2i(3, 4))
	## Distância Manhattan = 3 + 4 = 7
	var enemies = ses.get_active_enemies()
	assert_eq(enemies[0].state, "idle", "Longe demais para perseguir")


func test_multiple_enemies():
	var ses = SeamlessEncounterSystem.new()
	ses.register_enemy("e1", Vector2i(5, 5), "goblin", 1)
	ses.register_enemy("e2", Vector2i(8, 8), "orc", 2)
	ses.register_enemy("e3", Vector2i(10, 10), "troll", 3)
	assert_eq(ses.get_enemy_count(), 3, "3 inimigos")


func test_get_encounter_config():
	var ses = SeamlessEncounterSystem.new()
	var config = ses.get_encounter_config()
	assert_eq(config.aggro_range, 2, "Aggro range = 2")
	assert_eq(config.contact_range, 1, "Contact range = 1")
