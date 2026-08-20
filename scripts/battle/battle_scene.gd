extends Node2D

@onready var grid: BattleGrid = $BattleGrid
@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UILayer
@onready var unit_container: Node2D = $UnitContainer

@onready var phase_label: Label = $UILayer/PhaseLabel
@onready var turn_label: Label = $UILayer/TurnLabel
@onready var soul_ether_label: Label = $UILayer/SoulEtherLabel
@onready var unit_info_panel: PanelContainer = $UILayer/UnitInfoPanel
@onready var unit_name_label: Label = $UILayer/UnitInfoPanel/VBoxContainer/UnitNameLabel
@onready var unit_hp_label: Label = $UILayer/UnitInfoPanel/VBoxContainer/UnitHPLabel
@onready var unit_class_label: Label = $UILayer/UnitInfoPanel/VBoxContainer/UnitClassLabel
@onready var action_menu: PanelContainer = $UILayer/ActionMenu
@onready var move_button: Button = $UILayer/ActionMenu/VBoxContainer/MoveButton
@onready var attack_button: Button = $UILayer/ActionMenu/VBoxContainer/AttackButton
@onready var wait_button: Button = $UILayer/ActionMenu/VBoxContainer/WaitButton

# Novos sistemas
var tutorial_system: TutorialSystem
var combat_feedback: CombatFeedback
var screen_effects: ScreenEffects
var unit_animators: Dictionary = {}
var autotile_system: AutoTileSystem

var selected_unit: Unit = null
var is_unit_selected: bool = false
var can_interact: bool = true
var battle_stats: Dictionary = {
 "turns": 0,
 "enemies_defeated": 0,
 "total_damage": 0,
 "damage_taken": 0,
 "souls_named": 0
}

func _ready() -> void:
 setup_systems()
 setup_ui()
 setup_battle()
 connect_signals()

func setup_systems() -> void:
 # Tutorial
 tutorial_system = TutorialSystem.new()
 tutorial_system.name = "TutorialSystem"
 add_child(tutorial_system)
 tutorial_system.tutorial_message.connect(_on_tutorial_message)

 # Combat Feedback
 combat_feedback = CombatFeedback.new()
 combat_feedback.name = "CombatFeedback"
 add_child(combat_feedback)

 # Screen Effects
 screen_effects = ScreenEffects.new()
 screen_effects.name = "ScreenEffects"
 add_child(screen_effects)
 screen_effects.setup_camera(camera)

 # Autotile System
 autotile_system = AutoTileSystem.new()
 autotile_system.name = "AutoTileSystem"
 add_child(autotile_system)

func setup_ui() -> void:
 phase_label.text = "FASE: JOGADOR"
 turn_label.text = "Turno: 1"
 soul_ether_label.text = "Soul Éter: 0"
 unit_info_panel.visible = false
 action_menu.visible = false

 move_button.pressed.connect(_on_move_pressed)
 attack_button.pressed.connect(_on_attack_pressed)
 wait_button.pressed.connect(_on_wait_pressed)

func setup_battle() -> void:
 # Inicializar sistema de autotile para o mapa
 autotile_system.auto_tile_map(grid, 0, 0, Rect2i(0, 0, 12, 12))
 autotile_system.setup_animated_tiles(grid, 0)
 autotile_system.apply_random_variations(grid, 0, Rect2i(0, 0, 12, 12), 0.15)
 
 # Obter o mapa atual
 var current_map = MapDatabase.get_map(GameManager.game_data.get("current_map", 0))
 if current_map:
  # Spawn inimigos baseado no mapa
  var enemy_positions = MapDatabase.get_enemy_spawn_positions(GameManager.game_data.get("current_map", 0), current_map.enemy_count)
  var enemies = current_map.enemies
  
  for i in range(min(current_map.enemy_count, enemy_positions.size())):
   var enemy_type = enemies[randi() % enemies.size()]
   var enemy_data = EnemyDatabase.get_enemy(enemy_type)
   if enemy_data:
    spawn_enemy_unit(enemy_positions[i], enemy_data.name, Color(enemy_data.color.r, enemy_data.color.g, enemy_data.color.b), enemy_data.class, enemy_data.hp, enemy_data.atk, enemy_data.def, enemy_data.mov, enemy_data.rng)
 else:
  # Fallback para spawn padrão
  spawn_player_unit(Vector2i(2, 6), "Kael", Color(0.2, 0.8, 0.3), "Imp Menor", 80, 12, 8, 3, 1)
  spawn_player_unit(Vector2i(1, 7), "Kroug", Color(0.8, 0.3, 0.1), "Goblin da Lama", 120, 10, 15, 2, 1)
  spawn_enemy_unit(Vector2i(9, 5), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
  spawn_enemy_unit(Vector2i(10, 6), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
  spawn_enemy_unit(Vector2i(8, 4), "Caçador", Color(0.6, 0.3, 0.3), "Arqueiro", 45, 16, 5, 4, 3)

 # Iniciar tutorial na primeira batalha
 if not FileAccess.file_exists("user://tutorial_completed"):
  tutorial_system.start_tutorial()

func spawn_player_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
 var unit = create_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng, true)
 BattleManager.register_unit(unit)
 return unit

func spawn_enemy_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
 var unit = create_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng, false)
 BattleManager.register_unit(unit)
 return unit

