extends RefCounted
## Construtores de UI do battle_scene (P2 #13b — extração do god file).
## Monta os painéis: Kaelen HUD (§3.4), Combo/Eter (§3), Boss HP (§5),
## Progressão (§8), Painel de Ações (§6), Forja (§7) e Cozinha (§7.2).
## Escreve os membros de referência na cena dona via `battle`.

var battle: Node2D


func setup_ui() -> void:
	battle.phase_label.text = "FASE: JOGADOR"
	battle.turn_label.text = "Turno: 1"
	battle.soul_ether_label.text = "Soul Éter: 0"
	battle.unit_info_panel.visible = false
	battle.action_menu.visible = false

	battle.move_button.pressed.connect(battle._on_move_pressed)
	battle.attack_button.pressed.connect(battle._on_attack_pressed)
	battle.wait_button.pressed.connect(battle._on_wait_pressed)

	# UI de Combo Points (canto inferior esquerdo)
	_create_combo_ui()

	# UI de Éter/Fúria (canto inferior direito)
	_create_balance_ui()

	# UI de Boss HP (topo)
	_create_boss_ui()

	# HUD de Progressão §6-8 (top-right)
	_create_progression_hud()
	battle._update_progression_hud()

	# Painel de ações §6-7 (logo abaixo do HUD de progressão)
	_create_actions_panel()

	# Kaelen HUD (§3.4) - análise preditiva de alvos
	_create_kaelen_hud()


func _create_kaelen_hud() -> void:
	var panel = PanelContainer.new()
	panel.position = Vector2(850, 10)
	panel.size = Vector2(420, 300)
	panel.visible = false
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	panel_style.border_color = Color(0.2, 0.4, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	battle.ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.add_theme_constant_override("margin_left", 10)
	vbox.add_theme_constant_override("margin_right", 10)
	vbox.add_theme_constant_override("margin_top", 10)
	vbox.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "KALEN — INTERFACE COGNITIVA"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(title)

	# Separator
	var sep1 = HSeparator.new()
	sep1.add_theme_color_override("font_color", Color(0.2, 0.4, 0.6))
	vbox.add_child(sep1)

	# Vetor Biológico
	var bio_title = Label.new()
	bio_title.text = "VETOR BIOLÓGICO"
	bio_title.add_theme_font_size_override("font_size", 12)
	bio_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(bio_title)

	battle.kaelen_bio_weaknesses = Label.new()
	battle.kaelen_bio_weaknesses.text = "Fraquezas: —"
	battle.kaelen_bio_weaknesses.add_theme_font_size_override("font_size", 11)
	battle.kaelen_bio_weaknesses.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_bio_weaknesses)

	battle.kaelen_bio_fatigue = Label.new()
	battle.kaelen_bio_fatigue.text = "Fadiga: —"
	battle.kaelen_bio_fatigue.add_theme_font_size_override("font_size", 11)
	battle.kaelen_bio_fatigue.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_bio_fatigue)

	battle.kaelen_bio_armor = Label.new()
	battle.kaelen_bio_armor.text = "Armadura: —"
	battle.kaelen_bio_armor.add_theme_font_size_override("font_size", 11)
	battle.kaelen_bio_armor.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_bio_armor)

	# Vetor Psicológico
	var psycho_title = Label.new()
	psycho_title.text = "VETOR PSICOLÓGICO"
	psycho_title.add_theme_font_size_override("font_size", 12)
	psycho_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	vbox.add_child(psycho_title)

	battle.kaelen_psy_morale = Label.new()
	battle.kaelen_psy_morale.text = "Moral: —"
	battle.kaelen_psy_morale.add_theme_font_size_override("font_size", 11)
	battle.kaelen_psy_morale.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_psy_morale)

	battle.kaelen_psy_flee = Label.new()
	battle.kaelen_psy_flee.text = "Fuga: —"
	battle.kaelen_psy_flee.add_theme_font_size_override("font_size", 11)
	battle.kaelen_psy_flee.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_psy_flee)

	# Vetor Tático
	var tactical_title = Label.new()
	tactical_title.text = "VETOR TÁTICO"
	tactical_title.add_theme_font_size_override("font_size", 12)
	tactical_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	vbox.add_child(tactical_title)

	battle.kaelen_tac_locks = Label.new()
	battle.kaelen_tac_locks.text = "Locks: —"
	battle.kaelen_tac_locks.add_theme_font_size_override("font_size", 11)
	battle.kaelen_tac_locks.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_tac_locks)

	battle.kaelen_tac_threat = Label.new()
	battle.kaelen_tac_threat.text = "Ameaça: —"
	battle.kaelen_tac_threat.add_theme_font_size_override("font_size", 11)
	battle.kaelen_tac_threat.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_tac_threat)

	battle.kaelen_tac_range = Label.new()
	battle.kaelen_tac_range.text = "Alcance: —"
	battle.kaelen_tac_range.add_theme_font_size_override("font_size", 11)
	battle.kaelen_tac_range.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(battle.kaelen_tac_range)

	# Separator
	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("font_color", Color(0.2, 0.4, 0.6))
	vbox.add_child(sep2)

	# Sugestões de Lock Break
	battle.kaelen_suggestions_label = Label.new()
	battle.kaelen_suggestions_label.text = "SUGESTÕES: —"
	battle.kaelen_suggestions_label.add_theme_font_size_override("font_size", 11)
	battle.kaelen_suggestions_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4))
	vbox.add_child(battle.kaelen_suggestions_label)

	battle.kaelen_hud_panel = panel


