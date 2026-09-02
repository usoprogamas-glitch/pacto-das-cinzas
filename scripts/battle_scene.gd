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

func setup_ui() -> void:
 phase_label.text = "FASE: JOGADOR"
 turn_label.text = "Turno: 1"
 soul_ether_label.text = "Soul Éter: 0"
 unit_info_panel.visible = false
 action_menu.visible = false

 move_button.pressed.connect(_on_move_pressed)
 attack_button.pressed.connect(_on_attack_pressed)
 wait_button.pressed.connect(_on_wait_pressed)

 # UI de Combo Points (canto inferior esquerdo)
 _create_combo_ui()

 # UI de Éter/Fúria (canto inferior direito)
 _create_balance_ui()

 # UI de Boss HP (topo)
 _create_boss_ui()

 # HUD de Progressão §6-8 (top-right)
 _create_progression_hud()
 _update_progression_hud()

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
 ui_layer.add_child(panel)

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

 kaelen_bio_weaknesses = Label.new()
 kaelen_bio_weaknesses.text = "Fraquezas: —"
 kaelen_bio_weaknesses.add_theme_font_size_override("font_size", 11)
 kaelen_bio_weaknesses.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_bio_weaknesses)

 kaelen_bio_fatigue = Label.new()
 kaelen_bio_fatigue.text = "Fadiga: —"
 kaelen_bio_fatigue.add_theme_font_size_override("font_size", 11)
 kaelen_bio_fatigue.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_bio_fatigue)

 kaelen_bio_armor = Label.new()
 kaelen_bio_armor.text = "Armadura: —"
 kaelen_bio_armor.add_theme_font_size_override("font_size", 11)
 kaelen_bio_armor.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_bio_armor)

 # Vetor Psicológico
 var psycho_title = Label.new()
 psycho_title.text = "VETOR PSICOLÓGICO"
 psycho_title.add_theme_font_size_override("font_size", 12)
 psycho_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
 vbox.add_child(psycho_title)

 kaelen_psy_morale = Label.new()
 kaelen_psy_morale.text = "Moral: —"
 kaelen_psy_morale.add_theme_font_size_override("font_size", 11)
 kaelen_psy_morale.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_psy_morale)

 kaelen_psy_flee = Label.new()
 kaelen_psy_flee.text = "Fuga: —"
 kaelen_psy_flee.add_theme_font_size_override("font_size", 11)
 kaelen_psy_flee.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_psy_flee)

 # Vetor Tático
 var tactical_title = Label.new()
 tactical_title.text = "VETOR TÁTICO"
 tactical_title.add_theme_font_size_override("font_size", 12)
 tactical_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
 vbox.add_child(tactical_title)

 kaelen_tac_locks = Label.new()
 kaelen_tac_locks.text = "Locks: —"
 kaelen_tac_locks.add_theme_font_size_override("font_size", 11)
 kaelen_tac_locks.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_tac_locks)

 kaelen_tac_threat = Label.new()
 kaelen_tac_threat.text = "Ameaça: —"
 kaelen_tac_threat.add_theme_font_size_override("font_size", 11)
 kaelen_tac_threat.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_tac_threat)

 kaelen_tac_range = Label.new()
 kaelen_tac_range.text = "Alcance: —"
 kaelen_tac_range.add_theme_font_size_override("font_size", 11)
 kaelen_tac_range.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
 vbox.add_child(kaelen_tac_range)

 # Separator
 var sep2 = HSeparator.new()
 sep2.add_theme_color_override("font_color", Color(0.2, 0.4, 0.6))
 vbox.add_child(sep2)

 # Sugestões de Lock Break
 kaelen_suggestions_label = Label.new()
 kaelen_suggestions_label.text = "SUGESTÕES: —"
 kaelen_suggestions_label.add_theme_font_size_override("font_size", 11)
 kaelen_suggestions_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4))
 vbox.add_child(kaelen_suggestions_label)

 kaelen_hud_panel = panel

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
 ui_layer.add_child(panel)

 var vbox = VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 4)
 panel.add_child(vbox)

 combo_label = Label.new()
 combo_label.text = "CP: 0/3"
 combo_label.add_theme_font_size_override("font_size", 14)
 combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
 combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
 combo_label.add_theme_constant_override("shadow_offset_x", 2)
 combo_label.add_theme_constant_override("shadow_offset_y", 2)
 vbox.add_child(combo_label)

 # Dots visuais para CP (maiores, com glow)
 var dots_container = HBoxContainer.new()
 dots_container.add_theme_constant_override("separation", 6)
 vbox.add_child(dots_container)

 for i in range(3):
  var dot = ColorRect.new()
  dot.size = Vector2(20, 20)
  dot.color = Color(0.2, 0.2, 0.2)
  dots_container.add_child(dot)
  combo_dots.append(dot)

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
 ui_layer.add_child(panel)

 var vbox = VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 4)
 panel.add_child(vbox)

 balance_label = Label.new()
 balance_label.text = "Neutro"
 balance_label.add_theme_font_size_override("font_size", 13)
 balance_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
 balance_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
 balance_label.add_theme_constant_override("shadow_offset_x", 2)
 balance_label.add_theme_constant_override("shadow_offset_y", 2)
 balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 vbox.add_child(balance_label)

 balance_bar = ProgressBar.new()
 balance_bar.size = Vector2(150, 16)
 balance_bar.max_value = 100
 balance_bar.value = 50
 var bar_bg = StyleBoxFlat.new()
 bar_bg.bg_color = Color(0.15, 0.15, 0.15)
 bar_bg.set_corner_radius_all(4)
 balance_bar.add_theme_stylebox_override("background", bar_bg)
 var bar_fill = StyleBoxFlat.new()
 bar_fill.bg_color = Color(0.5, 0.5, 0.5)
 bar_fill.set_corner_radius_all(4)
 balance_bar.add_theme_stylebox_override("fill", bar_fill)
 vbox.add_child(balance_bar)

