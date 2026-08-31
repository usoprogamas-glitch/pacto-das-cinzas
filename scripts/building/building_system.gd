class_name BuildingSystem
extends Node

signal building_built(building_name: String)
signal building_upgraded(building_name: String, new_level: int)
signal resource_changed(resource: String, amount: int)
signal feature_unlocked(feature: String)

var buildings: Dictionary = {}
var resources: Dictionary = {
 "soul_ether": 0,
 "gold": 0,
 "materials": 0
}

# Desbloqueios acumulados das construções. Persistido no save para consumidores
# (UI de crafting, recrutamento, fé) consultarem.
var unlocked_features: Dictionary = {}

func _ready() -> void:
 initialize_buildings()

func initialize_buildings() -> void:
 buildings = {
  "acampamento_base": {
   "name": "Acampamento Base",
   "description": "Centro da operação",
   "level": 1,
   "max_level": 3,
   "cost": {"soul_ether": 0},
   "effects": {"storage": 100},
   "unlocks": []
  },
  "toca_goblin": {
   "name": "Toca do Goblin",
   "description": "Permite recrutar Goblins",
   "level": 0,
   "max_level": 3,
   "cost": {"soul_ether": 50},
   "effects": {"recruit": "Goblin"},
   "unlocks": ["Goblin"]
  },
  "fornalha_vulcanica": {
   "name": "Fornalha Vulcânica",
   "description": "Melhora equipamentos",
   "level": 0,
   "max_level": 3,
   "cost": {"soul_ether": 120},
   "effects": {"craft": true},
   "unlocks": ["Armas Básicas"]
  },
  "templo_cinzas": {
   "name": "Templo das Cinzas",
   "description": "Aumenta Fé máxima",
   "level": 0,
   "max_level": 3,
   "cost": {"soul_ether": 200},
   "effects": {"faith_cap": 50},
   "unlocks": ["Habilidades de Fé"]
  },
  "muralha_pedra": {
   "name": "Muralha de Pedra",
   "description": "Defesa da vila",
   "level": 0,
   "max_level": 3,
   "cost": {"soul_ether": 150},
   "effects": {"defense": 20},
   "unlocks": []
  },
  "torre_vigia": {
   "name": "Torre de Vigia",
   "description": "Avisa de ataques",
   "level": 0,
   "max_level": 2,
   "cost": {"soul_ether": 100},
   "effects": {"alert": true},
   "unlocks": []
  },
  "jardim_lira": {
   "name": "Jardim de Lira",
   "description": "Regeneração de HP",
   "level": 0,
   "max_level": 3,
   "cost": {"soul_ether": 180},
   "effects": {"heal_rate": 10},
   "unlocks": ["Poções"]
  },
  "guilda_thalkor": {
   "name": "Guilda de Thal'kor",
   "description": "Desbloqueia missões de espionagem",
   "level": 0,
   "max_level": 2,
   "cost": {"soul_ether": 250},
   "effects": {"spy_missions": true},
   "unlocks": ["Missões de Espionagem"]
  },
  "forja_rei_ogro": {
   "name": "Forja do Rei Ogro",
   "description": "Melhora armas do exército",
   "level": 0,
   "max_level": 3,
   "cost": {"soul_ether": 300},
   "effects": {"army_power": 15},
   "unlocks": ["Armas Avançadas"]
  },
  "portao_abismo": {
   "name": "Portão do Abismo",
   "description": "Desbloqueia novas regiões",
   "level": 0,
   "max_level": 1,
   "cost": {"soul_ether": 500},
   "effects": {"new_regions": true},
   "unlocks": ["Floresta Sombria", "Montanhas"]
  }
 }

func can_build(building_id: String) -> bool:
 if not buildings.has(building_id):
  return false

 var building = buildings[building_id]
 if building.level >= building.max_level:
  return false

 var cost = get_upgrade_cost(building_id)
 return has_resources(cost)

