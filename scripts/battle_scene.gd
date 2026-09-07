extends Node2D

const EquipmentSystemLib := preload("res://scripts/equipment_system.gd")

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
var unit_animators: Dictionary = {}  # chave: instance_id da Unit (NÃO nome — nomes duplicados colidiam)
var autotile_system: AutoTileSystem
var pixel_art_renderer: PixelArtRenderer

# UI dos novos sistemas
var combo_label: Label
var combo_dots: Array[ColorRect] = []
var balance_bar: ProgressBar
var balance_label: Label
var boss_hp_bar: ProgressBar
var boss_name_label: Label
var boss_panel: PanelContainer

# Kaelen HUD (§3.4)
var kaelen_hud_panel: PanelContainer
var kaelen_bio_weaknesses: Label
var kaelen_bio_fatigue: Label
var kaelen_bio_armor: Label
var kaelen_psy_morale: Label
var kaelen_psy_flee: Label
var kaelen_tac_locks: Label
var kaelen_tac_threat: Label
var kaelen_tac_range: Label
var kaelen_suggestions_label: Label

# Sistemas de combate avançado (GDD v2 §3-5)
var timed_combat: TimedCombatSystem
var lock_system: LockSystem
var combo_system: ComboSystem
var balance_system: BalanceSystem
var kaelen_system: KaelenSystem
var boss_system: BossSystem

# §6-7 Sistemas (Traversal / Camp / Cooking / Tavern)
var traversal_system: TraversalSystem
var campfire_system: CampfireSystem
var cooking_system: CookingSystem
var tavern_minigame: TavernMinigame

# §8 Progressão Global
var progression_system: ProgressionSystem

# HUD cumulativo dos sistemas §6-7
var progression_hud: PanelContainer

# §5 Boss runtime: cardinal resolvido por NOME da unidade (_resolve_cardinal_name)
# — o mapeamento por classe ("Boss": "Ignis") fazia TODO chefe usar dados de Ignis.

# Painel de ações §6-7 (excita sinais já conectados)
var actions_panel: PanelContainer
var _camp_used: bool = false
var _cook_used: bool = false
var _tavern_running: bool = false
var _tavern_turn_limit: int = 20
const TAVERN_BET: int = 10  ## aposta fixa da Guerra de Runas (ROADMAP #12)
var _forge_panel: PanelContainer = null  ## UI de seleção da Forja (§7)
var _cook_panel: PanelContainer = null  ## UI de seleção da Cozinha (§7.2)

# Estado de timed hit
var _timed_hit_active: bool = false
var _timed_hit_start_time: float = 0.0
var _timed_hit_target: Unit = null

