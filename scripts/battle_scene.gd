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

# === Sinal handlers para sistemas avançados ===

func _on_combo_activated(combo_name: String, description: String) -> void:
 combat_feedback.show_status_effect(Vector2(640, 300), "COMBO: " + combo_name)
 combat_feedback.show_status_effect(Vector2(640, 340), description)
 combat_feedback.shake_medium()
 SoundManager.play_hit()
 update_combo_ui()

## §3.2-3.3 Quebra de lock gera CP (2 por lock, GDD via resolve_spellbreak).
func _on_lock_broken(_enemy, _lock: Dictionary) -> void:
 combo_system.earn_from_lock_break()
 update_combo_ui()
 combat_feedback.show_status_effect(Vector2(640, 300), "LOCK QUEBRADO (+2 CP)")

## §3.2 Cast inimigo anunciado: locks visíveis + aviso de conjuração.
func _on_enemy_cast_started(enemy, spell_name: String, _locks: Array, _turns: int) -> void:
 if enemy is Node2D and enemy.is_inside_tree():
  combat_feedback.show_status_effect(enemy.global_position + Vector2(0, -40), "CONJURANDO: " + spell_name)
 else:
  combat_feedback.show_status_effect(Vector2(640, 200), "PERIGO: " + spell_name + " se preparando!")
 combat_feedback.shake_light()

## §3.2 Spellbreak: todos os locks quebrados → inimigo atordoado.
func _on_enemy_spellbreak(_enemy) -> void:
 combat_feedback.show_status_effect(Vector2(640, 200), "SPELLBREAK! INIMIGO ATORDOADO!")
 combat_feedback.shake_medium()

## §3.4 Kaelen System — handlers de sinais
func _on_kaelen_target_analyzed(target_name: String, data: Dictionary) -> void:
 if not kaelen_hud_panel:
  return
 # HUD começa oculto (§3.4 morto) — revela na 1ª análise de um inimigo.
 if not kaelen_hud_panel.visible:
  kaelen_hud_panel.visible = true

 # Vetor Biológico
 var bio = data.get("biological", {})
 var weaknesses_text: Array = []
 for w in bio.get("weaknesses", []):
  weaknesses_text.append("%s (+%d%%)" % [w["type"], w["bonus_percent"]])
 kaelen_bio_weaknesses.text = "Fraquezas: " + (", ".join(weaknesses_text) if weaknesses_text else "—")
 kaelen_bio_fatigue.text = "Fadiga: " + kaelen_system.get_fatigue_name(bio.get("fatigue", 0))
 kaelen_bio_armor.text = "Armadura: %d" % bio.get("armor", 0)

 # Vetor Psicológico
 var psycho = data.get("psychological", {})
 kaelen_psy_morale.text = "Moral: " + kaelen_system.get_morale_name(psycho.get("morale", 1))
 kaelen_psy_flee.text = "Fuga: %.0f%%" % (psycho.get("flee_chance", 0.0) * 100)

 # Vetor Tático
 var tac = data.get("tactical", {})
 kaelen_tac_locks.text = "Locks: " + ("Sim" if tac.get("has_locks", false) else "Não")
 kaelen_tac_threat.text = "Ameaça: " + tac.get("threat_level", "BAIXA")
 kaelen_tac_range.text = "Alcance: %d" % tac.get("attack_range", 1)

func _on_kaelen_suggestion_generated(suggestion: Dictionary) -> void:
 if not kaelen_hud_panel:
  return
 var suggestions: Array = suggestion.get("suggestions", [])
 var texts: Array = []
 for s in suggestions:
  texts.append("%s: %s (urgência: %s)" % [s["lock_type"], s["suggestion"], s["urgency"]])
 kaelen_suggestions_label.text = "SUGESTÕES: " + ("\n".join(texts) if texts else "—")

func _on_balance_mode_changed(new_mode: String) -> void:
 var color: Color
 match new_mode:
  "ETHER": color = Color(0.3, 0.7, 1.0)
  "FURY": color = Color(1.0, 0.3, 0.2)
  "SYMBIOSIS": color = Color(0.8, 0.5, 1.0)
  _: color = Color.WHITE
 combat_feedback.show_status_effect(Vector2(640, 50), new_mode)
 update_balance_ui()

func _on_boss_defeated(boss_name: String) -> void:
 can_interact = false
 await screen_effects.flash_white()
 combat_feedback.show_status_effect(Vector2(640, 360), boss_name + " DERROTADO!")
 await get_tree().create_timer(2.0).timeout
 show_victory_screen()

