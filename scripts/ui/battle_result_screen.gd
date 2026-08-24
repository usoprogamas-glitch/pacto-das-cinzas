class_name BattleResultScreen
extends Control

signal restart_pressed()
signal menu_pressed()
signal continue_pressed()

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var rewards_label: Label = $VBoxContainer/RewardsLabel
@onready var restart_button: Button = $VBoxContainer/ButtonContainer/RestartButton
@onready var menu_button: Button = $VBoxContainer/ButtonContainer/MenuButton
@onready var continue_button: Button = $VBoxContainer/ButtonContainer/ContinueButton

var is_victory: bool = false

func _ready() -> void:
 restart_button.pressed.connect(_on_restart)
 menu_button.pressed.connect(_on_menu)
 continue_button.pressed.connect(_on_continue)

func show_victory(stats: Dictionary) -> void:
 is_victory = true
 visible = true

 title_label.text = "VITÓRIA!"
 title_label.add_theme_color_override("font_color", Color("#FFD93D"))

 var stats_text = ""
 stats_text += "Turnos: %d\n" % stats.get("turns", 0)
 stats_text += "Inimigos derrotados: %d\n" % stats.get("enemies_defeated", 0)
 stats_text += "Dano total: %d\n" % stats.get("total_damage", 0)
 stats_text += "Dano recebido: %d\n" % stats.get("damage_taken", 0)
 stats_text += "Almas nomeadas: %d\n" % stats.get("souls_named", 0)
 stats_label.text = stats_text

 var rewards_text = ""
 rewards_text += "Soul Éter: +%d\n" % stats.get("soul_ether", 0)
 rewards_text += "Ouro: +%d\n" % stats.get("gold", 0)
 rewards_text += "Experiência: +%d\n" % stats.get("experience", 0)
 rewards_label.text = rewards_text

 continue_button.visible = true
 restart_button.visible = false

func show_defeat(stats: Dictionary) -> void:
 is_victory = false
 visible = true

 title_label.text = "DERROTA..."
 title_label.add_theme_color_override("font_color", Color("#FF5252"))

 var stats_text = ""
 stats_text += "Turnos sobrevividos: %d\n" % stats.get("turns", 0)
 stats_text += "Inimigos derrotados: %d\n" % stats.get("enemies_defeated", 0)
 stats_text += "Dano total causado: %d\n" % stats.get("total_damage", 0)
 stats_label.text = stats_text

 rewards_label.text = "Nenhuma recompensa"

 continue_button.visible = false
 restart_button.visible = true

func _on_restart() -> void:
 restart_pressed.emit()

func _on_menu() -> void:
 menu_pressed.emit()

func _on_continue() -> void:
 continue_pressed.emit()