# Estado de timed block (defesa reativa — espelho do timed hit, GDD v2 §3.1)
var _timed_block_active: bool = false
var _timed_block_start_time: float = 0.0
var _timed_block_reduction: float = 0.0

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
var captured_souls: CapturedSouls = CapturedSouls.new()

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

 # Pixel Art Renderer
 pixel_art_renderer = PixelArtRenderer.new()
 pixel_art_renderer.name = "PixelArtRenderer"
 add_child(pixel_art_renderer)

 # Sistemas de combate avançado
 timed_combat = TimedCombatSystem.new()
 # LockSystem é do BattleManager (donos dos casts anunciados GDD §3.2):
 # battle_scene consome os sinais p/ feedback e CP.
 lock_system = BattleManager.lock_system
 combo_system = ComboSystem.new()
 balance_system = BalanceSystem.new()
 kaelen_system = KaelenSystem.new()
 boss_system = BossSystem.new()

 # §8 Progressão Global (RefCounted — sem add_child)
 progression_system = ProgressionSystem.new()

 # §6.1 Travessia Dinâmica (RefCounted)
 traversal_system = TraversalSystem.new()

 # §7.1 Acampamento (RefCounted)
 campfire_system = CampfireSystem.new()

 # §7.2 Culinária e Elixires (RefCounted)
 cooking_system = CookingSystem.new()

 # §7.3 Minigame Taberna (RefCounted)
 tavern_minigame = TavernMinigame.new()

 # Conectar sinais dos sistemas
 combo_system.combo_activated.connect(_on_combo_activated)
 combo_system.cp_changed.connect(func(_cp: int, _max: int) -> void: update_combo_ui())
 balance_system.mode_changed.connect(_on_balance_mode_changed)
 balance_system.mode_changed.connect(func(_mode: String) -> void: update_balance_ui())
 balance_system.ether_changed.connect(func(_v: int) -> void: update_balance_ui())
 balance_system.fury_changed.connect(func(_v: int) -> void: update_balance_ui())
 boss_system.boss_defeated.connect(_on_boss_defeated)
 boss_system.boss_spell_charging.connect(_on_boss_spell_charging)
 boss_system.boss_hp_changed.connect(show_boss_hp)
 lock_system.lock_broken.connect(_on_lock_broken)
 lock_system.enemy_cast_started.connect(_on_enemy_cast_started)
 BattleManager.enemy_stunned.connect(_on_enemy_spellbreak)

 # §6-7 Sinais
 traversal_system.traversal_completed.connect(_on_traversal_completed)
 campfire_system.rest_completed.connect(_on_camp_rest_completed)
 campfire_system.bond_level_changed.connect(_on_bond_level_changed)
 cooking_system.recipe_crafted.connect(_on_recipe_crafted)
 tavern_minigame.game_over.connect(_on_tavern_game_over)

## P2 #13b: construtores de UI extraidos para battle_hud.gd (scripts/battle/).
## Wrappers preservam a API usada por testes e handlers da cena.
const BattleHudLib := preload("res://scripts/battle/battle_hud.gd")
var _hud = null


func _get_hud():
 if _hud == null:
  _hud = BattleHudLib.new()
  _hud.battle = self
 return _hud


func setup_ui() -> void:
 _get_hud().setup_ui()


func _create_kaelen_hud() -> void:
 _get_hud()._create_kaelen_hud()


func _create_combo_ui() -> void:
 _get_hud()._create_combo_ui()


func _create_balance_ui() -> void:
 _get_hud()._create_balance_ui()


func _create_boss_ui() -> void:
 _get_hud()._create_boss_ui()


func _create_progression_hud() -> void:
 _get_hud()._create_progression_hud()


func _create_actions_panel() -> void:
 _get_hud()._create_actions_panel()


func _add_action_button(parent: Node, label_text: String, handler: Callable) -> void:
 _get_hud()._add_action_button(parent, label_text, handler)


func _build_forge_panel() -> void:
 _get_hud()._build_forge_panel()


func _build_cook_panel() -> void:
 _get_hud()._build_cook_panel()


func _add_cook_row(vbox: VBoxContainer, recipe_id: String, recipe: Dictionary, is_food: bool) -> void:
 _get_hud()._add_cook_row(vbox, recipe_id, recipe, is_food)


## P2 #13: spawn/sprites extraídos para BattleSpawner (scripts/battle/battle_spawner.gd).
## Wrappers preservam a API usada por testes e handlers da cena.
const BattleSpawnerLib := preload("res://scripts/battle/battle_spawner.gd")
var _spawner = null


func _load_hd_sprite(path: String) -> Sprite2D:
 return _get_spawner().load_hd_sprite(path)


func _get_spawner():
 # Lazy (RefCounted): testes instanciam a cena sem _ready e stubam
 # grid/unit_container via .set() — o spawner lê os membros na hora.
 if _spawner == null:
  _spawner = BattleSpawnerLib.new()
  _spawner.battle = self
 return _spawner


func setup_battle() -> void:
 _get_spawner().setup_battle()


func _resolve_enemy_pool(current_map: Dictionary) -> Dictionary:
 return _get_spawner().resolve_enemy_pool(current_map)


func _spawn_player_party() -> void:
 _get_spawner().spawn_player_party()


func spawn_player_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
 return _get_spawner().spawn_player_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng)


