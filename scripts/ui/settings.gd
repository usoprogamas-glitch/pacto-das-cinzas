extends Control
## Menu de Opções (simples): volume da música/SFX e modo de janela.
## Existia apenas para o botão "Opções" do main_menu — o path settings.tscn
## apontava para um arquivo inexistente, quebrando change_scene_to_file.

@onready var volume_slider: HSlider = $VBoxContainer/VolumeBox/VolumeSlider
@onready var volume_value: Label = $VBoxContainer/VolumeBox/VolumeValue
@onready var fullscreen_check: CheckButton = $VBoxContainer/FullscreenCheck
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
 # Conectar sinais (padrão do projeto: connect no _ready; indentação 1 espaço)
 volume_slider.value_changed.connect(_on_volume_changed)
 fullscreen_check.toggled.connect(_on_fullscreen_toggled)
 back_button.pressed.connect(_on_back)

 # Carregar estado persistido (usuário local)
 var cfg = ConfigFile.new()
 if cfg.load("user://settings.cfg") == OK:
  volume_slider.value = cfg.get_value("audio", "master_volume", 0.8)
  fullscreen_check.button_pressed = cfg.get_value("video", "fullscreen", false)
 else:
  volume_slider.value = 0.8
  fullscreen_check.button_pressed = false

 _on_volume_changed(volume_slider.value)
 _apply_fullscreen(fullscreen_check.button_pressed)

func _on_volume_changed(value: float) -> void:
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
 AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value <= 0.01)
 volume_value.text = "%d%%" % int(value * 100)
 _save()

func _on_fullscreen_toggled(enabled: bool) -> void:
 _apply_fullscreen(enabled)
 _save()

func _apply_fullscreen(enabled: bool) -> void:
 if enabled:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
 else:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save() -> void:
 var cfg = ConfigFile.new()
 cfg.set_value("audio", "master_volume", volume_slider.value)
 cfg.set_value("video", "fullscreen", fullscreen_check.button_pressed)
 cfg.save("user://settings.cfg")

func _on_back() -> void:
 SceneManager.go_to_main_menu()