func _create_combo_ui() -> void:
	# Painel de Combo Points (canto inferior esquerdo)
	var panel = PanelContainer.new()
	panel.position = Vector2(10, 650)
	panel.size = Vector2(160, 70)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	panel_style.border_color = Color(0.4, 0.35, 0.15)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	battle.ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	battle.combo_label = Label.new()
	battle.combo_label.text = "CP: 0/3"
	battle.combo_label.add_theme_font_size_override("font_size", 14)
	battle.combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	battle.combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	battle.combo_label.add_theme_constant_override("shadow_offset_x", 2)
	battle.combo_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(battle.combo_label)

	# Dots visuais para CP (maiores, com glow)
	var dots_container = HBoxContainer.new()
	dots_container.add_theme_constant_override("separation", 6)
	vbox.add_child(dots_container)

	for i in range(3):
		var dot = ColorRect.new()
		dot.size = Vector2(20, 20)
		dot.color = Color(0.2, 0.2, 0.2)
		dots_container.add_child(dot)
		battle.combo_dots.append(dot)


func _create_balance_ui() -> void:
	# Painel de Éter/Fúria (canto inferior direito)
	var panel = PanelContainer.new()
	panel.position = Vector2(1100, 650)
	panel.size = Vector2(170, 70)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	panel_style.border_color = Color(0.3, 0.5, 0.7)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	battle.ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	battle.balance_label = Label.new()
	battle.balance_label.text = "Neutro"
	battle.balance_label.add_theme_font_size_override("font_size", 13)
	battle.balance_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	battle.balance_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	battle.balance_label.add_theme_constant_override("shadow_offset_x", 2)
	battle.balance_label.add_theme_constant_override("shadow_offset_y", 2)
	battle.balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(battle.balance_label)

	battle.balance_bar = ProgressBar.new()
	battle.balance_bar.size = Vector2(150, 16)
	battle.balance_bar.max_value = 100
	battle.balance_bar.value = 50
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.15, 0.15)
	bar_bg.set_corner_radius_all(4)
	battle.balance_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.5, 0.5, 0.5)
	bar_fill.set_corner_radius_all(4)
	battle.balance_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(battle.balance_bar)


func _create_boss_ui() -> void:
	# Painel de Boss HP (topo central, inicialmente oculto)
	battle.boss_panel = PanelContainer.new()
	battle.boss_panel.position = Vector2(340, 8)
	battle.boss_panel.size = Vector2(600, 60)
	battle.boss_panel.visible = false
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.02, 0.02, 0.9)
	panel_style.border_color = Color(0.7, 0.15, 0.1)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	battle.boss_panel.add_theme_stylebox_override("panel", panel_style)
	battle.ui_layer.add_child(battle.boss_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	battle.boss_panel.add_child(vbox)

	battle.boss_name_label = Label.new()
	battle.boss_name_label.text = "Boss"
	battle.boss_name_label.add_theme_font_size_override("font_size", 16)
	battle.boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
	battle.boss_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	battle.boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
	battle.boss_name_label.add_theme_constant_override("shadow_offset_y", 2)
	battle.boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(battle.boss_name_label)

	battle.boss_hp_bar = ProgressBar.new()
	battle.boss_hp_bar.size = Vector2(580, 20)
	battle.boss_hp_bar.max_value = 500
	battle.boss_hp_bar.value = 500
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.05, 0.05)
	hp_bg.set_corner_radius_all(3)
	battle.boss_hp_bar.add_theme_stylebox_override("background", hp_bg)
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.85, 0.15, 0.1)
	hp_fill.set_corner_radius_all(3)
	battle.boss_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	vbox.add_child(battle.boss_hp_bar)