func _on_boss_spell_charging(_boss_name: String, spell_name: String, _turns_left: int) -> void:
 combat_feedback.show_status_effect(Vector2(640, 200), "PERIGO: " + spell_name + " se preparando!")
 combat_feedback.shake_light()

# === Handlers sistemas §6-7 ===

func _on_traversal_completed(traversal_type: String) -> void:
  combat_feedback.show_status_effect(Vector2(640, 300), "TRAVESSIA: " + traversal_type)
  if progression_system:
    progression_system.add_memory(10)
    progression_system.add_experience(25)
  _collect_traversal_loot()
  _update_progression_hud()

## §7.2 Coleta de ingredientes: a travessia é a exploração do mundo.
## Drop ponderado por raridade (common 60% / uncommon 30% / rare 10%).
func _collect_traversal_loot() -> void:
  var roll: float = randf() * 100.0
  var target_rarity: String = "common"
  if roll >= 90.0:
    target_rarity = "rare"
  elif roll >= 60.0:
    target_rarity = "uncommon"
  var pool: Array[String] = []
  for ing_id: String in cooking_system.INGREDIENTS:
    if cooking_system.INGREDIENTS[ing_id]["rarity"] == target_rarity:
      pool.append(ing_id)
  if pool.is_empty():
    return
  var picked: String = pool[randi() % pool.size()]
  cooking_system.collect_ingredient(picked, 1)
  combat_feedback.show_status_effect(Vector2(640, 340), "ENCONTROU: " + cooking_system.INGREDIENTS[picked]["name"])

func _on_camp_rest_completed(healed_units: Array) -> void:
 combat_feedback.show_status_effect(Vector2(640, 300), "ACAMPAMENTO: %d unidades restauradas" % healed_units.size())
 if progression_system:
  progression_system.add_experience(15)
  progression_system.add_memory(5)
 _update_progression_hud()

func _on_bond_level_changed(apostle_name: String, new_level: int) -> void:
 combat_feedback.show_status_effect(Vector2(640, 300), "VÍNCULO: " + apostle_name + " nível " + str(new_level))

func _on_recipe_crafted(recipe_name: String, bonuses: Dictionary) -> void:
 combat_feedback.show_status_effect(Vector2(640, 300), "RECEITA: " + recipe_name)
 if progression_system:
  progression_system.add_experience(20)
  progression_system.add_memory(10)
 _apply_cooked_heal(bonuses)
 _update_progression_hud()

func _apply_cooked_heal(bonuses: Dictionary) -> void:
 # §7.2: hp/mp de receita curam imediatamente as units jogador (não mexe em max)
 var heal_hp: int = bonuses.get("hp", 0)
 var heal_mp: int = bonuses.get("mp", 0)
 if heal_hp <= 0 and heal_mp <= 0:
  return
 for unit: Unit in BattleManager.player_units:
  if not unit.data or not unit.data.is_player:
   continue
  if heal_hp > 0:
   unit.heal(heal_hp)
  if heal_mp > 0:
   unit.current_mp = mini(unit.data.max_mp, unit.current_mp + heal_mp)
 if heal_hp > 0 or heal_mp > 0:
  combat_feedback.show_status_effect(Vector2(640, 340), "RECUPEROU +%d HP / +%d MP" % [heal_hp, heal_mp])

func _cooking_attack_multiplier() -> float:
 # Buff de cozinha §7.2: cada ponto de "attack" soma 10% ao dano do atacante.
 # Sem buffs ativos retorna 1.0 (neutro). ponytail: 10%/ponto é flat;
 # calibrar na tabela de receitas se precisar de curva.
 if not cooking_system:
  return 1.0
 var attack_bonus: int = cooking_system.get_total_bonuses().get("attack", 0)
 return 1.0 + attack_bonus * 0.1


func _cooking_defense_bonus() -> int:
 # Buff de cozinha §7.2: "defense" soma à defesa do alvo (reduz dano recebido).
 if not cooking_system:
  return 0
 return cooking_system.get_total_bonuses().get("defense", 0)

func _on_tavern_game_over(winner: String, loser: String) -> void:
 combat_feedback.show_status_effect(Vector2(640, 300), "TABERNA: " + winner + " vence!")
 if progression_system:
  progression_system.add_named_soul()
 _update_progression_hud()

# === Funções de atualização de UI ===

func update_combo_ui() -> void:
 if not combo_label:
  return
 var cp = combo_system.get_cp()
 combo_label.text = "CP: %d/3" % cp
 for i in range(3):
  if i < cp:
   combo_dots[i].color = Color(1.0, 0.8, 0.2)  # Dourado quando ativo
  else:
   combo_dots[i].color = Color(0.3, 0.3, 0.3)  # Cinza quando vazio

