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

var selected_unit: Unit = null
var is_unit_selected: bool = false
var can_interact: bool = true

func _ready() -> void:
 setup_ui()
 setup_battle()
 connect_signals()

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
 spawn_player_unit(Vector2i(2, 6), "Kael", Color(0.2, 0.8, 0.3), "Imp Menor", 80, 12, 8, 3, 1)
 spawn_player_unit(Vector2i(1, 7), "Kroug", Color(0.8, 0.3, 0.1), "Goblin da Lama", 120, 10, 15, 2, 1)
 spawn_enemy_unit(Vector2i(9, 5), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
 spawn_enemy_unit(Vector2i(10, 6), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
 spawn_enemy_unit(Vector2i(8, 4), "Caçador", Color(0.6, 0.3, 0.3), "Arqueiro", 45, 16, 5, 4, 3)

 grid.draw_grid()
 BattleManager.start_battle()

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
 var hp_fill = ColorRect.new()
 hp_fill.color = Color(0.2, 0.8, 0.2)
 hp_bar.add_theme_stylebox_override("fill", hp_fill.create_style_box())
 var hp_bg = ColorRect.new()
 hp_bg.color = Color(0.2, 0.2, 0.2)
 hp_bar.add_theme_stylebox_override("background", hp_bg.create_style_box())
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

 if clicked_unit and clicked_unit.is_player and BattleManager.current_phase == BattleManager.Phase.PLAYER_TURN:
  select_unit(clicked_unit)
 elif is_unit_selected and selected_unit:
  if not selected_unit.has_moved and grid.movement_tiles.has(grid_pos):
   move_selected_unit(grid_pos)
  elif not selected_unit.has_acted and grid.attack_tiles.has(grid_pos) and clicked_unit and not clicked_unit.is_player:
   attack_with_selected_unit(clicked_unit)

func handle_right_click() -> void:
 deselect_unit()

func select_unit(unit: Unit) -> void:
 deselect_unit()
 selected_unit = unit
 is_unit_selected = true
 unit.select()

 show_unit_info(unit)
 show_action_menu(unit)

 if not unit.has_moved:
  grid.show_movement_range(unit, unit.data.move_range)
 if not unit.has_acted:
  grid.show_attack_range(unit, unit.data.attack_range)

func deselect_unit() -> void:
 if selected_unit:
  selected_unit.deselect()
 selected_unit = null
 is_unit_selected = false
 grid.clear_highlights()
 hide_unit_info()
 hide_action_menu()

func move_selected_unit(grid_pos: Vector2i) -> void:
 if selected_unit and not selected_unit.has_moved:
  BattleManager.move_unit(selected_unit, grid_pos)
  selected_unit.has_moved = true
  grid.clear_highlights()
  if not selected_unit.has_acted:
   grid.show_attack_range(selected_unit, selected_unit.data.attack_range)

func attack_with_selected_unit(target: Unit) -> void:
 if selected_unit and not selected_unit.has_acted:
  BattleManager.attack_unit(selected_unit, target)
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
  deselect_unit()
  check_all_units_acted()

func check_all_units_acted() -> void:
 for unit in BattleManager.player_units:
  if not unit.has_acted or not unit.has_moved:
   return
 BattleManager.end_player_turn()

func _on_phase_changed(phase: String) -> void:
 phase_label.text = "FASE: " + phase
 can_interact = (phase == "PLAYER_TURN")

func _on_turn_started(_unit: Unit) -> void:
 turn_label.text = "Turno: %d" % BattleManager.turn_count

func _on_unit_moved(unit: Unit, _from: Vector2i, to: Vector2i) -> void:
 unit.position = grid.grid_to_pixel(to)

func _on_unit_attacked(attacker: Unit, target: Unit, damage: int) -> void:
 pass

func _on_unit_died(unit: Unit) -> void:
 pass

func _on_battle_won() -> void:
 phase_label.text = "VITÓRIA!"
 can_interact = false

func _on_battle_lost() -> void:
 phase_label.text = "DERROTA..."
 can_interact = false

func _on_soul_ether_gained(amount: int) -> void:
 soul_ether_label.text = "Soul Éter: %d" % BattleManager.soul_ether