func spawn_enemy_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
 return _get_spawner().spawn_enemy_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng)


func _resolve_cardinal_name(unit_name: String) -> String:
 return _get_spawner().resolve_cardinal_name(unit_name)


func create_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int, is_player: bool) -> Unit:
 return _get_spawner().create_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng, is_player)


func create_unit_sprite(unit_name: String, color: Color, is_player: bool) -> Sprite2D:
 return _get_spawner().create_unit_sprite(unit_name, color, is_player)


func _normalize_sprite_to_tile(sprite: Sprite2D) -> void:
 _get_spawner().normalize_sprite_to_tile(sprite)


func _sprite_key(unit_name: String) -> String:
 return _get_spawner().sprite_key(unit_name)


func connect_signals() -> void:
 BattleManager.phase_changed.connect(_on_phase_changed)
 BattleManager.turn_started.connect(_on_turn_started)
 BattleManager.unit_moved.connect(_on_unit_moved)
 BattleManager.unit_attacked.connect(_on_unit_attacked)
 BattleManager.unit_died.connect(_on_unit_died)
 BattleManager.battle_won.connect(_on_battle_won)
 BattleManager.battle_lost.connect(_on_battle_lost)
 BattleManager.soul_ether_gained.connect(_on_soul_ether_gained)
 # Resolver da janela defensiva: o BattleManager aguarda este callable antes
 # de aplicar o dano ao protagonista (núcleo headless segue testável sem ele).
 BattleManager.timed_block_resolver = _resolve_timed_block

 # Kaelen System (§3.4) - conectar sinais
 kaelen_system.target_analyzed.connect(_on_kaelen_target_analyzed)
 kaelen_system.suggestion_generated.connect(_on_kaelen_suggestion_generated)

 # Form evolution (§8 / ROADMAP #6) - feedback imediato no mundo quando a
 # forma do protagonista muda (avanço de ato por memória/almas/XP).
 if GameManager and GameManager.character_progression:
  GameManager.character_progression.form_changed.connect(_on_protagonist_form_changed)


func _input(event: InputEvent) -> void:
 _get_input().handle_event(event)

## P2 #13d: interação/seleção extraída para BattleInput (scripts/battle/battle_input.gd).
## Wrappers preservam a API usada por testes, connect_signals e handlers da cena.
const BattleInputLib := preload("res://scripts/battle/battle_input.gd")
var _input_lib = null


func _get_input():
 # Lazy (RefCounted): testes instanciam a cena sem _ready e stubam membros.
 if _input_lib == null:
  _input_lib = BattleInputLib.new()
  _input_lib.battle = self
 return _input_lib


func handle_left_click() -> void:
 _get_input().handle_left_click()


func handle_right_click() -> void:
 _get_input().handle_right_click()


func select_unit(unit: Unit) -> void:
 _get_input().select_unit(unit)


func deselect_unit() -> void:
 _get_input().deselect_unit()


func move_selected_unit(grid_pos: Vector2i) -> void:
 _get_input().move_selected_unit(grid_pos)


func attack_with_selected_unit(target: Unit) -> void:
 _get_input().attack_with_selected_unit(target)


func _resolve_timed_block(_attacker: Unit, target: Unit) -> float:
 return _get_input()._resolve_timed_block(_attacker, target)


func _resolve_block_input() -> void:
 _get_input()._resolve_block_input()


func _apply_attack_result(target: Unit, multiplier: float, grade: String) -> void:
 _get_input()._apply_attack_result(target, multiplier, grade)


func show_unit_info(unit: Unit) -> void:
 _get_input().show_unit_info(unit)


func hide_unit_info() -> void:
 _get_input().hide_unit_info()


func show_action_menu(unit: Unit) -> void:
 _get_input().show_action_menu(unit)


func hide_action_menu() -> void:
 _get_input().hide_action_menu()


func _on_move_pressed() -> void:
 _get_input()._on_move_pressed()


func _on_attack_pressed() -> void:
 _get_input()._on_attack_pressed()