func _create_progression_hud() -> void:
	battle.progression_hud = PanelContainer.new()
	battle.progression_hud.position = Vector2(960, 8)
	battle.progression_hud.size = Vector2(310, 70)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.09, 0.88)
	style.border_color = Color(0.25, 0.4, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	battle.progression_hud.add_theme_stylebox_override("panel", style)
	battle.ui_layer.add_child(battle.progression_hud)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	battle.progression_hud.add_child(vbox)

	# Linha 1: Ato + Memória
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 16)
	vbox.add_child(row1)

	var act_label = Label.new()
	act_label.name = "ActLabel"
	act_label.text = "ATO 1"
	act_label.add_theme_font_size_override("font_size", 12)
	act_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	act_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	act_label.add_theme_constant_override("shadow_offset_x", 1)
	act_label.add_theme_constant_override("shadow_offset_y", 1)
	row1.add_child(act_label)

	var mem_label = Label.new()
	mem_label.name = "MemLabel"
	mem_label.text = "MEM 0%"
	mem_label.add_theme_font_size_override("font_size", 12)
	mem_label.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0))
	mem_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	mem_label.add_theme_constant_override("shadow_offset_x", 1)
	mem_label.add_theme_constant_override("shadow_offset_y", 1)
	row1.add_child(mem_label)

	var soul_label = Label.new()
	soul_label.name = "SoulLabel"
	soul_label.text = "ALMAS 0"
	soul_label.add_theme_font_size_override("font_size", 12)
	soul_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.9))
	soul_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	soul_label.add_theme_constant_override("shadow_offset_x", 1)
	soul_label.add_theme_constant_override("shadow_offset_y", 1)
	row1.add_child(soul_label)

	# Linha 2: XP + Forma atual
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	vbox.add_child(row2)

	var xp_label = Label.new()
	xp_label.name = "XPLabel"
	xp_label.text = "XP 0"
	xp_label.add_theme_font_size_override("font_size", 12)
	xp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	xp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	xp_label.add_theme_constant_override("shadow_offset_x", 1)
	xp_label.add_theme_constant_override("shadow_offset_y", 1)
	row2.add_child(xp_label)

	var form_label = Label.new()
	form_label.name = "FormLabel"
	form_label.text = "FORMA: Imp Menor"
	form_label.add_theme_font_size_override("font_size", 12)
	form_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.7))
	form_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	form_label.add_theme_constant_override("shadow_offset_x", 1)
	form_label.add_theme_constant_override("shadow_offset_y", 1)
	row2.add_child(form_label)


