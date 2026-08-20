extends Control

@onready var map_list: ItemList = $VBoxContainer/MapList
@onready var map_info: Label = $VBoxContainer/MapInfo
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var back_button: Button = $VBoxContainer/BackButton

var maps: Array[Dictionary] = [
 {
  "id": 0,
  "name": "Fronteira Cinzenta",
  "description": "Onde tudo começou. Terreno baldio com vegetação morta.",
  "difficulty": 1,
  "unlocked": true
 },
 {
  "id": 1,
  "name": "Floresta Sombria",
  "description": "Floresta densa e perigosa. Lobo Sombrios e Aranhas.",
  "difficulty": 2,
  "unlocked": true
 },
 {
  "id": 2,
  "name": "Caverna Profunda",
  "description": "Sistema de cavernas com cristais brilhantes. Esqueletos e Trolls.",
  "difficulty": 3,
  "unlocked": false
 },
 {
  "id": 3,
  "name": "Castelo Solaris",
  "description": "A fortaleza da Igreja. Paladinos e Inquisidores.",
  "difficulty": 4,
  "unlocked": false
 },
 {
  "id": 4,
  "name": "Vulcão do Abismo",
  "description": "Terra de ninguém. Feras elementais e lava.",
  "difficulty": 5,
  "unlocked": false
 }
]

var selected_map: int = 0

func _ready() -> void:
 populate_map_list()
 start_button.pressed.connect(_on_start)
 back_button.pressed.connect(_on_back)
 map_list.item_selected.connect(_on_map_selected)

func populate_map_list() -> void:
 map_list.clear()
 for map in maps:
  var lock = "🔒" if not map.unlocked else "⭐".repeat(map.difficulty)
  map_list.add_item("%s %s" % [lock, map.name])

func _on_map_selected(index: int) -> void:
 selected_map = index
 var map = maps[index]
 map_info.text = "%s\n\nDificuldade: %s\n\n%s" % [
  map.name,
  "⭐".repeat(map.difficulty),
  map.description
 ]
 start_button.disabled = not map.unlocked

func _on_start() -> void:
 if maps[selected_map].unlocked:
  GameManager.game_data["current_map"] = selected_map
  SceneManager.change_scene("battle")

func _on_back() -> void:
 SceneManager.change_scene("main_menu")