func _create_boss_ui() -> void:
 # Painel de Boss HP (topo central, inicialmente oculto)
 boss_panel = PanelContainer.new()
 boss_panel.position = Vector2(340, 8)
 boss_panel.size = Vector2(600, 60)
 boss_panel.visible = false
 var panel_style = StyleBoxFlat.new()
 panel_style.bg_color = Color(0.08, 0.02, 0.02, 0.9)
 panel_style.border_color = Color(0.7, 0.15, 0.1)
 panel_style.set_border_width_all(2)
 panel_style.set_corner_radius_all(4)
 boss_panel.add_theme_stylebox_override("panel", panel_style)
 ui_layer.add_child(boss_panel)

 var vbox = VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 2)
 boss_panel.add_child(vbox)

 boss_name_label = Label.new()
 boss_name_label.text = "Boss"
 boss_name_label.add_theme_font_size_override("font_size", 16)
 boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
 boss_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
 boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
 boss_name_label.add_theme_constant_override("shadow_offset_y", 2)
 boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 vbox.add_child(boss_name_label)

 boss_hp_bar = ProgressBar.new()
 boss_hp_bar.size = Vector2(580, 20)
 boss_hp_bar.max_value = 500
 boss_hp_bar.value = 500
 var hp_bg = StyleBoxFlat.new()
 hp_bg.bg_color = Color(0.15, 0.05, 0.05)
 hp_bg.set_corner_radius_all(3)
 boss_hp_bar.add_theme_stylebox_override("background", hp_bg)
 var hp_fill = StyleBoxFlat.new()
 hp_fill.bg_color = Color(0.85, 0.15, 0.1)
 hp_fill.set_corner_radius_all(3)
 boss_hp_bar.add_theme_stylebox_override("fill", hp_fill)
 vbox.add_child(boss_hp_bar)