func create_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int, is_player: bool) -> Unit:
 var unit = Unit.new()
 unit.name = unit_name

 # Criar sprite visual
 var sprite = Sprite2D.new()
 sprite.name = "Sprite2D"
 var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
 image.fill(color)
 # Adicionar detalhes
 for i in range(8):
  var x = randi() % 32
  var y = randi() % 32
  image.set_pixel(x, y, color.lightened(0.3))
 # Olhos
 image.set_pixel(12, 12, Color.WHITE)
 image.set_pixel(20, 12, Color.WHITE)
 image.set_pixel(12, 12, Color.BLACK)
 image.set_pixel(20, 12, Color.BLACK)
 var texture = ImageTexture.create_from_image(image)
 sprite.texture = texture
 unit.add_child(sprite)

  var hp_bar = ProgressBar.new()
  hp_bar.name = "HPBar"
  hp_bar.position = Vector2(-12, -20)
  hp_bar.size = Vector2(24, 4)
  hp_bar.max_value = hp
  hp_bar.value = hp
  var hp_fill = StyleBoxFlat.new()
  hp_fill.bg_color = Color(0.2, 0.8, 0.2)
  hp_bar.add_theme_stylebox_override("fill", hp_fill)
  var hp_bg = StyleBoxFlat.new()
  hp_bg.bg_color = Color(0.2, 0.2, 0.2)
  hp_bar.add_theme_stylebox_override("background", hp_bg)
 unit.add_child(hp_bar)

 var selection = ColorRect.new()
 selection.name = "SelectionIndicator"
 selection.color = Color(1, 1, 0, 0.3)
 selection.position = Vector2(-2, -2)
 selection.size = Vector2(36, 36)
 selection.visible = false
 unit.add_child(selection)

 var data = UnitData.new()
 data.unit_name = unit_name
 data.is_player = is_player
 data.unit_class = unit_class
 data.max_hp = hp
 data.current_hp = hp
 data.attack = atk
 data.defense = def
 data.move_range = mov
 data.attack_range = rng
 data.color = color
 data.soul_ether_value = 10 if is_player else 15
 unit.data = data

 unit.position = grid.grid_to_pixel(grid_pos)
 unit.grid_position = grid_pos
 unit_container.add_child(unit)

 # Criar animador
 var animator = UnitAnimator.new()
 animator.name = "Animator"
 unit.add_child(animator)
 animator.setup(unit)
 unit_animators[unit_name] = animator
 animator.play_idle()

 return unit

func connect_signals() -> void:
 BattleManager.phase_changed.connect(_on_phase_changed)
 BattleManager.turn_started.connect(_on_turn_started)
 BattleManager.unit_moved.connect(_on_unit_moved)
 BattleManager.unit_attacked.connect(_on_unit_attacked)
 BattleManager.unit_died.connect(_on_unit_died)
 BattleManager.battle_won.connect(_on_battle_won)
 BattleManager.battle_lost.connect(_on_battle_lost)
 BattleManager.soul_ether_gained.connect(_on_soul_ether_gained)

func _input(event: InputEvent) -> void:
 if not can_interact:
  return
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_LEFT:
   handle_left_click()
  elif event.button_index == MOUSE_BUTTON_RIGHT:
   handle_right_click()

