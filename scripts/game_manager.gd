extends Node

signal game_started()
signal game_paused()
signal game_resumed()
signal scene_changed(scene_name: String)

var faith_system: FaithSystem
var building_system: BuildingSystem
var ability_system: AbilitySystem

var current_scene: String = "battle"
var game_data: Dictionary = {
 "protagonist_name": "Kael",
 "protagonist_form": "Imp Menor",
 "soul_ether": 0,
 "gold": 0,
 "turn_count": 0,
 "chapter": 1
}

func _ready() -> void:
 initialize_systems()

func initialize_systems() -> void:
 faith_system = FaithSystem.new()
 faith_system.name = "FaithSystem"
 add_child(faith_system)

 building_system = BuildingSystem.new()
 building_system.name = "BuildingSystem"
 add_child(building_system)

 ability_system = AbilitySystem.new()
 ability_system.name = "AbilitySystem"
 add_child(ability_system)

func start_new_game() -> void:
 game_data = {
  "protagonist_name": "Kael",
  "protagonist_form": "Imp Menor",
  "soul_ether": 0,
  "gold": 0,
  "turn_count": 0,
  "chapter": 1
 }

 faith_system.register_apostle("Kroug")
 faith_system.register_apostle("Lira")
 faith_system.register_apostle("Thal'kor")

 building_system.add_resource("soul_ether", 100)
 building_system.add_resource("gold", 50)

 game_started.emit()

func add_soul_ether(amount: int) -> void:
 game_data.soul_ether += amount
 building_system.add_resource("soul_ether", amount)

func add_gold(amount: int) -> void:
 game_data.gold += amount
 building_system.add_resource("gold", amount)

func get_game_data() -> Dictionary:
 return game_data

func save_game() -> void:
 var save_data = {
  "game_data": game_data,
  "faith_data": faith_system.faith_data,
  "buildings": building_system.buildings,
  "resources": building_system.resources
 }
 var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify(save_data))
  file.close()

func load_game() -> bool:
 if not FileAccess.file_exists("user://save_game.json"):
  return false

 var file = FileAccess.open("user://save_game.json", FileAccess.READ)
 if file:
  var json = JSON.new()
  var result = json.parse(file.get_as_text())
  file.close()

  if result == OK:
   var save_data = json.data
   game_data = save_data.game_data
   faith_system.faith_data = save_data.faith_data
   building_system.buildings = save_data.buildings
   building_system.resources = save_data.resources
   return true
 return false