func update_balance_ui() -> void:
 if not balance_bar or not balance_label:
  return
 var ether: int = balance_system.get_ether()
 var fury: int = balance_system.get_fury()
 var mode: String = balance_system.get_current_mode()

 # Barra bipolar: equilíbrio (ether == fury) no centro 50; Éter puxa p/ esquerda,
 # Fúria p/ direita. Escala 0..100 (MAX_VALUE).
 balance_bar.value = 50 + (ether - fury) / 2

 # Label do modo (get_current_mode retorna String)
 match mode:
  "NEUTRAL": balance_label.text = "Neutro"
  "ETHER": balance_label.text = "Modo Éter"
  "FURY": balance_label.text = "Modo Fúria"
  "SYMBIOSIS": balance_label.text = "SIMBIOSE!"

 # Cor da barra baseada no modo
 var bar_fill = StyleBoxFlat.new()
 match mode:
  "ETHER": bar_fill.bg_color = Color(0.3, 0.7, 1.0)  # Azul para Éter
  "FURY": bar_fill.bg_color = Color(1.0, 0.3, 0.2)  # Vermelho para Fúria
  "SYMBIOSIS": bar_fill.bg_color = Color(0.8, 0.5, 1.0)  # Roxo para Simbiose
  _: bar_fill.bg_color = Color(0.5, 0.5, 0.5)  # Cinza para Neutro
 balance_bar.add_theme_stylebox_override("fill", bar_fill)

func show_boss_hp(boss_name: String, hp: int, max_hp: int) -> void:
 if boss_panel:
  boss_panel.visible = true
  boss_name_label.text = boss_name
  boss_hp_bar.max_value = max_hp
  boss_hp_bar.value = hp

func hide_boss_hp() -> void:
 if boss_panel:
  boss_panel.visible = false

# === HUD de Progressão §6-8 ===

## Feedback visual + stat application quando a forma do protagonista evolui.
## Conectado a CharacterProgression.form_changed (§8 / ROADMAP #6).
func _on_protagonist_form_changed(old_form: String, new_form: String) -> void:
 # Flash do FormLabel + status effect para o jogador notar a evolução no mundo.
 if progression_hud:
  var form_label := progression_hud.find_child("FormLabel", true, false) as Label
  if form_label:
   form_label.text = "FORMA: " + new_form
   form_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
   form_label.modulate = Color(3, 3, 2)
 if combat_feedback:
  combat_feedback.show_status_effect(Vector2(640, 300), "EVOLUÇÃO: " + old_form + " → " + new_form)
 _update_progression_hud()
 _apply_protagonist_form_stats(new_form)

## Aplica os multiplicadores de stats da forma nova na unit viva do Kael.
func _apply_protagonist_form_stats(new_form: String) -> void:
 if not GameManager or not GameManager.character_progression:
  return
 var form_data: Dictionary = GameManager.character_progression.get_form_info(new_form)
 if form_data.is_empty():
  return
 for unit: Unit in BattleManager.player_units:
  if not unit.data or not unit.data.is_player:
   continue
  if unit.data.unit_name != "Kael":
   continue
  var stats := GameManager.character_progression.get_protagonist_stats()
  if unit.data.current_hp > 0:
   var hp_ratio := float(unit.data.current_hp) / float(unit.data.max_hp)
   unit.data.max_hp = stats.get("hp", unit.data.max_hp)
   unit.data.current_hp = int(unit.data.max_hp * hp_ratio)
   unit.data.attack = stats.get("attack", unit.data.attack)
   unit.data.defense = stats.get("defense", unit.data.defense)
   unit.data.magic = stats.get("magic", unit.data.magic)
   unit.data.speed = stats.get("speed", unit.data.speed)
   # P0-3: a evolução é VISÍVEL — sprite da unit vira a png da forma nova.
   _swap_protagonist_sprite(unit, new_form)

## Troca a textura do sprite da unit para a png da forma nova (§8 / P0-3).
## Reusa o NÓ do sprite (animator mantém a referência); png ausente → mantém atual.
func _swap_protagonist_sprite(unit: Unit, new_form: String) -> void:
 var new_sprite := _load_hd_sprite("res://assets/sprites/" + _sprite_key(new_form) + ".png")
 if new_sprite == null:
  return
 var old_sprite := _find_unit_sprite(unit)
 if old_sprite == null:
  new_sprite.free()
  return
 old_sprite.texture = new_sprite.texture
 old_sprite.scale = new_sprite.scale
 _normalize_sprite_to_tile(old_sprite)  # 1024px cru → célula de 32px
 new_sprite.free()