func handle_left_click() -> void:
 var mouse_pos = get_global_mouse_position()
 var grid_pos = grid.pixel_to_grid(mouse_pos)

 if not BattleManager.is_valid_position(grid_pos):
  return

 var clicked_unit = BattleManager.get_tile_at(grid_pos)

 if clicked_unit and clicked_unit.data and clicked_unit.data.is_player and BattleManager.current_phase == BattleManager.Phase.PLAYER_TURN:
  select_unit(clicked_unit)
  tutorial_system.complete_step("select_unit")
 elif is_unit_selected and selected_unit:
  if not selected_unit.has_moved and grid.movement_tiles.has(grid_pos):
   move_selected_unit(grid_pos)
   tutorial_system.complete_step("move_unit")
  elif not selected_unit.has_acted and grid.attack_tiles.has(grid_pos) and clicked_unit and clicked_unit.data and not clicked_unit.data.is_player:
   attack_with_selected_unit(clicked_unit)
   tutorial_system.complete_step("attack_unit")

func handle_right_click() -> void:
 deselect_unit()

func select_unit(unit: Unit) -> void:
 deselect_unit()
 selected_unit = unit
 is_unit_selected = true

 # Feedback visual
 SoundManager.play_select()
 combat_feedback.flash_unit(unit, Color(1.2, 1.2, 1.5), 0.1)

 show_unit_info(unit)
 show_action_menu(unit)

 if not unit.has_moved:
  grid.show_movement_range(unit, unit.data.move_range)
 if not unit.has_acted:
  grid.show_attack_range(unit, unit.data.attack_range)

func deselect_unit() -> void:
 selected_unit = null
 is_unit_selected = false
 grid.clear_highlights()
 hide_unit_info()
 hide_action_menu()

func move_selected_unit(grid_pos: Vector2i) -> void:
 if selected_unit and not selected_unit.has_moved:
  # Animação de movimento
  var animator = unit_animators.get(selected_unit.name)
  if animator:
   animator.play_walk(grid.grid_to_pixel(grid_pos))

  SoundManager.play_step()
  BattleManager.move_unit(selected_unit, grid_pos)
  selected_unit.has_moved = true
  grid.clear_highlights()
  if not selected_unit.has_acted:
   grid.show_attack_range(selected_unit, selected_unit.data.attack_range)

func attack_with_selected_unit(target: Unit) -> void:
 if selected_unit and not selected_unit.has_acted:
  # Animação de ataque
  var attacker_animator = unit_animators.get(selected_unit.name)
  if attacker_animator:
   await attacker_animator.play_attack(target)

  SoundManager.play_hit()
  combat_feedback.shake_light()

  BattleManager.attack_unit(selected_unit, target)

  # Animação de dano no alvo
  var target_animator = unit_animators.get(target.name)
  if target_animator:
   target_animator.play_hit()

  selected_unit.has_acted = true
  grid.clear_highlights()
  hide_action_menu()
  deselect_unit()

func show_unit_info(unit: Unit) -> void:
 unit_info_panel.visible = true
 unit_name_label.text = unit.data.unit_name
 unit_hp_label.text = "HP: %d/%d" % [unit.current_hp, unit.data.max_hp]
 unit_class_label.text = unit.data.unit_class

func hide_unit_info() -> void:
 unit_info_panel.visible = false

func show_action_menu(unit: Unit) -> void:
 if not unit.has_moved or not unit.has_acted:
  action_menu.visible = true
  move_button.disabled = unit.has_moved
  attack_button.disabled = unit.has_acted
 else:
  hide_action_menu()

func hide_action_menu() -> void:
 action_menu.visible = false

func _on_move_pressed() -> void:
 if selected_unit and not selected_unit.has_moved:
  grid.show_movement_range(selected_unit, selected_unit.data.move_range)

func _on_attack_pressed() -> void:
 if selected_unit and not selected_unit.has_acted:
  grid.show_attack_range(selected_unit, selected_unit.data.attack_range)

func _on_wait_pressed() -> void:
 if selected_unit:
  selected_unit.has_moved = true
  selected_unit.has_acted = true
  tutorial_system.complete_step("wait_action")
  deselect_unit()
  check_all_units_acted()

func check_all_units_acted() -> void:
 for unit in BattleManager.player_units:
  if not unit.has_acted or not unit.has_moved:
   return
 tutorial_system.complete_step("end_turn")
 BattleManager.end_player_turn()

