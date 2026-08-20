extends Control

@onready var building_list: ItemList = $VBoxContainer/BuildingList
@onready var building_info: Label = $VBoxContainer/BuildingInfo
@onready var build_button: Button = $VBoxContainer/BuildButton
@onready var soul_ether_label: Label = $TopBar/SoulEtherLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var back_button: Button = $BackButton

var selected_building: String = ""

func _ready() -> void:
 populate_buildings()
 build_button.pressed.connect(_on_build)
 back_button.pressed.connect(_on_back)
 building_list.item_selected.connect(_on_building_selected)
 update_resources()

func populate_buildings() -> void:
 building_list.clear()
 var buildings = GameManager.building_system.get_all_buildings()
 for building in buildings:
  var status = "✅" if building.level > 0 else "⬜"
  var level = "Nv.%d/%d" % [building.level, building.max_level] if building.level > 0 else "Não construído"
  building_list.add_item("%s %s - %s" % [status, building.name, level])

func _on_building_selected(index: int) -> void:
 var buildings = GameManager.building_system.get_all_buildings()
 selected_building = buildings[index].id
 var info = GameManager.building_system.get_building_info(selected_building)

 var text = "%s\n\n%s\n\nNível: %d/%d\n\nCusto para próximo nível:\n" % [
  info.name,
  info.description,
  info.level,
  info.max_level
 ]

 for resource in info.cost:
  text += "- %s: %d\n" % [resource, info.cost[resource]]

 if info.level >= info.max_level:
  text += "\n✅ Nível máximo atingido!"

 building_info.text = text
 build_button.disabled = not info.can_build

func _on_build() -> void:
 if selected_building and GameManager.building_system.build(selected_building):
  populate_buildings()
  update_resources()
  _on_building_selected(building_list.get_selected_items()[0])

func update_resources() -> void:
 soul_ether_label.text = "Soul Éter: %d" % GameManager.building_system.get_resource_amount("soul_ether")
 gold_label.text = "Ouro: %d" % GameManager.building_system.get_resource_amount("gold")

func _on_back() -> void:
 SceneManager.change_scene("main_menu")
