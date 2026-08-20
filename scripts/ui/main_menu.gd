extends Control

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
 new_game_button.pressed.connect(_on_new_game)
 continue_button.pressed.connect(_on_continue)
 settings_button.pressed.connect(_on_settings)
 quit_button.pressed.connect(_on_quit)

 # Verificar se há save
 continue_button.disabled = not FileAccess.file_exists("user://save_game.json")

 # Animação de título
 animate_title()

func animate_title() -> void:
 title_label.modulate.a = 0.0
 var tween = create_tween()
 tween.tween_property(title_label, "modulate:a", 1.0, 1.0)

func _on_new_game() -> void:
 GameManager.start_new_game()
 SceneManager.change_scene("map_select")

func _on_continue() -> void:
 if GameManager.load_game():
  SceneManager.change_scene("village")
 else:
  print("Erro ao carregar save")

func _on_settings() -> void:
 SceneManager.change_scene("settings")

func _on_quit() -> void:
 get_tree().quit()
