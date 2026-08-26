class_name GameManagerClass
extends Node

signal game_started()
signal game_paused()
signal game_resumed()
signal scene_changed(scene_name: String)
signal intro_completed(choices: Dictionary)

var faith_system: FaithSystem
var building_system: BuildingSystem
var ability_system: AbilitySystem
var progression_system: ProgressionSystem
var intro_story: Control  # Instância de IntroStory (evita dependência circular de class_name)

var current_scene: String = "intro"
var game_data: Dictionary = {
 "protagonist_name": "Kael",
 "protagonist_form": "Imp Menor",
 "soul_ether": 0,
 "gold": 0,
 "turn_count": 0,
 "chapter": 1,
 "mana": 120,
 "starting_ally": "none",
 "kaelen_approval": 0,
 "difficulty": "normal",
 "knowledge_bonus": false,
 "first_pact": false,
  "progression": {}
}

func _ready() -> void:
 initialize_systems()
 connect_intro_story()

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

 progression_system = ProgressionSystem.new()
 progression_system.name = "ProgressionSystem"
 add_child(progression_system)

 var intro_script = load("res://scripts/ui/intro_story.gd")
 if intro_script:
  intro_story = intro_script.new()
  intro_story.name = "IntroStory"
  add_child(intro_story)

func connect_intro_story() -> void:
 if intro_story and intro_story.has_signal("intro_completed"):
  intro_story.intro_completed.connect(_on_intro_completed)

func _on_intro_completed(choices: Dictionary) -> void:
 # Aplicar escolhas do jogador
 for key in choices:
  var choice = choices[key]
  if choice.consequence == "first_pact":
   game_data.starting_ally = "kroug"
   game_data.first_pact = true
   game_data.mana -= 15
  elif choice.consequence == "lone_survivor":
   game_data.starting_ally = "none"
   game_data.kaelen_approval = -10
   game_data.difficulty = "hard"
  elif choice.consequence == "cautious_start":
   game_data.starting_ally = "none"
   game_data.knowledge_bonus = true
   game_data.mana += 10
   game_data.difficulty = "normal"

 # Aplicar bônus de conhecimento se escolhido
 if game_data.knowledge_bonus:
  # Desbloquear conhecimento extra
  pass

 # Iniciar jogo propriamente dito
 start_new_game()

func start_new_game() -> void:
 game_data = {
  "protagonist_name": "Kael",
  "protagonist_form": "Imp Menor",
  "soul_ether": 0,
  "gold": 0,
  "turn_count": 0,
  "chapter": 1,
  "mana": game_data.mana,
  "starting_ally": game_data.starting_ally,
  "kaelen_approval": game_data.kaelen_approval,
  "difficulty": game_data.difficulty,
  "knowledge_bonus": game_data.knowledge_bonus,
  "first_pact": game_data.first_pact
 }

 # Registrar aliados baseado na escolha
 if game_data.starting_ally == "kroug":
  faith_system.register_apostle("Kroug")
  # K25 de fé inicial por ser o primeiro pacto
  faith_system.add_faith("Kroug", 25)
 elif game_data.starting_ally == "none":
  # Sem aliado inicial
  pass

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
 if progression_system:
  game_data["progression"] = progression_system.serialize()
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
    if progression_system and save_data.game_data.has("progression"):
      progression_system.deserialize(save_data.game_data.progression)
    return true
  return false
