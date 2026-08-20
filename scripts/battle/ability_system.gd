class_name AbilitySystem
extends Node

signal ability_used(unit_name: String, ability_name: String)
signal ability_unlocked(unit_name: String, ability_name: String)

var abilities: Dictionary = {}

func _ready() -> void:
 initialize_abilities()

func initialize_abilities() -> void:
 abilities = {
  "kroug": {
   "passive": {
    "name": "Pele de Ferro",
    "description": "+15% DEF enquanto estiver no turno",
    "effect": "defense_bonus",
    "value": 15
   },
   "faith_60": {
    "name": "Grito de Guerra",
    "description": "Aumenta ATK de todos os aliados em 20% por 2 turnos",
    "effect": "buff_allies_atk",
    "value": 20,
    "duration": 2,
    "cooldown": 3,
    "mp_cost": 15
   },
   "faith_100": {
    "name": "Fúria Vulcânica",
    "description": "Ataque AoE que causa dano e stuna por 1 turno",
    "effect": "aoe_damage_stun",
    "value": 40,
    "range": 2,
    "cooldown": 4,
    "mp_cost": 25
   },
   "evolution": {
    "name": "Juramento de Cinzas",
    "description": "Revive uma vez por batalha com 50% HP",
    "effect": "revive_once",
    "value": 50
   }
  },
  "lira": {
   "passive": {
    "name": "Toque da Natureza",
    "description": "Regenera 5% HP no início do turno",
    "effect": "heal_per_turn",
    "value": 5
   },
   "faith_60": {
    "name": "Névoa Protetora",
    "description": "Esconde um aliado por 1 turno (invulnerável)",
    "effect": "hide_ally",
    "duration": 1,
    "cooldown": 3,
    "mp_cost": 12
   },
   "faith_100": {
    "name": "Jardim Eterno",
    "description": "Cura todos os aliados em 30% e remove debuffs",
    "effect": "heal_all_cleanse",
    "value": 30,
    "cooldown": 5,
    "mp_cost": 30
   },
   "evolution": {
    "name": "Canto Primaveril",
    "description": "Resurrecta todos os aliados caídos uma vez por batalha",
    "effect": "resurrect_all",
    "value": 30
   }
  },
  "thalkor": {
   "passive": {
    "name": "Sentidos Aguçados",
    "description": "+20% chance de crítico",
    "effect": "crit_chance",
    "value": 20
   },
   "faith_60": {
    "name": "Dançar das Lâminas",
    "description": "Ataque em cone que ignora 50% da defesa",
    "effect": "cone_ignore_def",
    "value": 50,
    "range": 2,
    "cooldown": 2,
    "mp_cost": 10
   },
   "faith_100": {
    "name": "Eclipse Mortal",
    "description": "Silencia o alvo por 2 turnos e causa dano massivo",
    "effect": "silence_heavy_damage",
    "value": 80,
    "duration": 2,
    "cooldown": 4,
    "mp_cost": 25
   },
   "evolution": {
    "name": "Voo do Corvo",
    "description": "Ataque aéreo que ignora terreno e obstáculos",
    "effect": "aerial_attack",
    "value": 60
   }
  }
 }

func has_ability(unit_name: String, ability_type: String) -> bool:
 var unit_key = unit_name.to_lower().replace(" ", "_")
 if abilities.has(unit_key):
  return abilities[unit_key].has(ability_type)
 return false

func get_ability(unit_name: String, ability_type: String) -> Dictionary:
 var unit_key = unit_name.to_lower().replace(" ", "_")
 if abilities.has(unit_key) and abilities[unit_key].has(ability_type):
  return abilities[unit_key][ability_type]
 return {}

func use_ability(unit_name: String, ability_type: String, target: Unit = null) -> Dictionary:
 var ability = get_ability(unit_name, ability_type)
 if ability.is_empty():
  return {"success": false, "reason": "ability_not_found"}

 ability_used.emit(unit_name, ability.name)

 match ability.effect:
  "defense_bonus":
   return {"success": true, "effect": "buff", "stat": "defense", "value": ability.value}
  "buff_allies_atk":
   return {"success": true, "effect": "buff_all", "stat": "attack", "value": ability.value, "duration": ability.duration}
  "aoe_damage_stun":
   return {"success": true, "effect": "aoe_damage", "value": ability.value, "range": ability.range, "stun": true}
  "revive_once":
   return {"success": true, "effect": "revive", "value": ability.value}
  "heal_per_turn":
   return {"success": true, "effect": "regen", "value": ability.value}
  "hide_ally":
   return {"success": true, "effect": "hide", "target": target, "duration": ability.duration}
  "heal_all_cleanse":
   return {"success": true, "effect": "heal_all", "value": ability.value, "cleanse": true}
  "resurrect_all":
   return {"success": true, "effect": "resurrect", "value": ability.value}
  "crit_chance":
   return {"success": true, "effect": "crit_boost", "value": ability.value}
  "cone_ignore_def":
   return {"success": true, "effect": "cone_attack", "value": ability.value, "ignore_def": true}
  "silence_heavy_damage":
   return {"success": true, "effect": "silence_damage", "value": ability.value, "duration": ability.duration}
  "aerial_attack":
   return {"success": true, "effect": "aerial", "value": ability.value}

 return {"success": false, "reason": "unknown_effect"}

func get_unit_abilities(unit_name: String) -> Array:
 var unit_key = unit_name.to_lower().replace(" ", "_")
 if abilities.has(unit_key):
  return abilities[unit_key].keys()
 return []

func get_ability_description(unit_name: String, ability_type: String) -> String:
 var ability = get_ability(unit_name, ability_type)
 if not ability.is_empty():
  return ability.get("description", "")
 return ""
