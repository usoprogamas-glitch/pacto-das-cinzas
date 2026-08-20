class_name BattleUI
extends CanvasLayer

signal action_selected(action: String)
signal target_selected(unit: Unit)

@onready var phase_label: Label = $PhaseLabel
@onready var turn_label: Label = $TurnLabel
@onready var soul_ether_label: Label = $SoulEtherLabel
@onready var faith_label: Label = $FaithLabel

@onready var unit_info_panel: PanelContainer = $UnitInfoPanel
@onready var unit_name_label: Label = $UnitInfoPanel/VBox/UnitName
@onready var unit_class_label: Label = $UnitInfoPanel/VBox/UnitClass
@onready var unit_hp_bar: ProgressBar = $UnitInfoPanel/VBox/HPBar
@onready var unit_hp_label: Label = $UnitInfoPanel/VBox/HPLabel
@onready var unit_mp_bar: ProgressBar = $UnitInfoPanel/VBox/MPBar
@onready var unit_mp_label: Label = $UnitInfoPanel/VBox/MPLabel
@onready var unit_atk_label: Label = $UnitInfoPanel/VBox/ATKLabel
@onready var unit_def_label: Label = $UnitInfoPanel/VBox/DEFLabel
@onready var unit_faith_bar: ProgressBar = $UnitInfoPanel/VBox/FaithBar
@onready var unit_faith_label: Label = $UnitInfoPanel/VBox/FaithLabel

@onready var action_menu: PanelContainer = $ActionMenu
@onready var move_button: Button = $ActionMenu/VBox/MoveButton
@onready var attack_button: Button = $ActionMenu/VBox/AttackButton
@onready var ability_button: Button = $ActionMenu/VBox/AbilityButton
@onready var wait_button: Button = $ActionMenu/VBox/WaitButton

@onready var ability_list: ItemList = $AbilityList
@onready var end_turn_button: Button = $EndTurnButton

@onready var message_label: Label = $MessageLabel
@onready var damage_popup: Label = $DamagePopup

var current_unit: Unit = null

func _ready() -> void:
 setup_connections()

func setup_connections() -> void:
 move_button.pressed.connect(func(): action_selected.emit("move"))
 attack_button.pressed.connect(func(): action_selected.emit("attack"))
 ability_button.pressed.connect(func(): action_selected.emit("ability"))
 wait_button.pressed.connect(func(): action_selected.emit("wait"))
 end_turn_button.pressed.connect(func(): action_selected.emit("end_turn"))

func update_phase_label(phase: String) -> void:
 phase_label.text = "FASE: " + phase

func update_turn_label(turn: int) -> void:
 turn_label.text = "Turno: %d" % turn

func update_soul_ether(amount: int) -> void:
 soul_ether_label.text = "Soul Éter: %d" % amount

func update_faith_label(faith_system: FaithSystem, unit_name: String) -> void:
 var faith = faith_system.get_faith(unit_name)
 faith_label.text = "Fé: %d/100" % faith

func show_unit_info(unit: Unit) -> void:
 current_unit = unit
 unit_info_panel.visible = true

 unit_name_label.text = unit.data.unit_name
 unit_class_label.text = unit.data.unit_class

 unit_hp_bar.max_value = unit.data.max_hp
 unit_hp_bar.value = unit.current_hp
 unit_hp_label.text = "HP: %d/%d" % [unit.current_hp, unit.data.max_hp]

 unit_mp_bar.max_value = unit.data.max_mp
 unit_mp_bar.value = unit.current_mp
 unit_mp_label.text = "MP: %d/%d" % [unit.current_mp, unit.data.max_mp]

 unit_atk_label.text = "ATK: %d" % unit.data.attack
 unit_def_label.text = "DEF: %d" % unit.data.defense

func update_unit_info_hp(unit: Unit) -> void:
 if current_unit == unit:
  unit_hp_bar.value = unit.current_hp
  unit_hp_label.text = "HP: %d/%d" % [unit.current_hp, unit.data.max_hp]

func hide_unit_info() -> void:
 unit_info_panel.visible = false
 current_unit = null

func show_action_menu(unit: Unit) -> void:
 action_menu.visible = true
 move_button.disabled = unit.has_moved
 attack_button.disabled = unit.has_acted
 ability_button.disabled = unit.has_acted
 wait_button.disabled = false

func hide_action_menu() -> void:
 action_menu.visible = false

func show_ability_list(abilities: Array) -> void:
 ability_list.clear()
 ability_list.visible = true
 for ability in abilities:
  ability_list.add_item(ability)

func hide_ability_list() -> void:
 ability_list.visible = false

func show_message(text: String, duration: float = 2.0) -> void:
 message_label.text = text
 message_label.visible = true
 await get_tree().create_timer(duration).timeout
 message_label.visible = false

func show_damage_popup(position: Vector2, damage: int, is_heal: bool = false) -> void:
 damage_popup.position = position
 if is_heal:
  damage_popup.text = "+%d" % damage
  damage_popup.modulate = Color.GREEN
 else:
  damage_popup.text = "-%d" % damage
  damage_popup.modulate = Color.RED
 damage_popup.visible = true

 var tween = create_tween()
 tween.tween_property(damage_popup, "position:y", position.y - 30, 0.5)
 tween.parallel().tween_property(damage_popup, "modulate:a", 0.0, 0.5)
 await tween.finished
 damage_popup.visible = false

func update_button_states(can_move: bool, can_act: bool) -> void:
 move_button.disabled = not can_move
 attack_button.disabled = not can_act
 ability_button.disabled = not can_act