func setup_battle() -> void:
 # BGM data-driven (P0-4): o campo "music" do mapa (exploration/battle) nunca
 # era lido — batalhas rodavam em silêncio de fundo.
 var current_map_for_music = MapDatabase.get_map(GameManager.game_data.get("current_map", 0))
 if current_map_for_music and SoundManager:
  SoundManager.play_music(current_map_for_music.get("music", "exploration"))

 # Inicializar sistema de autotile para o mapa (aplicado sobre a camada de terreno do grid)
 autotile_system.auto_tile_map(grid.terrain_layer, 0, Rect2i(0, 0, 12, 12))
 autotile_system.setup_animated_tiles(grid.terrain_layer)
 autotile_system.apply_random_variations(grid.terrain_layer, Rect2i(0, 0, 12, 12), 0.15)

 # Root-cause fix: spawnar o grupo principal ANTES dos inimigos. Antes disso o
 # caminho de current_map spawnava só inimigos -> instant loss. DRY: helper
 # único, usado também pelo fallback abaixo.
 _spawn_player_party()

 # Obter o mapa atual
 var current_map = MapDatabase.get_map(GameManager.game_data.get("current_map", 0))
 if current_map:
  # Pool de inimigos resolvido de forma data-driven (ROADMAP #8): o estágio
  # pode declarar "boss_enemy" para substituir o pool do mapa (Ato I
  # compartilha o mapa 0 com batalhas comuns); Atos II-IV têm pool próprio
  # no mapa (Cardeais/Aurius, 1 unidade).
  var pool = _resolve_enemy_pool(current_map)
  var enemies = pool.enemies
  var enemy_count = pool.count

  var enemy_positions = MapDatabase.get_enemy_spawn_positions(GameManager.game_data.get("current_map", 0), enemy_count)

  for i in range(min(enemy_count, enemy_positions.size())):
   var enemy_type = enemies[randi() % enemies.size()]
   var enemy_data = EnemyDatabase.get_enemy(enemy_type)
   if enemy_data:
    spawn_enemy_unit(enemy_positions[i], enemy_data.name, Color(enemy_data.color.r, enemy_data.color.g, enemy_data.color.b), enemy_data.class, enemy_data.hp, enemy_data.atk, enemy_data.def, enemy_data.mov, enemy_data.rng)
 else:
  # Fallback para spawn padrão (reusa o helper acima — uma só fonte de verdade)
  spawn_enemy_unit(Vector2i(9, 5), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
  spawn_enemy_unit(Vector2i(10, 6), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
  spawn_enemy_unit(Vector2i(8, 4), "Caçador", Color(0.6, 0.3, 0.3), "Arqueiro", 45, 16, 5, 4, 3)

 # Iniciar tutorial na primeira batalha
 if not FileAccess.file_exists("user://tutorial_completed"):
  tutorial_system.start_tutorial()

# Pool de inimigos da batalha (ROADMAP #8): fonte de verdade data-driven.
# Estágio de campanha pode declarar "boss_enemy" (chefe sem mapa próprio);
# caso contrário vale o pool do mapa (Cardeais/Aurius já definidos lá).
func _resolve_enemy_pool(current_map: Dictionary) -> Dictionary:
 var enemies: Array = current_map.get("enemies", [])
 var enemy_count: int = current_map.get("enemy_count", 1)
 if GameManager and GameManager.campaign_system:
  var stage: Dictionary = GameManager.campaign_system.get_current_stage()
  var boss_enemy: String = stage.get("boss_enemy", "")
  if boss_enemy != "":
   enemies = [boss_enemy]
   enemy_count = 1
 return {"enemies": enemies, "count": enemy_count}

func _spawn_player_party() -> void:
 # Stats de CharacterProgression (runtime) — literais preservam o balanço herdado
 # (atk Kael = 12 literal, não o default 8 de protagonist_stats.stats).
 var stats: Dictionary = {}
 if GameManager and GameManager.character_progression:
  stats = GameManager.character_progression.get_protagonist_stats()
 var hp: int = stats.get("hp", 80)
 var atk: int = 12
 var def: int = 8
 # Fonte da verdade: GameManager.party_data (persistida no save). Fallback para
 # jogo novo / caminho legado sem party registrada.
 var party: Array[Dictionary] = []
 if GameManager and GameManager.party_data and not GameManager.party_data.is_empty():
  party = GameManager.party_data
 else:
  party = [{"name": "Kael", "class": "Imp Menor", "hp": hp, "atk": atk, "def": def, "mov": 3, "rng": 1}]
  if GameManager and GameManager.game_data.get("starting_ally") == "kroug":
   party.append({"name": "Kroug", "class": "Goblin da Lama", "hp": 120, "atk": 10, "def": 15, "mov": 2, "rng": 1})
 for i in range(party.size()):
  var m: Dictionary = party[i]
  var grid_pos = Vector2i(2 + i, 6)
  spawn_player_unit(
   grid_pos,
   m.get("name", "Kael"),
   _party_color(m.get("name", "")),
   m.get("class", "Imp Menor"),
   int(m.get("hp", 80)),
   int(m.get("atk", atk)),
   int(m.get("def", def)),
   int(m.get("mov", 3)),
   int(m.get("rng", 1))
  )
 _spawn_named_souls(_party_names(party))

func _party_names(party: Array) -> Array:
 var names: Array = []
 for m in party:
  names.append(m.get("name", ""))
 return names

func _party_color(member_name: String) -> Color:
 match member_name:
  "Kroug":
   return Color(0.8, 0.3, 0.1)
  "Lira":
   return Color(0.3, 0.8, 0.4)
  "Thal'kor":
   return Color(0.4, 0.3, 0.8)
  _:
   return Color(0.2, 0.8, 0.3)


# Spawna as almas nomeadas do save (NamingSystem) como aliados vivos, usando o
# NOME real persistido + stats evoluídos (ROADMAP #9). Almas canônicas já
# spawnadas (Kroug via starting_ally) são puladas por nome.
func _spawn_named_souls(spawned: Array = []) -> void:
 if not GameManager or not GameManager.naming_system:
  return
 # Slots ao redor do Kael (evita sobreposição em party grande).
 var offsets: Array[Vector2i] = [
  Vector2i(3, 6), Vector2i(1, 5), Vector2i(3, 7), Vector2i(2, 8), Vector2i(3, 5)
 ]
 var idx: int = 0
 for soul in GameManager.naming_system.get_all_souls():
  if idx >= offsets.size():
   break
  var soul_name: String = soul.get("name", "Alma Nomeada")
  if soul_name in spawned:
   continue
  var soul_stats: Dictionary = soul.get("stats", {})
  var hp_val: int = soul_stats.get("hp", 80)
  var atk_val: int = soul_stats.get("attack", 10)
  var def_val: int = soul_stats.get("defense", 8)
  spawn_player_unit(offsets[idx], soul_name, Color(0.6, 0.6, 0.9), soul.get("original_type", "Monstro"), hp_val, atk_val, def_val, 2, 1)
  spawned.append(soul_name)
  idx += 1

func spawn_player_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
 var unit = create_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng, true)
 BattleManager.register_unit(unit)
 return unit

func spawn_enemy_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
 var unit = create_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng, false)
 BattleManager.register_unit(unit)
 # §5 Boss runtime: classe Boss = chefe no campo → sincroniza BossSystem (panel + HP).
 # Cardinal resolvido pelo NOME da unidade (antes: por classe → todos viravam Ignis).
 if unit_class == "Boss" and _resolve_cardinal_name(unit_name) != "":
  _spawn_runtime_boss(unit)
 return unit

