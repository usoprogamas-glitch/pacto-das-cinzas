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
var character_progression: CharacterProgression  # conectado ao ProgressionSystem p/ evolucao de forma
var lineage_system: LineageSystem  # canonico (RefCounted): evolucao dos apostolos por ato
var naming_system: NamingSystem  # Pacto de Alma (GDD 2.1/4): nomear criaturas -> apostolos
var campaign_system: CampaignSystem  # Ato/stage/gating/persistencia (ROADMAP #2)

# Fonte de verdade da party do jogador (persistida no save). Cada entrada descreve
# um membro recrutado: { "name", "class", "hp", "atk", "def", "mov", "rng" }.
var party_data: Array[Dictionary] = []

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
 # ProgressionSystem extends RefCounted (nao Node) -- so guarda a referencia, nao add_child

 character_progression = CharacterProgression.new()
 character_progression.name = "CharacterProgression"
 add_child(character_progression)
 progression_system.set_character_progression(character_progression)

 # LineageSystem canonico (RefCounted) -- registrar os 4 apostolos e conectar a evolucao por ato
 lineage_system = LineageSystem.new()
 for creature_name in LineageSystem.APOSTLE_EVOLUTIONS:
  lineage_system.register_creature(creature_name)
 progression_system.set_lineage_system(lineage_system)

 # NamingSystem (Pacto de Alma, GDD 2.1/4): dono persistente do sistema orfao --
 # nomear criaturas derrotadas vira apostolo no save.
 naming_system = NamingSystem.new()
 naming_system.name = "NamingSystem"
 add_child(naming_system)

 # CampaignSystem (ROADMAP #2): atos e estagios -> desbloqueio de mapa + save.
 campaign_system = CampaignSystem.new()

# A intro canonica e a main scene (intro_story.tscn), que se auto-conecta no _ready.
# Antes havia um IntroStory DUPLICADO instanciado aqui (script.new()): a intro que o
# jogador via emitia intro_completed para zero listeners -> tela preta, game nunca
# iniciava. Quem quer que carregue a intro (main scene) passa a propria instancia.
func connect_intro_story(story) -> void:
 if story and story.has_signal("intro_completed"):
  story.intro_completed.connect(_on_intro_completed)

func _on_intro_completed(choices: Dictionary) -> void:
 # Aplicar escolhas do jogador. So os dicts de escolha tem "consequence"; o emit
 # tambem carrega chaves auxiliares (starting_ally/knowledge_bonus/skipped) --
 # filtrar evita crash (`"kroug".consequence` era erro de runtime).
 for key in choices:
  var choice = choices[key]
  if not (choice is Dictionary): continue
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

 # Aplicar bonus de conhecimento se escolhido
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
 party_data = [{
  "name": "Kael",
  "class": "Imp Menor",
  "hp": 80,
  "atk": 12,
  "def": 8,
  "mov": 3,
  "rng": 1
 }]
 if game_data.starting_ally == "kroug":
  # Pacto de Alma vivo (GDD 2.1): nomear Kroug forja o 1o pacto + vira apostolo
  var res = naming_system.name_soul("goblin_lama", "Kroug")
  if res.success:
   faith_system.register_apostle("Kroug")
   # +25 de fe inicial por ser o primeiro pacto
   faith_system.add_faith("Kroug", 25)
   add_to_party({"name": "Kroug", "class": "Goblin da Lama", "hp": 120, "atk": 10, "def": 15, "mov": 2, "rng": 1})
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

func apply_victory_rewards(rewards) -> void:
 add_soul_ether(rewards.soul_ether)
 add_gold(rewards.gold)
 if progression_system:
  progression_system.add_experience(rewards.xp)
 for soul in rewards.captured_souls:
  if naming_system:
   naming_system.name_soul(soul["type"], soul["display_name"])
 game_data["victory_rewards"] = rewards.serialize() if rewards.has_method("serialize") else {
  "soul_ether": rewards.soul_ether,
  "gold": rewards.gold,
  "xp": rewards.xp,
  "captured_souls": rewards.captured_souls,
  "unlocks": rewards.unlocks
 }

func get_game_data() -> Dictionary:
 return game_data

## Adiciona um membro à party (sem duplicar por nome). Usado ao recrutar apóstolos
## via Pacto de Alma / construções.
func add_to_party(member: Dictionary) -> void:
 for existing in party_data:
  if existing.name == member.get("name", ""):
   return
 party_data.append(member)

func save_game() -> void:
 if progression_system:
  game_data["progression"] = progression_system.serialize()
 var save_data = {
  "game_data": game_data,
  "faith_data": faith_system.faith_data,
  "buildings": building_system.buildings,
  "resources": building_system.resources,
  "unlocked_features": building_system.unlocked_features,
  "character_progression": character_progression.serialize(),
  "lineage_system": lineage_system.serialize(),
  "naming_system": naming_system.save_data(),
  "campaign_system": campaign_system.serialize() if campaign_system else {},
  "party_data": party_data
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
   if save_data.has("unlocked_features"):
    building_system.unlocked_features = save_data.unlocked_features
   if progression_system and save_data.game_data.has("progression"):
    progression_system.deserialize(save_data.game_data.progression)
   if character_progression and save_data.has("character_progression"):
    character_progression.deserialize(save_data.character_progression)
   if lineage_system and save_data.has("lineage_system"):
    lineage_system.deserialize(save_data.lineage_system)
   if naming_system and save_data.has("naming_system"):
    naming_system.load_data(save_data.naming_system)
   if campaign_system and save_data.has("campaign_system"):
    campaign_system.deserialize(save_data.campaign_system)
   if save_data.has("party_data"):
    party_data = save_data.party_data
   return true
  return false
 return false
