extends RefCounted
## Interação/seleção do battle_scene (P2 #13d — extração do god file).
## Cliques, seleção de unidade, movimento/ataque com selecionada, timed hit/block
## e menus contextuais. Acessa os membros da cena dona via `battle`.

var battle: Node2D


## Roteamento de input (chamado pelo `_input` da cena).
func handle_event(event: InputEvent) -> void:
	# Timed Block: o clique reativo vale mesmo fora do turno do jogador
	# (a janela abre durante o ENEMY_TURN, quando can_interact é false).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and battle._timed_block_active:
		_resolve_block_input()
		return
	if not battle.can_interact:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click()


func handle_left_click() -> void:
	var mouse_pos = battle.get_global_mouse_position()
	var grid_pos = battle.grid.pixel_to_grid(mouse_pos)

	# Se timed hit está ativo, processar timing
	if battle._timed_hit_active:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - battle._timed_hit_start_time
		var grade = battle.timed_combat.resolve_timing(elapsed)
		_apply_attack_result(battle._timed_hit_target, grade.multiplier, grade.label)
		battle._timed_hit_active = false
		return

	if not BattleManager.is_valid_position(grid_pos):
		return

	var clicked_unit = BattleManager.get_tile_at(grid_pos)

	if clicked_unit and clicked_unit.data and clicked_unit.data.is_player and BattleManager.current_phase == BattleManager.Phase.PLAYER_TURN:
		select_unit(clicked_unit)
		battle.tutorial_system.complete_step("select_unit")
	elif battle.is_unit_selected and battle.selected_unit:
		if not battle.selected_unit.has_moved and battle.grid.movement_tiles.has(grid_pos):
			move_selected_unit(grid_pos)
			battle.tutorial_system.complete_step("move_unit")
		elif not battle.selected_unit.has_acted and battle.grid.attack_tiles.has(grid_pos) and clicked_unit and clicked_unit.data and not clicked_unit.data.is_player:
			attack_with_selected_unit(clicked_unit)
			battle.tutorial_system.complete_step("attack_unit")


func handle_right_click() -> void:
	deselect_unit()


func select_unit(unit: Unit) -> void:
	deselect_unit()
	battle.selected_unit = unit
	battle.is_unit_selected = true

	# Feedback visual
	SoundManager.play_select()
	battle.combat_feedback.flash_unit(unit, Color(1.2, 1.2, 1.5), 0.1)

	show_unit_info(unit)
	show_action_menu(unit)

	if not unit.has_moved:
		battle.grid.show_movement_range(unit, unit.data.move_range)
	if not unit.has_acted:
		battle.grid.show_attack_range(unit, unit.data.attack_range)

	# Kaelen System (§3.4): analisar alvo inimigo selecionado.
	# analyze_target espera um Dictionary, nao o objeto UnitData.
	if unit.data and not unit.data.is_player:
		# WEAKNESS_TABLE é chaveada por tipo de criatura ("Goblin", "Orc", "Cardeal"...).
		# O nome do inimigo ("Lobo Sombrio", "Santo Cardeal") é o que casa por
		# substring no KaelenSystem — melhor que soul_type (raro) ou unit_class (papel).
		var target_data := {
			"name": unit.data.unit_name,
			"type": unit.data.unit_name,
			"hp": unit.data.current_hp,
			"max_hp": unit.data.max_hp,
			"armor": unit.data.defense,
			"morale": 50,
			"attack_range": unit.data.attack_range,
			"locks": [],
			"spell_counter": 0,
		}
		battle.kaelen_system.analyze_target(target_data)


func deselect_unit() -> void:
	battle.selected_unit = null
	battle.is_unit_selected = false
	battle.grid.clear_highlights()
	hide_unit_info()
	hide_action_menu()
	if battle.kaelen_hud_panel and battle.kaelen_hud_panel.visible:
		battle.kaelen_hud_panel.visible = false


func move_selected_unit(grid_pos: Vector2i) -> void:
	if battle.selected_unit and not battle.selected_unit.has_moved:
		# Animação de movimento
		var animator = battle._get_animator(battle.selected_unit)
		if animator:
			animator.play_walk(battle.grid.grid_to_pixel(grid_pos))

		SoundManager.play_step()
		BattleManager.move_unit(battle.selected_unit, grid_pos)
		battle.selected_unit.has_moved = true
		battle.grid.clear_highlights()
		if not battle.selected_unit.has_acted:
			battle.grid.show_attack_range(battle.selected_unit, battle.selected_unit.data.attack_range)