## Vincula o boss em campo ao BossSystem: nome/cardinal resolvido por nome, HP da Unit real.
func _spawn_runtime_boss(unit: Unit) -> void:
 var cardinal: String = _resolve_cardinal_name(unit.data.unit_name)
 boss_system.spawn_runtime_boss(cardinal, unit.data.max_hp)
 unit.hp_changed.connect(func(hp: int) -> void: boss_system.sync_runtime_hp(hp))

## Nome da unidade → cardinal do BossSystem (data-driven):
## - Cardeais: o nome do EnemyDatabase CASA com a chave de BossSystem.CARDINALS.
## - Aurius: as 3 fases têm nomes distintos no EnemyDatabase → todas viram "Aurius".
## - "Santo Cardeal" (mapa lateral 4): mantém o binding legado com Ignis.
## - Demais nomes: "" (não é chefe conhecido).
func _resolve_cardinal_name(unit_name: String) -> String:
 if boss_system and boss_system.CARDINALS.has(unit_name):
  return unit_name
 if unit_name.begins_with("Aurius"):
  return "Aurius"
 if unit_name == "Santo Cardeal":
  return "Ignis"
 return ""

func create_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int, is_player: bool) -> Unit:
 var unit = Unit.new()
 unit.name = unit_name

 # Criar sprite visual usando PixelArtRenderer
 var sprite = create_unit_sprite(unit_name, color, is_player)
 unit.add_child(sprite)

 var hp_bar = ProgressBar.new()
 hp_bar.name = "HPBar"
 hp_bar.position = Vector2(-16, -24)
 hp_bar.size = Vector2(32, 5)
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
 selection.color = Color(1, 1, 0, 0.4)
 selection.position = Vector2(-4, -4)
 selection.size = Vector2(40, 40)
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

 var inst = _place_unit(unit, grid_pos)
 if not inst:
  return null

 # Criar animador
 var animator = UnitAnimator.new()
 animator.name = "Animator"
 (unit as Node).add_child(animator)
 animator.setup(unit)
 # Chave por instância: 2 inimigos de mesmo nome ("Mercenário" ×2) compartilhavam
 # UMA entrada → animações tocavam na unidade errada. Instance ID é único.
 unit_animators[unit.get_instance_id()] = animator
 animator.play_idle()

 # Aplicar efeitos visuais avançados
 if pixel_art_renderer and pixel_art_renderer.has_method("apply_all_effects"):
  pixel_art_renderer.apply_all_effects(sprite, _sprite_key(unit_name))

 return unit

# Coloca a unit no grid/rótulo. Isolado p/ stubbing: testes de spawn chamam
# _spawn_player_party sem árvore (sem $BattleGrid/$UnitContainer); a variante
# real usa grid à vista, a variante de teste stub usa um fake geométrico.
## Normaliza o sprite à célula do grid (BattleGrid.TILE_SIZE): sprites HD
## (1024px) e procedurais (64-128px) chegam em tamanhos heterogêneos — sem isto,
## o sprite HD é 32x a célula (GDD §10.1: sprites 32x32).
func _normalize_sprite_to_tile(sprite: Sprite2D) -> void:
 if sprite == null or sprite.texture == null:
  return
 var effective := sprite.texture.get_width() * sprite.scale.x
 if effective <= 0.0:
  return
 var factor := float(BattleGrid.TILE_SIZE) / effective
 sprite.scale *= factor

func _place_unit(unit, grid_pos: Vector2i) -> bool:
 unit.grid_position = grid_pos
 if grid:
  unit.position = grid.grid_to_pixel(grid_pos)
 elif unit.has_method("set_grid_position"):
  unit.set_grid_position(grid_pos)
 if unit_container:
  unit_container.add_child(unit)
  return true
 return false

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

func create_unit_sprite(unit_name: String, color: Color, is_player: bool) -> Sprite2D:
 # Factory única de sprite de unidade: toda saída sai normalizada à célula
 # (BattleGrid.TILE_SIZE) — HD 1024px e procedurais 64-128px entram cruos.
 var sprite = _create_unit_sprite_raw(unit_name, color, is_player)
 _normalize_sprite_to_tile(sprite)
 return sprite

