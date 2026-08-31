extends Control

@onready var map_list: ItemList = $VBoxContainer/MapList
@onready var map_info: Label = $VBoxContainer/MapInfo
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var act_label: Label = $VBoxContainer/ActLabel

# Fallback data-driven quando não há CampaignSystem (testes isolados / dead path).
# Em runtime, a fonte de verdade é CampaignSystem.ACT_STAGES.
var maps: Array[Dictionary] = [
 {
  "id": 0,
  "name": "Socorro aos Goblins",
  "description": "Resgatar a tribo goblin e forjar o primeiro Pacto de Alma.",
  "difficulty": 1,
  "unlocked": true,
  "act": 1,
  "boss": false
 },
 {
  "id": 0,
  "name": "O Chefe Orc",
  "description": "Derrotar o chefe orc que ameaça os goblins das cinzas.",
  "difficulty": 2,
  "unlocked": false,
  "act": 1,
  "boss": true
 },
 {
  "id": 1,
  "name": "Floresta Sombria",
  "description": "Floresta densa e perigosa. Lobo Sombrios e Aranhas.",
  "difficulty": 3,
  "unlocked": false,
  "act": 2,
  "boss": false
 },
 {
  "id": 2,
  "name": "Vale dos Despojos",
  "description": "Sistema de cavernas com cristais brilhantes. Esqueletos e Trolls.",
  "difficulty": 4,
  "unlocked": false,
  "act": 2,
  "boss": true
 },
 {
  "id": 3,
  "name": "Castelo Solaris",
  "description": "A fortaleza da Igreja. Paladinos e Inquisidores.",
  "difficulty": 4,
  "unlocked": false,
  "act": 3,
  "boss": false
 },
 {
  "id": 4,
  "name": "Cerne da Igreja",
  "description": "Terra de ninguém. Feras elementais e lava.",
  "difficulty": 5,
  "unlocked": false,
  "act": 3,
  "boss": true
 }
]

var selected_map: int = 0

func _ready() -> void:
 populate_map_list()
 start_button.pressed.connect(_on_start)
 back_button.pressed.connect(_on_back)
 map_list.item_selected.connect(_on_map_selected)
 _update_act_label()

## Fonte única de stages: CampaignSystem quando disponível; senão o fallback local.
func _stage_list() -> Array:
 if GameManager and GameManager.campaign_system:
  return GameManager.campaign_system.get_campaign_stages()
 return maps

func _is_map_playable(m: Dictionary) -> bool:
 if GameManager and GameManager.campaign_system:
  return GameManager.campaign_system.is_stage_playable(m.get("map_id", m.get("id", -1)))
 return m.get("unlocked", false)

func _update_act_label() -> void:
 if GameManager and GameManager.campaign_system:
  var act = GameManager.campaign_system.current_act
  var act_names = {1: "ATO I — FRONTEIRA CINZENTA", 2: "ATO II — O DESPERTAR", 3: "ATO III — GUERRA FRIA", 4: "ATO IV — QUEDA DE SOLARIA"}
  act_label.text = act_names.get(act, "ATO %d" % act)
 else:
  act_label.text = "ATO I — FRONTEIRA CINZENTA"

func populate_map_list() -> void:
 map_list.clear()
 var stages = _stage_list()
 for map in stages:
  var playable = _is_map_playable(map)
  var lock = "🔒" if not playable else "⭐".repeat(_stage_difficulty(map))
  var act_badge = "  [Ato %d]" % map.act
  var boss_tag = " [BOSS]" if map.get("boss", false) else ""
  map_list.add_item("%s %s%s%s" % [lock, _stage_name(map), boss_tag, act_badge])

func _stage_name(m: Dictionary) -> String:
 return m.get("name", m.get("map_name", "Estágio %d" % m.get("map_id", 0)))

func _stage_difficulty(m: Dictionary) -> int:
 return m.get("difficulty", 1)

func _on_map_selected(index: int) -> void:
 selected_map = index
 var stages = _stage_list()
 if index >= stages.size():
  return
 var map = stages[index]
 map_info.text = "%s\n\n%s\nAto: %d\n\n%s" % [
  _stage_name(map),
  "⭐".repeat(_stage_difficulty(map)),
  map.act,
  _stage_description(map)
 ]
 start_button.disabled = not _is_map_playable(map)

func _stage_description(m: Dictionary) -> String:
 return m.get("description", m.get("map_desc", ""))

func _on_start() -> void:
 var stages = _stage_list()
 if selected_map >= stages.size():
  return
 var map = stages[selected_map]
 if _is_map_playable(map):
  GameManager.game_data["current_map"] = map.get("map_id", map.get("id", 0))
  # Registrar o stage atual no CampaignSystem para o battle_scene resolver inimigos/rewards.
  if GameManager and GameManager.campaign_system:
   GameManager.campaign_system.select_map(map.get("map_id", map.get("id", 0)))
  SceneManager.change_scene("battle")

func _on_back() -> void:
 SceneManager.change_scene("main_menu")