func attack_with_selected_unit(target: Unit) -> void:
	if battle.selected_unit and not battle.selected_unit.has_acted:
		# Iniciar timed hit
		battle._timed_hit_active = true
		battle._timed_hit_start_time = Time.get_ticks_msec() / 1000.0
		battle._timed_hit_target = target

		# Mostrar indicador visual
		battle.combat_feedback.show_status_effect(target.global_position + Vector2(0, -40), "TIMED HIT!")

		# Esperar input do jogador (timer de 0.3s)
		await battle.get_tree().create_timer(TimedCombatSystem.ATTACK_WINDOW).timeout

		# Se jogador não clicou a tempo, aplicar dano sem bônus
		if battle._timed_hit_active:
			_apply_attack_result(target, 1.0, "MISS")


# --- Timed Block: defesa reativa (espelho do timed hit, GDD v2 §3.1) ---

## Chamado pelo BattleManager quando um ataque inimigo mira um aliado jogador:
## abre a janela de 0.2s e aguarda o clique reativo antes do dano ser aplicado.
func _resolve_timed_block(_attacker: Unit, target: Unit) -> float:
	battle._timed_block_active = true
	battle._timed_block_start_time = Time.get_ticks_msec() / 1000.0
	battle._timed_block_reduction = 0.0

	battle.combat_feedback.show_status_effect(target.global_position + Vector2(0, -40), "TIMED BLOCK!")
	SoundManager.play_select()

	# Espera o input do jogador dentro da janela (0.2s) e devolve a redução
	# para o pipeline de dano do BattleManager.
	await battle.get_tree().create_timer(TimedCombatSystem.BLOCK_WINDOW).timeout
	battle._timed_block_active = false
	return battle._timed_block_reduction


## Clique reativo dentro da janela: gradua o timing e trava a redução obtida.
func _resolve_block_input() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - battle._timed_block_start_time
	var result = battle.timed_combat.resolve_block_timing(elapsed)
	battle._timed_block_reduction = battle.timed_combat.get_block_reduction(result)

	battle.combat_feedback.show_status_effect(Vector2(640, 300), "BLOCK " + result.grade)
	if battle._timed_block_reduction > 0.0:
		battle.combat_feedback.shake_light()
		SoundManager.play_hit()


func _apply_attack_result(target: Unit, multiplier: float, grade: String) -> void:
	if not battle.selected_unit or not target:
		return

	# Animação de ataque
	var attacker_animator = battle._get_animator(battle.selected_unit)
	if attacker_animator:
		await attacker_animator.play_attack(target)

	SoundManager.play_hit()
	battle.combat_feedback.shake_light()

	# Aplicar dano com bônus de timing + buffs de cozinha §7.2 via BattleManager
	BattleManager.attack_unit(battle.selected_unit, target, "", "", multiplier * battle._cooking_attack_multiplier(), battle._cooking_defense_bonus())

	# Mostrar grade de timing
	battle.combat_feedback.show_status_effect(target.global_position + Vector2(0, -30), grade)

	# Ganhar Éter por timing perfeito
	if grade == "PERFECT":
		battle.balance_system.apply_action("buff_ally")  # +8 Éter
		battle.update_balance_ui()

	# Animação de dano no alvo
	var target_animator = battle._get_animator(target)
	if target_animator:
		target_animator.play_hit()

	# Ganhar CP por Perfect
	if grade == "PERFECT":
		battle.combo_system.earn_from_timed_hit(grade)
		battle.update_combo_ui()

	battle.selected_unit.has_acted = true
	battle.grid.clear_highlights()
	hide_action_menu()
	deselect_unit()


func show_unit_info(unit: Unit) -> void:
	battle.unit_info_panel.visible = true
	battle.unit_name_label.text = unit.data.unit_name
	battle.unit_hp_label.text = "HP: %d/%d" % [unit.current_hp, unit.data.max_hp]
	battle.unit_class_label.text = unit.data.unit_class


func hide_unit_info() -> void:
	battle.unit_info_panel.visible = false


func show_action_menu(unit: Unit) -> void:
	if not unit.has_moved or not unit.has_acted:
		battle.action_menu.visible = true
		battle.move_button.disabled = unit.has_moved
		battle.attack_button.disabled = unit.has_acted
	else:
		hide_action_menu()


func hide_action_menu() -> void:
	battle.action_menu.visible = false


func _on_move_pressed() -> void:
	if battle.selected_unit and not battle.selected_unit.has_moved:
		battle.grid.show_movement_range(battle.selected_unit, battle.selected_unit.data.move_range)


func _on_attack_pressed() -> void:
	if battle.selected_unit and not battle.selected_unit.has_acted:
		battle.grid.show_attack_range(battle.selected_unit, battle.selected_unit.data.attack_range)


func _on_wait_pressed() -> void:
	if battle.selected_unit:
		battle.selected_unit.has_moved = true
		battle.selected_unit.has_acted = true
		battle.tutorial_system.complete_step("wait_action")
		deselect_unit()
		battle.check_all_units_acted()