func _create_unit_sprite_raw(unit_name: String, color: Color, is_player: bool) -> Sprite2D:
 # HD 2D: usa textura de assets/sprites/<key>.png se existir (gerada via ComfyUI).
 # Fallback: PixelArtRenderer procedural.
 var char_key = _sprite_key(unit_name)
 var hd = _load_hd_sprite("res://assets/sprites/" + char_key + ".png")
 if hd:
  return hd

 # Usar PixelArtRenderer para sprites detalhados
 match char_key:
  "kael":
   return pixel_art_renderer.create_kael("imp")
  "kroug":
   return pixel_art_renderer.create_kroug()
  "lira":
   return pixel_art_renderer.create_lira()
  "thal'kor", "thalkor":
   return pixel_art_renderer.create_thalkor()
  "mercenário", "mercenario":
   return pixel_art_renderer.create_enemy("mercenario")
  "guerreiro":
   return pixel_art_renderer.create_enemy("mercenario")
  "caçador", "cacador":
   return pixel_art_renderer.create_enemy("cacador")
  "arqueiro":
   return pixel_art_renderer.create_enemy("cacador")
  "inquisidor":
   return pixel_art_renderer.create_enemy("inquisidor")
  "paladino":
   return pixel_art_renderer.create_enemy("paladino")
  "troll":
   return pixel_art_renderer.create_enemy("troll")
  "lobo_sombrio":
   return pixel_art_renderer.create_enemy("lobo_sombrio")
  "aranha_gigante":
   return pixel_art_renderer.create_enemy("aranha_gigante")
  "esqueleto":
   return pixel_art_renderer.create_enemy("esqueleto")
  "cardeal", "santo_cardeal":
   return pixel_art_renderer.create_enemy("cardeal")
  _:
   # Fallback para sprite procedural se não encontrado
   return _create_fallback_sprite(color, is_player)

## Normaliza nome de unidade → chave de arquivo sprite (minúsculo, sem acento/
## apóstrofo/em-dash, underscores únicos). Ex.: "Aurius — Falso Demiurgo" →
## "aurius_falso_demiurgo", "Arquidemônio" → "arquidemonio".
func _sprite_key(unit_name: String) -> String:
 var key := unit_name.to_lower()
 for pair in [["—", ""], ["'", ""], ["á", "a"], ["é", "e"], ["ê", "e"], ["â", "a"], ["ã", "a"], ["õ", "o"], ["ô", "o"], ["í", "i"], ["ú", "u"], ["ç", "c"], [" ", "_"]]:
  key = key.replace(pair[0], pair[1])
 while "__" in key:
  key = key.replace("__", "_")
 return key

## HD 2D: carrega textura png de assets/sprites se existir; null → fallback procedural.
## Pre-check file_exists (P0-6): img.load em arquivo ausente imprime ERROR no
## console para CADA probe (fantasma/teia/guerreiro...) — mascara erros reais.
func _load_hd_sprite(path: String) -> Sprite2D:
 var img := Image.new()
 if not FileAccess.file_exists(path):
  return null
 if img.load(path) != OK:
  return null
 var sprite = Sprite2D.new()
 sprite.texture = ImageTexture.create_from_image(img)
 return sprite

func _create_fallback_sprite(color: Color, is_player: bool) -> Sprite2D:
 var sprite = Sprite2D.new()
 var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
 image.fill(Color(0, 0, 0, 0))
 
 var base_color = color if is_player else color.darkened(0.3)
 
 # Desenhar personagem simples mas melhorado
 var center = 32
 
 # Corpo
 for y in range(center - 10, center + 10):
  for x in range(center - 8, center + 8):
   if x >= 0 && x < 64 && y >= 0 && y < 64:
    var dist = sqrt(pow(x - center, 2) + pow(y - center, 2))
    if dist < 10:
     var shade = 1.0 - dist / 10.0
     if shade > 0.7:
      image.set_pixel(x, y, base_color.lightened(0.3))
     elif shade > 0.4:
      image.set_pixel(x, y, base_color)
     else:
      image.set_pixel(x, y, base_color.darkened(0.3))

 # Olhos
 var eye_color = Color.WHITE if is_player else Color("#FF4444")
 image.set_pixel(center - 4, center - 4, eye_color)
 image.set_pixel(center + 4, center - 4, eye_color)
 image.set_pixel(center - 3, center - 3, Color.BLACK)
 image.set_pixel(center + 3, center - 3, Color.BLACK)

 var texture = ImageTexture.create_from_image(image)
 var sprite_node = Sprite2D.new()
 sprite_node.texture = texture
 sprite_node.scale = Vector2(1.5, 1.5)

 return sprite_node

func _input(event: InputEvent) -> void:
 # Timed Block: o clique reativo vale mesmo fora do turno do jogador
 # (a janela abre durante o ENEMY_TURN, quando can_interact é false).
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _timed_block_active:
  _resolve_block_input()
  return
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

 # Se timed hit está ativo, processar timing
 if _timed_hit_active:
  var elapsed = (Time.get_ticks_msec() / 1000.0) - _timed_hit_start_time
  var grade = timed_combat.resolve_timing(elapsed)
  _apply_attack_result(_timed_hit_target, grade.multiplier, grade.label)
  _timed_hit_active = false
  return

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
  kaelen_system.analyze_target(target_data)

