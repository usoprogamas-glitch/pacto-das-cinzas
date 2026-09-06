extends RefCounted
## Fluxo de batalha/resultado do battle_scene (P2 #13c — extração do god file).
## Turnos/fases, eventos de unidade (movida/atacou/morreu), fim de batalha,
## tela de vitória/derrota, progressão persistida e destinos pós-vitória.
## Acessa os membros da cena dona via `battle`.

var battle: Node2D


func check_all_units_acted() -> void:
	for unit in BattleManager.player_units:
		if not unit.has_acted or not unit.has_moved:
			return
	battle.tutorial_system.complete_step("end_turn")
	BattleManager.end_player_turn()


func _on_phase_changed(phase: String) -> void:
	battle.phase_label.text = "FASE: " + phase
	battle.can_interact = (phase == "PLAYER_TURN")


func _on_turn_started(_unit: Unit) -> void:
	battle.turn_label.text = "Turno: %d" % BattleManager.turn_count
	battle.battle_stats.turns = BattleManager.turn_count
	# Atualizar UI dos sistemas a cada turno
	battle.update_combo_ui()
	battle.update_balance_ui()
	# Buffs de cozinha §7.2 decaem a cada turno; expirados viram toast
	if battle.cooking_system:
		for buff_name: String in battle.cooking_system.tick_bonuses():
			battle.combat_feedback.show_status_effect(Vector2(640, 300), "BUFF EXPIRADO: " + buff_name)


func _on_unit_moved(unit: Unit, _from: Vector2i, to: Vector2i) -> void:
	unit.position = battle.grid.grid_to_pixel(to)


func _on_unit_attacked(attacker: Unit, target: Unit, damage: int) -> void:
	# Feedback visual de dano
	var target_pos = target.global_position + Vector2(0, -20)
	battle.combat_feedback.show_damage_number(target_pos, damage)
	battle.combat_feedback.spawn_hit_particles(target.global_position)

	# Atualizar stats
	if attacker.data and attacker.data.is_player:
		battle.battle_stats.total_damage += damage
	else:
		battle.battle_stats.damage_taken += damage

		# Atualizar HP bar
		var hp_bar = target.get_node("HPBar") if target.has_node("HPBar") else null
		if hp_bar:
			hp_bar.value = target.current_hp

	# Flash de dano
	battle.combat_feedback.flash_unit(target, Color(2, 0.5, 0.5), 0.1)


func _on_unit_died(unit: Unit) -> void:
	# Animação de morte
	var animator = battle._get_animator(unit)
	if animator:
		await animator.play_death()

	SoundManager.play_death()
	battle.combat_feedback.shake_medium()

	if unit.data and not unit.data.is_player:
		battle.battle_stats.enemies_defeated += 1
		var soul_type = unit.data.soul_type if unit.data else ""
		if soul_type != "":
			battle.captured_souls.add(soul_type, unit.data.unit_name)

	# Verificar vitória
	check_battle_end()


func check_battle_end() -> void:
	if BattleManager.player_units.size() == 0:
		BattleManager.battle_lost.emit()
	elif BattleManager.enemy_units.size() == 0:
		BattleManager.battle_won.emit()


func _on_battle_won() -> void:
	_commit_progression()  # persiste progresso da batalha no GameManager antes de sair
	battle.can_interact = false

	# Fix: soul_ether e souls_named nunca chegavam ao result screen antes.
	battle.battle_stats["soul_ether"] = BattleManager.soul_ether
	if battle.captured_souls.has_captured():
		battle.battle_stats["souls_named"] += battle.captured_souls.souls.size()

	# Campanha: boss encerra o ato; estágio normal avança o estágio — ambos persistem.
	if GameManager and GameManager.campaign_system:
		if GameManager.campaign_system.is_act_boss_stage():
			_on_boss_stage_cleared()
		else:
			GameManager.campaign_system.advance_stage()
			if GameManager.has_method("save_game"):
				GameManager.save_game()

	# Efeitos visuais
	await battle.screen_effects.flash_white()
	battle.combat_feedback.spawn_level_up_effect(Vector2(640, 360))

	# Mostrar tela de vitória
	await battle.get_tree().create_timer(1.0).timeout
	await _maybe_show_naming()
	show_victory_screen()


func _on_boss_stage_cleared() -> void:
	# Called ONLY when an act-boss stage is won: advance act + persist.
	if not GameManager or not GameManager.campaign_system:
		return
	GameManager.campaign_system.complete_act()
	if GameManager.has_method("save_game"):
		GameManager.save_game()