func _create_actions_panel() -> void:
	battle.actions_panel = PanelContainer.new()
	battle.actions_panel.position = Vector2(960, 82)
	battle.actions_panel.size = Vector2(310, 140)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.09, 0.88)
	style.border_color = Color(0.6, 0.45, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	battle.actions_panel.add_theme_stylebox_override("panel", style)
	battle.ui_layer.add_child(battle.actions_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	battle.actions_panel.add_child(vbox)

	var title = Label.new()
	title.text = "AÇÕES §6"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	_add_action_button(grid, "Acampar", battle._on_camp_pressed)
	_add_action_button(grid, "Cozinhar", battle._on_cook_pressed)
	_add_action_button(grid, "Taberna", battle._on_tavern_pressed)
	_add_action_button(grid, "Travessia", battle._on_traverse_pressed)
	_add_action_button(grid, "Forja", battle._on_forge_pressed)
	_add_action_button(grid, "Combo", battle._on_combo_pressed)


func _add_action_button(parent: Node, label_text: String, handler: Callable) -> void:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(140, 30)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14)
	style.border_color = Color(0.5, 0.45, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	btn.pressed.connect(func() -> void:
		if SoundManager:
			SoundManager.play_sfx("click")
		handler.call())
	parent.add_child(btn)


func _build_forge_panel() -> void:
	battle._forge_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	style.border_color = Color(0.5, 0.45, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	battle._forge_panel.add_theme_stylebox_override("panel", style)
	battle._forge_panel.position = Vector2(400, 200)
	battle._forge_panel.custom_minimum_size = Vector2(480, 0)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	battle._forge_panel.add_child(vbox)
	var title := Label.new()
	title.text = "FORJA — escolha o equipamento"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vbox.add_child(title)
	var equipment = battle._sync_equipment()
	for equipment_id: String in equipment.EQUIPMENT:
		var item: Dictionary = equipment.get_equipment(equipment_id)
		var check: Dictionary = equipment.can_craft(equipment_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := Label.new()
		var cost_parts := PackedStringArray()
		for cost_key: String in item["cost"]:
			cost_parts.append("%d %s" % [int(item["cost"][cost_key]), cost_key])
		var cost_text := ", ".join(cost_parts)
		info.text = "%s  [%s]\nCusto: %s" % [item["name"], item["slot"], cost_text]
		info.add_theme_font_size_override("font_size", 13)
		info.custom_minimum_size = Vector2(300, 0)
		row.add_child(info)
		var btn := Button.new()
		if check.can:
			btn.text = "Forjar"
		else:
			btn.text = check.reason
			btn.disabled = true
		btn.custom_minimum_size = Vector2(150, 28)
		btn.pressed.connect(battle._on_forge_item_pressed.bind(equipment_id))
		row.add_child(btn)
		vbox.add_child(row)
	var close := Button.new()
	close.text = "Fechar"
	close.custom_minimum_size = Vector2(140, 26)
	close.pressed.connect(func() -> void: battle._forge_panel.visible = false)
	vbox.add_child(close)
	battle.ui_layer.add_child(battle._forge_panel)


func _build_cook_panel() -> void:
	battle._cook_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	style.border_color = Color(0.5, 0.45, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	battle._cook_panel.add_theme_stylebox_override("panel", style)
	battle._cook_panel.position = Vector2(400, 200)
	battle._cook_panel.custom_minimum_size = Vector2(480, 0)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	battle._cook_panel.add_child(vbox)
	var title := Label.new()
	title.text = "COZINHA — escolha a receita"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vbox.add_child(title)
	for recipe_id: String in battle.cooking_system.RECIPES:
		_add_cook_row(vbox, recipe_id, battle.cooking_system.RECIPES[recipe_id], true)
	for elixir_id: String in battle.cooking_system.ELIXIRS:
		_add_cook_row(vbox, elixir_id, battle.cooking_system.ELIXIRS[elixir_id], false)
	var close := Button.new()
	close.text = "Fechar"
	close.custom_minimum_size = Vector2(140, 26)
	close.pressed.connect(func() -> void: battle._cook_panel.visible = false)
	vbox.add_child(close)
	battle.ui_layer.add_child(battle._cook_panel)


func _add_cook_row(vbox: VBoxContainer, recipe_id: String, recipe: Dictionary, is_food: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var info := Label.new()
	var cost_parts := PackedStringArray()
	for ing_id: String in recipe["ingredients"]:
		cost_parts.append("%dx %s" % [int(recipe["ingredients"][ing_id]), battle.cooking_system.get_all_ingredients().get(ing_id, {}).get("name", ing_id)])
	var cost_text := ", ".join(cost_parts)
	var suffix := "" if is_food else "  [PERMANENTE]"
	info.text = "%s%s\nCusto: %s" % [recipe["name"], suffix, cost_text]
	info.add_theme_font_size_override("font_size", 13)
	info.custom_minimum_size = Vector2(320, 0)
	row.add_child(info)
	var btn := Button.new()
	if battle.cooking_system.can_craft(recipe_id):
		btn.text = "Cozinhar"
	else:
		btn.text = "Sem ingredientes"
		btn.disabled = true
	btn.custom_minimum_size = Vector2(140, 28)
	btn.pressed.connect(battle._on_cook_item_pressed.bind(recipe_id, is_food))
	row.add_child(btn)
	vbox.add_child(row)