## Primeiro Sprite2D filho da unit (nome automático "@Sprite2D@N" impede path fixo).
func _find_unit_sprite(unit: Unit) -> Sprite2D:
 if unit == null:
  return null
 if unit.has_node("Sprite2D"):
  return unit.get_node("Sprite2D") as Sprite2D
 for child in unit.get_children():
  if child is Sprite2D:
   return child as Sprite2D
 return null

func _update_progression_hud() -> void:
 if not progression_hud or not progression_system:
  return
 var summary: Dictionary = progression_system.get_progress_summary()

 # Labels ficam em HBox aninhados; find_child por nome evita path frágil
 var act_label = progression_hud.find_child("ActLabel", true, false) as Label
 var mem_label = progression_hud.find_child("MemLabel", true, false) as Label
 var soul_label = progression_hud.find_child("SoulLabel", true, false) as Label
 var xp_label = progression_hud.find_child("XPLabel", true, false) as Label
 var form_label = progression_hud.find_child("FormLabel", true, false) as Label

 if act_label:
  act_label.text = "ATO %d" % summary.get("current_act", 1)
 if mem_label:
  mem_label.text = "MEM %d%%" % summary.get("memory_percent", 0)
 if soul_label:
  soul_label.text = "ALMAS %d" % summary.get("named_souls", 0)
 if xp_label:
  xp_label.text = "XP %d" % summary.get("total_xp", 0)
 if form_label:
  form_label.text = "FORMA: %s" % summary.get("protagonist_form", "???")

# === Painel de Ações §6-7 ===
# Excita os sinais já conectados em setup_systems(), ligando o runtime ao
# feedback visual (toast + HUD de progressão) dos sistemas Traversal/Camp/
# Cooking/Tavern.

func _on_forge_pressed() -> void:
 # Forja (§7, AUDIT P1 #12): painel de seleção — jogador escolhe o item;
 # disponibilidade vem das flags da vila (Fornalha/Forja do Rei Ogro).
 if _forge_panel != null and is_instance_valid(_forge_panel):
  _forge_panel.visible = not _forge_panel.visible
  return
 _build_forge_panel()
 _forge_panel.visible = true


func _sync_equipment() -> EquipmentSystemLib:
 var equipment = EquipmentSystemLib.new()
 equipment.set_unlocked_features(GameManager.building_system.unlocked_features if GameManager else {})
 var res: Dictionary = GameManager.building_system.resources if GameManager else {}
 equipment.set_resources({"materials": res.get("materials", 0), "gold": res.get("gold", 0), "soul_ether": res.get("soul_ether", 0)})
 return equipment


func _on_forge_item_pressed(equipment_id: String) -> void:
 var equipment := _sync_equipment()
 var check: Dictionary = equipment.can_craft(equipment_id)
 if not check.can:
  combat_feedback.show_status_effect(Vector2(640, 300), "FORJA: " + check.reason)
  return
 var item: Dictionary = equipment.get_equipment(equipment_id)
 for resource: String in item["cost"]:
  GameManager.building_system.spend_resources({resource: item["cost"][resource]})
 var result: Dictionary = equipment.craft(equipment_id)
 if result.ok:
  GameManager.apply_equipment_bonuses(result.bonuses, equipment_id, item["slot"])
  combat_feedback.show_status_effect(Vector2(640, 300), "FORJA: %s equipado!" % item["name"])
  if SoundManager:
   SoundManager.play_forge()
  if GameManager.has_method("save_game"):
   GameManager.save_game()  # bônus permanente + inventário da vila no save
 # Atualiza a painel (custos/estado mudaram).
 _forge_panel.queue_free()
 _forge_panel = null
 _build_forge_panel()
 _forge_panel.visible = true


# --- Handlers de excitação (disparam métodos que emitem sinais §6-7) ---

func _on_camp_pressed() -> void:
 if _camp_used:
  combat_feedback.show_status_effect(Vector2(640, 300), "ACAMPA: já usado nesta batalha")
  return
 _camp_used = true
 var party: Array = BattleManager.player_units
 campfire_system.rest_at_campfire("central", party)


func _on_cook_pressed() -> void:
 if _cook_used:
  combat_feedback.show_status_effect(Vector2(640, 300), "COZINHA: já usado nesta batalha")
  return
 _cook_used = true
 # Painel de seleção (mesmo padrão da Forja): jogador escolhe prato ou
 # elixir. Elixires (§7.2) viram bônus PERMANENTES no GameManager.
 if _cook_panel != null and is_instance_valid(_cook_panel):
  _cook_panel.visible = not _cook_panel.visible
  return
 _build_cook_panel()
 _cook_panel.visible = true