func get_upgrade_cost(building_id: String) -> Dictionary:
 if not buildings.has(building_id):
  return {}

 var building = buildings[building_id]
 var base_cost = building.cost
 var level = building.level
 var multiplier = 1.5

 var cost = {}
 for resource in base_cost:
  cost[resource] = int(base_cost[resource] * (1 + level * multiplier))

 return cost

func build(building_id: String) -> bool:
 if not can_build(building_id):
  return false

 var cost = get_upgrade_cost(building_id)
 spend_resources(cost)

 buildings[building_id].level += 1
 apply_building_effects(building_id)
 building_built.emit(building_id)

 if buildings[building_id].level > 1:
  building_upgraded.emit(building_id, buildings[building_id].level)

 return true

## Interpreta os efeitos data-driven da construção e materializa os desbloqueios
## em `unlocked_features` para as UIs/consumidores consultarem. Guardado como dados
## para persistência e para não acoplar a sistemas que podem nem existir ainda.
func apply_building_effects(building_id: String) -> void:
 if not buildings.has(building_id):
  return
 var building = buildings[building_id]
 for effect_key in building.effects:
  var effect_value = building.effects[effect_key]
  match effect_key:
   "craft":
    for u in building.unlocks:
     unlocked_features["craft_" + u.to_snake_case()] = true
     feature_unlocked.emit("craft_" + u.to_snake_case())
   "recruit":
    for u in building.unlocks:
     unlocked_features["recruit_" + u.to_snake_case()] = true
     feature_unlocked.emit("recruit_" + u.to_snake_case())
   "faith_cap":
    unlocked_features["faith_cap"] = int(effect_value)
    feature_unlocked.emit("faith_cap")
   "defense":
    unlocked_features["defense"] = int(effect_value)
    feature_unlocked.emit("defense")
   "heal_rate":
    unlocked_features["heal_rate"] = int(effect_value)
    feature_unlocked.emit("heal_rate")
   "army_power":
    unlocked_features["army_power"] = int(effect_value)
    feature_unlocked.emit("army_power")
   "new_regions":
    unlocked_features["new_regions"] = true
    feature_unlocked.emit("new_regions")
   "alert":
    unlocked_features["alert"] = true
    feature_unlocked.emit("alert")
   "spy_missions":
    unlocked_features["spy_missions"] = true
    feature_unlocked.emit("spy_missions")

func is_feature_unlocked(feature: String) -> bool:
 return unlocked_features.get(feature, false)

func is_craft_unlocked(recipe_id: String) -> bool:
 return unlocked_features.get("craft_" + recipe_id.to_snake_case(), false)

func get_unlocked_recruit_types() -> Array:
 var result = []
 for key in unlocked_features:
  if key.begins_with("recruit_"):
   result.append(key.trim_prefix("recruit_"))
 return result

func has_resources(cost: Dictionary) -> bool:
 for resource in cost:
  if not resources.has(resource) or resources[resource] < cost[resource]:
   return false
 return true

func spend_resources(cost: Dictionary) -> void:
 for resource in cost:
  resources[resource] -= cost[resource]
  resource_changed.emit(resource, resources[resource])

func add_resource(resource: String, amount: int) -> void:
 if resources.has(resource):
  resources[resource] += amount
  resource_changed.emit(resource, resources[resource])

func get_building_info(building_id: String) -> Dictionary:
 if buildings.has(building_id):
  var building = buildings[building_id]
  return {
   "id": building_id,
   "name": building.name,
   "description": building.description,
   "level": building.level,
   "max_level": building.max_level,
   "cost": get_upgrade_cost(building_id),
   "can_build": can_build(building_id),
   "effects": building.effects,
   "unlocks": building.unlocks
  }
 return {}

func get_all_buildings() -> Array:
 var result = []
 for building_id in buildings:
  result.append(get_building_info(building_id))
 return result

func get_built_buildings() -> Array:
 var result = []
 for building_id in buildings:
  if buildings[building_id].level > 0:
   result.append(get_building_info(building_id))
 return result

func get_resource_amount(resource: String) -> int:
 return resources.get(resource, 0)