func deselect_unit() -> void:
 selected_unit = null
 is_unit_selected = false
 grid.clear_highlights()
 hide_unit_info()
 hide_action_menu()
 if kaelen_hud_panel and kaelen_hud_panel.visible:
  kaelen_hud_panel.visible = false

func move_selected_unit(grid_pos: Vector2i) -> void:
 if selected_unit and not selected_unit.has_moved:
  # Animação de movimento
  var animator = _get_animator(selected_unit)
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
  # Iniciar timed hit
  _timed_hit_active = true
  _timed_hit_start_time = Time.get_ticks_msec() / 1000.0
  _timed_hit_target = target

  # Mostrar indicador visual
  combat_feedback.show_status_effect(target.global_position + Vector2(0, -40), "TIMED HIT!")

  # Esperar input do jogador (timer de 0.3s)
  await get_tree().create_timer(TimedCombatSystem.ATTACK_WINDOW).timeout

  # Se jogador não clicou a tempo, aplicar dano sem bônus
  if _timed_hit_active:
   _apply_attack_result(target, 1.0, "MISS")


# --- Timed Block: defesa reativa (espelho do timed hit, GDD v2 §3.1) ---

## Chamado pelo BattleManager quando um ataque inimigo mira um aliado jogador:
## abre a janela de 0.2s e aguarda o clique reativo antes do dano ser aplicado.
func _resolve_timed_block(_attacker: Unit, target: Unit) -> float:
 _timed_block_active = true
 _timed_block_start_time = Time.get_ticks_msec() / 1000.0
 _timed_block_reduction = 0.0

 combat_feedback.show_status_effect(target.global_position + Vector2(0, -40), "TIMED BLOCK!")
 SoundManager.play_select()

 # Espera o input do jogador dentro da janela (0.2s) e devolve a redução
 # para o pipeline de dano do BattleManager.
 await get_tree().create_timer(TimedCombatSystem.BLOCK_WINDOW).timeout
 _timed_block_active = false
 return _timed_block_reduction


## Clique reativo dentro da janela: gradua o timing e trava a redução obtida.
func _resolve_block_input() -> void:
 var elapsed = (Time.get_ticks_msec() / 1000.0) - _timed_block_start_time
 var result = timed_combat.resolve_block_timing(elapsed)
 _timed_block_reduction = timed_combat.get_block_reduction(result)

 combat_feedback.show_status_effect(Vector2(640, 300), "BLOCK " + result.grade)
 if _timed_block_reduction > 0.0:
  combat_feedback.shake_light()
  SoundManager.play_hit()


func _apply_attack_result(target: Unit, multiplier: float, grade: String) -> void:
 if not selected_unit or not target:
  return

 # Animação de ataque
 var attacker_animator = _get_animator(selected_unit)
 if attacker_animator:
  await attacker_animator.play_attack(target)

 SoundManager.play_hit()
 combat_feedback.shake_light()

 # Aplicar dano com bônus de timing + buffs de cozinha §7.2 via BattleManager
 BattleManager.attack_unit(selected_unit, target, "", "", multiplier * _cooking_attack_multiplier(), _cooking_defense_bonus())

 # Mostrar grade de timing
 combat_feedback.show_status_effect(target.global_position + Vector2(0, -30), grade)

 # Ganhar Éter por timing perfeito
 if grade == "PERFECT":
  balance_system.apply_action("buff_ally")  # +8 Éter
  update_balance_ui()

 # Animação de dano no alvo
 var target_animator = _get_animator(target)
 if target_animator:
  target_animator.play_hit()

 # Ganhar CP por Perfect
 if grade == "PERFECT":
  combo_system.earn_from_timed_hit(grade)
  update_combo_ui()

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
 # Atualizar UI dos sistemas a cada turno
 update_combo_ui()
 update_balance_ui()
 # Buffs de cozinha §7.2 decaem a cada turno; expirados viram toast
 if cooking_system:
  for buff_name: String in cooking_system.tick_bonuses():
   combat_feedback.show_status_effect(Vector2(640, 300), "BUFF EXPIRADO: " + buff_name)

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
 var animator = _get_animator(unit)
 if animator:
  await animator.play_death()

 SoundManager.play_death()
 combat_feedback.shake_medium()

 if unit.data and not unit.data.is_player:
  battle_stats.enemies_defeated += 1
  var soul_type = unit.data.soul_type if unit.data else ""
  if soul_type != "":
   captured_souls.add(soul_type, unit.data.unit_name)

 # Verificar vitória
 check_battle_end()

## Animator da unidade por instância (ver unit_animators).
func _get_animator(unit: Unit) -> UnitAnimator:
 return unit_animators.get(unit.get_instance_id())