func _on_wait_pressed() -> void:
 _get_input()._on_wait_pressed()


## P2 #13c: fluxo/resultado/sinais extraídos para BattleFlow (scripts/battle/battle_flow.gd).
## Wrappers preservam a API usada por testes e handlers da cena.
const BattleFlowLib := preload("res://scripts/battle/battle_flow.gd")
var _flow = null


func _get_flow():
 # Lazy (RefCounted): testes instanciam a cena sem _ready e stubam membros.
 if _flow == null:
  _flow = BattleFlowLib.new()
  _flow.battle = self
 return _flow


func check_all_units_acted() -> void:
 _get_flow().check_all_units_acted()


func _on_phase_changed(phase: String) -> void:
 _get_flow()._on_phase_changed(phase)


func _on_turn_started(unit: Unit) -> void:
 _get_flow()._on_turn_started(unit)


func _on_unit_moved(unit: Unit, _from: Vector2i, to: Vector2i) -> void:
 _get_flow()._on_unit_moved(unit, _from, to)


func _on_unit_attacked(attacker: Unit, target: Unit, damage: int) -> void:
 _get_flow()._on_unit_attacked(attacker, target, damage)


func _on_unit_died(unit: Unit) -> void:
 _get_flow()._on_unit_died(unit)


func check_battle_end() -> void:
 _get_flow().check_battle_end()


func _on_battle_won() -> void:
 _get_flow()._on_battle_won()


func _on_boss_stage_cleared() -> void:
 _get_flow()._on_boss_stage_cleared()


func _maybe_show_naming() -> void:
 _get_flow()._maybe_show_naming()


func _on_battle_lost() -> void:
 _get_flow()._on_battle_lost()


func _commit_progression() -> void:
 _get_flow()._commit_progression()


func _on_soul_ether_gained(amount: int) -> void:
 _get_flow()._on_soul_ether_gained(amount)


func show_victory_screen() -> void:
 _get_flow().show_victory_screen()


func show_defeat_screen() -> void:
 _get_flow().show_defeat_screen()


func _on_restart() -> void:
 _get_flow()._on_restart()


func _on_menu() -> void:
 _get_flow()._on_menu()


func _on_continue() -> void:
 _get_flow()._on_continue()


func _get_post_victory_destination() -> String:
 return _get_flow()._get_post_victory_destination()


## Animator da unidade por instância (ver unit_animators).
func _get_animator(unit: Unit) -> UnitAnimator:
 return unit_animators.get(unit.get_instance_id())


## P2 #13e: handlers de sistemas extraídos para BattleSystems (scripts/battle/battle_systems.gd).
## Wrappers preservam a API usada por testes e connect_signals.
const BattleSystemsLib := preload("res://scripts/battle/battle_systems.gd")
var _systems = null


func _get_systems():
 if _systems == null:
  _systems = BattleSystemsLib.new()
  _systems.battle = self
 return _systems


func _on_tutorial_message(message: String, position: Vector2) -> void:
 _get_systems()._on_tutorial_message(message, position)


func _on_combo_activated(combo_name: String, description: String) -> void:
 _get_systems()._on_combo_activated(combo_name, description)


func _on_lock_broken(_enemy, _lock: Dictionary) -> void:
 _get_systems()._on_lock_broken(_enemy, _lock)


func _on_enemy_cast_started(enemy, spell_name: String, _locks: Array, _turns: int) -> void:
 _get_systems()._on_enemy_cast_started(enemy, spell_name, _locks, _turns)


func _on_enemy_spellbreak(_enemy) -> void:
 _get_systems()._on_enemy_spellbreak(_enemy)


func _on_kaelen_target_analyzed(target_name: String, data: Dictionary) -> void:
 _get_systems()._on_kaelen_target_analyzed(target_name, data)


func _on_kaelen_suggestion_generated(suggestion: Dictionary) -> void:
 _get_systems()._on_kaelen_suggestion_generated(suggestion)