func _on_cook_item_pressed(recipe_id: String, is_food: bool) -> void:
 if not cooking_system.can_craft(recipe_id):
  combat_feedback.show_status_effect(Vector2(640, 300), "COZINHA: sem ingredientes")
  return
 var bonuses: Dictionary = cooking_system.craft(recipe_id)
 if bonuses.is_empty():
  return
 if is_food:
  combat_feedback.show_status_effect(Vector2(640, 300), "COZINHA: %s preparado!" % cooking_system.get_all_recipes()[recipe_id]["name"])
 else:
  GameManager.apply_elixir_bonuses(bonuses)
  combat_feedback.show_status_effect(Vector2(640, 300), "ELIXIR: bônus permanente aplicado!")
  if SoundManager:
   SoundManager.play_heal()
  if GameManager.has_method("save_game"):
   GameManager.save_game()  # bônus permanente no save
 # Atualiza o painel (ingredientes mudaram).
 _cook_panel.queue_free()
 _cook_panel = null
 _build_cook_panel()
 _cook_panel.visible = true


func _on_tavern_pressed() -> void:
 if _tavern_running:
  return
 # Aposta (ROADMAP #12): 10 ouro de entrada, pago no início; vitória paga 2x.
 # Sem ouro suficiente, a mesa joga casual (aposta 0).
 var bet := TAVERN_BET if GameManager.game_data.gold >= TAVERN_BET else 0
 if bet > 0:
  GameManager.add_gold(-bet)
 tavern_minigame.start_game("Jogador", "IA", bet)
 tavern_minigame.bet_resolved.connect(_on_tavern_bet_resolved)
 tavern_minigame.exclusive_reward_earned.connect(_on_tavern_exclusive_reward)
 _tavern_running = true
 _run_tavern_until_end()


func _on_tavern_bet_resolved(won: bool, payout: int) -> void:
 if payout > 0:
  GameManager.add_gold(payout)
 if SoundManager:
  SoundManager.play_bet_win() if won else SoundManager.play_bet_lose()
 var msg := "TABERNA: você venceu! +%d ouro" % payout if won else "TABERNA: derrota... aposta perdida."
 combat_feedback.show_status_effect(Vector2(640, 300), msg)


func _on_tavern_exclusive_reward(reward_id: String) -> void:
 var tiers: Dictionary = tavern_minigame.get_reward_tiers()
 for tier in tiers.values():
  if tier["id"] == reward_id:
   combat_feedback.show_status_effect(Vector2(640, 200), "RECOMPENSA: " + tier["name"])
   if progression_system:
    progression_system.add_named_soul()
   return


func _run_tavern_until_end() -> void:
 # ponytail: autobattler demo — ambos os lados jogam a primeira runa jogável
 # automaticamente. Stall (ninguém pode jogar) encerra no _tavern_turn_limit.
 # _advance_turn só roda via play_rune(), então o turno avança quando há jogo.
 var turns := 0
 while tavern_minigame.is_game_active() and turns < _tavern_turn_limit:
  var current := tavern_minigame.get_current_turn()
  var rune := _pick_tavern_rune(current)
  if not rune.is_empty():
   tavern_minigame.play_rune(current, rune)
  await get_tree().create_timer(0.25).timeout
  turns += 1
 _tavern_running = false


func _pick_tavern_rune(player_id: String) -> String:
 if not tavern_minigame.is_game_active():
  return ""
 for rune_id: String in tavern_minigame.get_player_hand(player_id):
  if tavern_minigame.can_play_rune(player_id, rune_id):
   return rune_id
 return ""


func _on_traverse_pressed() -> void:
  traversal_system.setup(true, 100)
  var result: Dictionary = traversal_system.start_traversal("dash")
  if not result.get("can", false):
    traversal_system.regen_stamina(100)
    traversal_system.start_traversal("dash")
  # Dash é instantâneo: finaliza na hora para emitir traversal_completed
  # (que alimenta memory + XP no handler).
  traversal_system.end_traversal()


func _on_combo_pressed() -> void:
  if not _try_use_combo():
    combat_feedback.show_status_effect(Vector2(640, 300), "COMBO: sem CP ou sem participantes")


## §3.3 Ativa a primeira combo disponível (CP suficiente + participantes no campo).
func _try_use_combo() -> bool:
  var participants: Array[String] = []
  for unit: Unit in BattleManager.player_units:
    if unit.data and unit.data.is_player:
      participants.append(unit.data.unit_name)
  for combo: Dictionary in combo_system.get_available_combos(participants):
    if combo_system.activate_combo(combo, participants):
      return true
  return false

