extends Control

@onready var map_list: ItemList = $VBoxContainer/MapList
@onready var map_info: Label = $VBoxContainer/MapInfo
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var act_label: Label = $VBoxContainer/ActLabel

var maps: Array[Dictionary] = [
 {
  "id": 0,
  "name": "Fronteira Cinzenta",
  "description": "Onde tudo começou. Terreno baldio com vegetação morta.",
  "difficulty": 1,
  "unlocked": true,
  "act": 1
 },
 {
  "id": 1,
  "name": "Floresta Sombria",
  "description": "Floresta densa e perigosa. Lobo Sombrios e Aranhas.",
  "difficulty": 2,
  "unlocked": true,
  "act": 2
 },
 {
  "id": 2,
  "name": "Caverna Profunda",
  "description": "Sistema de cavernas com cristais brilhantes. Esqueletos e Trolls.",
  "difficulty": 3,
  "unlocked": false,
  "act": 3
 },
 {
  "id": 3,
  "name": "Castelo Solaris",
  "description": "A fortaleza da Igreja. Paladinos e Inquisidores.",
  "difficulty": 4,
  "unlocked": false,
  "act": 4
 },
 {
  "id": 4,
  "name": "Vulcão do Abismo",
  "description": "Terra de ninguém. Feras elementais e lava.",
  "difficulty": 5,
  "unlocked": false,
  "act": 4
 }
]

var selected_map: int = 0

func _ready() -> void:
 populate_map_list()
 start_button.pressed.connect(_on_start)
 back_button.pressed.connect(_on_back)
 map_list.item_selected.connect(_on_map_selected)
 _update_act_label()

# Campaign gate: a map is playable only if its act is reachable.
# Falls back to the hard-coded `unlocked` field when there is no CampaignSystem
# (e.g. isolated tests / dead path), preserving prior behavior exactly.
func _is_map_playable(m: Dictionary) -> bool:
 if GameManager and GameManager.campaign_system:
  return GameManager.campaign_system.is_stage_playable(m.id)
 return m.unlocked

func _update_act_label() -> void:
 if GameManager and GameManager.campaign_system:
  var act = GameManager.campaign_system.current_act
  var act_names = {1: "ATO I — FRONTEIRA CINZENTA", 2: "ATO II — O DESPERTAR", 3: "ATO III — GUERRA FRIA", 4: "ATO IV — QUEDA DE SOLARIA"}
  act_label.text = act_names.get(act, "ATO %d" % act)
 else:
  act_label.text = "ATO I — FRONTEIRA CINZENTA"

func populate_map_list() -> void:
 map_list.clear()
 for map in maps:
  var playable = _is_map_playable(map)
  var lock = "🔒" if not playable else "⭐".repeat(map.difficulty)
  # Show act badge for context
  var act_badge = "  [Ato %d]" % map.act
  map_list.add_item("%s %s%s" % [lock, map.name, act_badge])

func _on_map_selected(index: int) -> void:
 selected_map = index
 var map = maps[index]
 map_info.text = "%s\n\nDificuldade: %s\nAto: %d\n\n%s" % [
  map.name,
  "⭐".repeat(map.difficulty),
  map.act,
  map.description
 ]
 start_button.disabled = not _is_map_playable(map)

func _on_start() -> void:
 if _is_map_playable(maps[selected_map]):
  GameManager.game_data["current_map"] = maps[selected_map]["id"]
  SceneManager.change_scene("battle")

func _on_back() -> void:
 SceneManager.change_scene("main_menu")