func _on_balance_mode_changed(new_mode: String) -> void:
 _get_systems()._on_balance_mode_changed(new_mode)


func _on_boss_defeated(boss_name: String) -> void:
 _get_systems()._on_boss_defeated(boss_name)


func _on_boss_spell_charging(_boss_name: String, spell_name: String, _turns_left: int) -> void:
 _get_systems()._on_boss_spell_charging(_boss_name, spell_name, _turns_left)


func _on_traversal_completed(traversal_type: String) -> void:
 _get_systems()._on_traversal_completed(traversal_type)


func _collect_traversal_loot() -> void:
 _get_systems()._collect_traversal_loot()


func _on_camp_rest_completed(healed_units: Array) -> void:
 _get_systems()._on_camp_rest_completed(healed_units)


func _on_bond_level_changed(apostle_name: String, new_level: int) -> void:
 _get_systems()._on_bond_level_changed(apostle_name, new_level)


func _on_recipe_crafted(recipe_name: String, bonuses: Dictionary) -> void:
 _get_systems()._on_recipe_crafted(recipe_name, bonuses)


func _apply_cooked_heal(bonuses: Dictionary) -> void:
 _get_systems()._apply_cooked_heal(bonuses)


func _cooking_attack_multiplier() -> float:
 return _get_systems()._cooking_attack_multiplier()


func _cooking_defense_bonus() -> int:
 return _get_systems()._cooking_defense_bonus()


func _on_tavern_game_over(winner: String, loser: String) -> void:
 _get_systems()._on_tavern_game_over(winner, loser)


func update_combo_ui() -> void:
 _get_systems().update_combo_ui()


func update_balance_ui() -> void:
 _get_systems().update_balance_ui()


func show_boss_hp(boss_name: String, hp: int, max_hp: int) -> void:
 _get_systems().show_boss_hp(boss_name, hp, max_hp)


func hide_boss_hp() -> void:
 _get_systems().hide_boss_hp()


func _on_protagonist_form_changed(old_form: String, new_form: String) -> void:
 _get_systems()._on_protagonist_form_changed(old_form, new_form)


func _apply_protagonist_form_stats(new_form: String) -> void:
 _get_systems()._apply_protagonist_form_stats(new_form)


func _swap_protagonist_sprite(unit: Unit, new_form: String) -> void:
 _get_systems()._swap_protagonist_sprite(unit, new_form)


func _find_unit_sprite(unit: Unit) -> Sprite2D:
 return _get_systems()._find_unit_sprite(unit)


func _update_progression_hud() -> void:
 _get_systems()._update_progression_hud()


func _on_forge_pressed() -> void:
 _get_systems()._on_forge_pressed()


func _sync_equipment():
 return _get_systems()._sync_equipment()


func _on_forge_item_pressed(equipment_id: String) -> void:
 _get_systems()._on_forge_item_pressed(equipment_id)


func _on_camp_pressed() -> void:
 _get_systems()._on_camp_pressed()


func _on_cook_pressed() -> void:
 _get_systems()._on_cook_pressed()


func _on_cook_item_pressed(recipe_id: String, is_food: bool) -> void:
 _get_systems()._on_cook_item_pressed(recipe_id, is_food)


func _on_tavern_pressed() -> void:
 _get_systems()._on_tavern_pressed()


func _on_tavern_bet_resolved(won: bool, payout: int) -> void:
 _get_systems()._on_tavern_bet_resolved(won, payout)


func _on_tavern_exclusive_reward(reward_id: String) -> void:
 _get_systems()._on_tavern_exclusive_reward(reward_id)


func _run_tavern_until_end() -> void:
 _get_systems()._run_tavern_until_end()


func _pick_tavern_rune(player_id: String) -> String:
 return _get_systems()._pick_tavern_rune(player_id)


func _on_traverse_pressed() -> void:
 _get_systems()._on_traverse_pressed()


func _on_combo_pressed() -> void:
 _get_systems()._on_combo_pressed()


func _try_use_combo() -> bool:
 return _get_systems()._try_use_combo()