func _maybe_show_naming() -> void:
	# Guarded seam: no-op when no NamingSystem / no captured souls,
	# so headless tests calling _on_battle_won are unaffected.
	if not GameManager or not GameManager.naming_system:
		return
	if not battle.captured_souls.has_captured():
		return
	var dialog = load("res://scenes/naming_ui.tscn").instantiate()
	battle.add_child(dialog)
	var types: Array[String] = []
	for s in battle.captured_souls.souls:
		types.append(s["type"])
	dialog.populate_soul_list(types)

	# Kaelen System (§3.4): analisar monstros selvagens capturados para preview de evolução.
	# O resultado (analysis) não é usado ainda — só a chamada garante a integração.
	for s in battle.captured_souls.souls:
		var monster_data = {"type": s["type"], "name": s["display_name"]}
		battle.kaelen_system.analyze_wild_monster(monster_data)

	dialog.soul_named.connect(func(soul_type: String, custom_name: String) -> void:
		if GameManager and GameManager.naming_system:
			GameManager.naming_system.name_soul(soul_type, custom_name)
			if GameManager.faith_system:
				GameManager.faith_system.register_apostle(custom_name)
	)
	await dialog.back_pressed
	dialog.queue_free()
	battle.captured_souls.clear()


func _on_battle_lost() -> void:
	battle.can_interact = false

	# Efeitos visuais
	await battle.screen_effects.flash_red()
	battle.screen_effects.slow_motion(0.3, 1.0)

	# Mostrar tela de derrota
	await battle.get_tree().create_timer(1.5).timeout
	show_defeat_screen()


func _commit_progression() -> void:
	# autoload ausente em teste isolado → no-op seguro
	if not GameManager or not battle.progression_system:
		return
	var gm_prog: ProgressionSystem = GameManager.progression_system
	if not gm_prog:
		return
	# Transferir o acumulado da batalha para o sistema persistente do save
	if battle.progression_system.total_memory > 0:
		gm_prog.add_memory(battle.progression_system.total_memory)
	if battle.progression_system.total_experience > 0:
		gm_prog.add_experience(battle.progression_system.total_experience)
	for i in battle.progression_system.named_souls:
		gm_prog.add_named_soul()
	# Fé: cada vitória fortalece o pacto — todos os apóstolos registrados ganham lealdade
	# (reusa add_faith, que emite faith_changed/faith_level_up; antes a fé era estática)
	var faith: FaithSystem = GameManager.faith_system
	if faith:
		for apostle in faith.get_all_apostles():
			faith.add_faith(apostle, 10)


func _on_soul_ether_gained(amount: int) -> void:
	battle.soul_ether_label.text = "Soul Éter: %d" % BattleManager.soul_ether
	battle.combat_feedback.show_status_effect(Vector2(640, 100), "Soul Éter +%d" % amount)


func show_victory_screen() -> void:
	# Criar tela de vitória dinamicamente
	var result_screen = load("res://scenes/battle_result_screen.tscn").instantiate()
	battle.add_child(result_screen)
	result_screen.show_victory(battle.battle_stats)
	result_screen.restart_pressed.connect(_on_restart)
	result_screen.menu_pressed.connect(_on_menu)
	result_screen.continue_pressed.connect(_on_continue)


func show_defeat_screen() -> void:
	var result_screen = load("res://scenes/battle_result_screen.tscn").instantiate()
	battle.add_child(result_screen)
	result_screen.show_defeat(battle.battle_stats)
	result_screen.restart_pressed.connect(_on_restart)
	result_screen.menu_pressed.connect(_on_menu)


func _on_restart() -> void:
	battle.get_tree().reload_current_scene()


func _on_menu() -> void:
	SceneManager.change_scene("main_menu")


func _on_continue() -> void:
	# Fluxo linear (molde SoS): "Continuar" entra na EXPLORAÇÃO do próximo
	# estágio; cutscene/epílogo rotas pela mesma porta.
	GameManager.sync_current_map_from_campaign()
	SceneManager.change_scene(_get_post_victory_destination())


# Destino pós-vitória (fluxo linear): campanha completa → epílogo; abertura de
# ato pendente → cutscene do ato; senão a EXPLORAÇÃO do próximo estágio.
func _get_post_victory_destination() -> String:
	if GameManager and GameManager.campaign_system:
		if GameManager.campaign_system.is_game_complete():
			return "epilogue"
		if GameManager.campaign_system.has_pending_act_intro():
			return "act_cutscene"
	return "explore"