func check_battle_end() -> void:
 if BattleManager.player_units.size() == 0:
  BattleManager.battle_lost.emit()
 elif BattleManager.enemy_units.size() == 0:
  BattleManager.battle_won.emit()

func _on_battle_won() -> void:
 _commit_progression()  # persiste progresso da batalha no GameManager antes de sair
 can_interact = false

 # Fix: soul_ether e souls_named nunca chegavam ao result screen antes.
 battle_stats["soul_ether"] = BattleManager.soul_ether
 if captured_souls.has_captured():
  battle_stats["souls_named"] += captured_souls.souls.size()

 # Campanha: boss encerra o ato; estágio normal avança o estágio — ambos persistem.
 if GameManager and GameManager.campaign_system:
  if GameManager.campaign_system.is_act_boss_stage():
   _on_boss_stage_cleared()
  else:
   GameManager.campaign_system.advance_stage()
   if GameManager.has_method("save_game"):
    GameManager.save_game()

 # Efeitos visuais
 await screen_effects.flash_white()
 combat_feedback.spawn_level_up_effect(Vector2(640, 360))

 # Mostrar tela de vitória
 await get_tree().create_timer(1.0).timeout
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
 if not captured_souls.has_captured():
  return
 var dialog = load("res://scenes/naming_ui.tscn").instantiate()
 add_child(dialog)
 var types: Array[String] = []
 for s in captured_souls.souls:
  types.append(s["type"])
 dialog.populate_soul_list(types)

 # Kaelen System (§3.4): analisar monstros selvagens capturados para preview de evolução.
 # O resultado (analysis) não é usado ainda — só a chamada garante a integração.
 for s in captured_souls.souls:
  var monster_data = {"type": s["type"], "name": s["display_name"]}
  kaelen_system.analyze_wild_monster(monster_data)

 dialog.soul_named.connect(func(soul_type: String, custom_name: String) -> void:
  if GameManager and GameManager.naming_system:
   GameManager.naming_system.name_soul(soul_type, custom_name)
   if GameManager.faith_system:
    GameManager.faith_system.register_apostle(custom_name)
 )
 await dialog.back_pressed
 dialog.queue_free()
 captured_souls.clear()

func _on_battle_lost() -> void:
 can_interact = false

 # Efeitos visuais
 await screen_effects.flash_red()
 screen_effects.slow_motion(0.3, 1.0)

 # Mostrar tela de derrota
 await get_tree().create_timer(1.5).timeout
 show_defeat_screen()

func _commit_progression() -> void:
 # autoload ausente em teste isolado → no-op seguro (mesmo padrão das linhas 316)
 if not GameManager or not progression_system:
  return
 var gm_prog: ProgressionSystem = GameManager.progression_system
 if not gm_prog:
  return
 # Transferir o acumulado da batalha para o sistema persistente do save
 if progression_system.total_memory > 0:
  gm_prog.add_memory(progression_system.total_memory)
 if progression_system.total_experience > 0:
  gm_prog.add_experience(progression_system.total_experience)
 for i in progression_system.named_souls:
  gm_prog.add_named_soul()
 # Fé: cada vitória fortalece o pacto — todos os apóstolos registrados ganham lealdade
 # (reusa add_faith, que emite faith_changed/faith_level_up; antes a fé era estática)
 var faith: FaithSystem = GameManager.faith_system
 if faith:
  for apostle in faith.get_all_apostles():
   faith.add_faith(apostle, 10)

func _on_soul_ether_gained(amount: int) -> void:
 soul_ether_label.text = "Soul Éter: %d" % BattleManager.soul_ether
 combat_feedback.show_status_effect(Vector2(640, 100), "Soul Éter +%d" % amount)

func show_victory_screen() -> void:
 # Criar tela de vitória dinamicamente
 var result_screen = load("res://scenes/battle_result_screen.tscn").instantiate()
 add_child(result_screen)
 result_screen.show_victory(battle_stats)
 result_screen.restart_pressed.connect(_on_restart)
 result_screen.menu_pressed.connect(_on_menu)
 result_screen.continue_pressed.connect(_on_continue)

func show_defeat_screen() -> void:
 var result_screen = load("res://scenes/battle_result_screen.tscn").instantiate()
 add_child(result_screen)
 result_screen.show_defeat(battle_stats)
 result_screen.restart_pressed.connect(_on_restart)
 result_screen.menu_pressed.connect(_on_menu)

func _on_restart() -> void:
 get_tree().reload_current_scene()

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

func _create_progression_hud() -> void:
 progression_hud = PanelContainer.new()
 progression_hud.position = Vector2(960, 8)
 progression_hud.size = Vector2(310, 70)
 var style = StyleBoxFlat.new()
 style.bg_color = Color(0.03, 0.05, 0.09, 0.88)
 style.border_color = Color(0.25, 0.4, 0.6)
 style.set_border_width_all(2)
 style.set_corner_radius_all(6)
 progression_hud.add_theme_stylebox_override("panel", style)
 ui_layer.add_child(progression_hud)

 var vbox = VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 4)
 progression_hud.add_child(vbox)

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