func _on_phase_changed(phase: String) -> void:
 phase_label.text = "FASE: " + phase
 can_interact = (phase == "PLAYER_TURN")

func _on_turn_started(_unit: Unit) -> void:
 turn_label.text = "Turno: %d" % BattleManager.turn_count
 battle_stats.turns = BattleManager.turn_count

func _on_unit_moved(unit: Unit, _from: Vector2i, to: Vector2i) -> void:
 unit.position = grid.grid_to_pixel(to)

func _on_unit_attacked(attacker: Unit, target: Unit, damage: int) -> void:
 # Feedback visual de dano
 var target_pos = target.global_position + Vector2(0, -20)
 combat_feedback.show_damage_number(target_pos, damage)
 combat_feedback.spawn_hit_particles(target.global_position)

 # Atualizar stats
 if attacker.data and attacker.data.is_player:
  battle_stats.total_damage += damage
 else:
  battle_stats.damage_taken += damage

  # Atualizar HP bar
  var hp_bar = target.get_node("HPBar") if target.has_node("HPBar") else null
  if hp_bar:
   hp_bar.value = target.current_hp

 # Flash de dano
 combat_feedback.flash_unit(target, Color(2, 0.5, 0.5), 0.1)

func _on_unit_died(unit: Unit) -> void:
 # Animação de morte
 var animator = unit_animators.get(unit.name)
 if animator:
  await animator.play_death()

 SoundManager.play_death()
 combat_feedback.shake_medium()

 if unit.data and not unit.data.is_player:
  battle_stats.enemies_defeated += 1

 # Verificar vitória
 check_battle_end()

func check_battle_end() -> void:
 if BattleManager.player_units.size() == 0:
  BattleManager.battle_lost.emit()
 elif BattleManager.enemy_units.size() == 0:
  BattleManager.battle_won.emit()

func _on_battle_won() -> void:
 can_interact = false

 # Efeitos visuais
 await screen_effects.flash_white()
 combat_feedback.spawn_level_up_effect(Vector2(640, 360))

 # Mostrar tela de vitória
 await get_tree().create_timer(1.0).timeout
 show_victory_screen()

func _on_battle_lost() -> void:
 can_interact = false

 # Efeitos visuais
 await screen_effects.flash_red()
 screen_effects.slow_motion(0.3, 1.0)

 # Mostrar tela de derrota
 await get_tree().create_timer(1.5).timeout
 show_defeat_screen()

func _on_soul_ether_gained(amount: int) -> void:
 soul_ether_label.text = "Soul Éter: %d" % BattleManager.soul_ether
 combat_feedback.show_status_effect(Vector2(640, 100), "Soul Éter +%d" % amount)

func show_victory_screen() -> void:
 # Criar tela de vitória dinamicamente
 var result_screen = load("res://scenes/ui/battle_result_screen.tscn").instantiate()
 add_child(result_screen)
 result_screen.show_victory(battle_stats)
 result_screen.restart_pressed.connect(_on_restart)
 result_screen.menu_pressed.connect(_on_menu)
 result_screen.continue_pressed.connect(_on_continue)

func show_defeat_screen() -> void:
 var result_screen = load("res://scenes/ui/battle_result_screen.tscn").instantiate()
 add_child(result_screen)
 result_screen.show_defeat(battle_stats)
 result_screen.restart_pressed.connect(_on_restart)
 result_screen.menu_pressed.connect(_on_menu)

func _on_restart() -> void:
 get_tree().reload_current_scene()

func _on_menu() -> void:
 SceneManager.change_scene("main_menu")

func _on_continue() -> void:
 SceneManager.change_scene("map_select")

func _on_tutorial_message(message: String, position: Vector2) -> void:
 # Mostrar mensagem do tutorial
 var label = Label.new()
 label.text = message
 label.position = position - Vector2(200, 20)
 label.z_index = 150
 label.add_theme_font_size_override("font_size", 16)
 label.add_theme_color_override("font_color", Color.WHITE)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.custom_minimum_size = Vector2(400, 0)

 ui_layer.add_child(label)

 # Auto-remover após 3 segundos
 await get_tree().create_timer(3.0).timeout
 if is_instance_valid(label):
  label.queue_free()