func _create_actions_panel() -> void:
 actions_panel = PanelContainer.new()
 actions_panel.position = Vector2(960, 82)
 actions_panel.size = Vector2(310, 140)
 var style = StyleBoxFlat.new()
 style.bg_color = Color(0.03, 0.05, 0.09, 0.88)
 style.border_color = Color(0.6, 0.45, 0.2)
 style.set_border_width_all(2)
 style.set_corner_radius_all(6)
 actions_panel.add_theme_stylebox_override("panel", style)
 ui_layer.add_child(actions_panel)

 var vbox = VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 4)
 actions_panel.add_child(vbox)

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

 _add_action_button(grid, "Acampar", _on_camp_pressed)
 _add_action_button(grid, "Cozinhar", _on_cook_pressed)
 _add_action_button(grid, "Taberna", _on_tavern_pressed)
 _add_action_button(grid, "Travessia", _on_traverse_pressed)
 _add_action_button(grid, "Forja", _on_forge_pressed)
 _add_action_button(grid, "Combo", _on_combo_pressed)


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


func _build_forge_panel() -> void:
 _forge_panel = PanelContainer.new()
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
 style.border_color = Color(0.5, 0.45, 0.3)
 style.set_border_width_all(2)
 style.set_corner_radius_all(6)
 _forge_panel.add_theme_stylebox_override("panel", style)
 _forge_panel.position = Vector2(400, 200)
 _forge_panel.custom_minimum_size = Vector2(480, 0)
 var vbox := VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 6)
 _forge_panel.add_child(vbox)
 var title := Label.new()
 title.text = "FORJA — escolha o equipamento"
 title.add_theme_font_size_override("font_size", 18)
 title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
 vbox.add_child(title)
 var equipment := _sync_equipment()
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
  btn.pressed.connect(_on_forge_item_pressed.bind(equipment_id))
  row.add_child(btn)
  vbox.add_child(row)
 var close := Button.new()
 close.text = "Fechar"
 close.custom_minimum_size = Vector2(140, 26)
 close.pressed.connect(func() -> void: _forge_panel.visible = false)
 vbox.add_child(close)
 ui_layer.add_child(_forge_panel)


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
 btn.pressed.connect(handler)
 parent.add_child(btn)


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


func _build_cook_panel() -> void:
 _cook_panel = PanelContainer.new()
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
 style.border_color = Color(0.5, 0.45, 0.3)
 style.set_border_width_all(2)
 style.set_corner_radius_all(6)
 _cook_panel.add_theme_stylebox_override("panel", style)
 _cook_panel.position = Vector2(400, 200)
 _cook_panel.custom_minimum_size = Vector2(480, 0)
 var vbox := VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 6)
 _cook_panel.add_child(vbox)
 var title := Label.new()
 title.text = "COZINHA — escolha a receita"
 title.add_theme_font_size_override("font_size", 18)
 title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
 vbox.add_child(title)
 for recipe_id: String in cooking_system.RECIPES:
  _add_cook_row(vbox, recipe_id, cooking_system.RECIPES[recipe_id], true)
 for elixir_id: String in cooking_system.ELIXIRS:
  _add_cook_row(vbox, elixir_id, cooking_system.ELIXIRS[elixir_id], false)
 var close := Button.new()
 close.text = "Fechar"
 close.custom_minimum_size = Vector2(140, 26)
 close.pressed.connect(func() -> void: _cook_panel.visible = false)
 vbox.add_child(close)
 ui_layer.add_child(_cook_panel)


func _add_cook_row(vbox: VBoxContainer, recipe_id: String, recipe: Dictionary, is_food: bool) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 8)
 var info := Label.new()
 var cost_parts := PackedStringArray()
 for ing_id: String in recipe["ingredients"]:
  cost_parts.append("%dx %s" % [int(recipe["ingredients"][ing_id]), cooking_system.get_all_ingredients().get(ing_id, {}).get("name", ing_id)])
 var cost_text := ", ".join(cost_parts)
 var suffix := "" if is_food else "  [PERMANENTE]"
 info.text = "%s%s\nCusto: %s" % [recipe["name"], suffix, cost_text]
 info.add_theme_font_size_override("font_size", 13)
 info.custom_minimum_size = Vector2(320, 0)
 row.add_child(info)
 var btn := Button.new()
 if cooking_system.can_craft(recipe_id):
  btn.text = "Cozinhar"
 else:
  btn.text = "Sem ingredientes"
  btn.disabled = true
 btn.custom_minimum_size = Vector2(140, 28)
 btn.pressed.connect(_on_cook_item_pressed.bind(recipe_id, is_food))
 row.add_child(btn)
 vbox.add_child(row)


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

