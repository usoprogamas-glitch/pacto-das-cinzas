class_name FaithSystem
extends Node

signal faith_changed(unit_name: String, new_faith: int)
signal faith_level_up(unit_name: String, level: String)

var faith_data: Dictionary = {}

func _ready() -> void:
 pass

func register_apostle(unit_name: String) -> void:
 faith_data[unit_name] = {
  "faith": 0,
  "level": "Neutro",
  "bonuses": {}
 }

func add_faith(unit_name: String, amount: int) -> void:
 if not faith_data.has(unit_name):
  register_apostle(unit_name)

 faith_data[unit_name].faith = mini(100, faith_data[unit_name].faith + amount)
 var new_faith = faith_data[unit_name].faith
 var old_level = faith_data[unit_name].level
 var new_level = get_faith_level(new_faith)

 faith_changed.emit(unit_name, new_faith)

 if new_level != old_level:
  faith_data[unit_name].level = new_level
  apply_faith_bonuses(unit_name, new_level)
  faith_level_up.emit(unit_name, new_level)

func get_faith(unit_name: String) -> int:
 if faith_data.has(unit_name):
  return faith_data[unit_name].faith
 return 0

func get_faith_level(faith: int) -> String:
 if faith >= 90:
  return "Apóstolo"
 elif faith >= 60:
  return "Devoto"
 elif faith >= 30:
  return "Leal"
 else:
  return "Neutro"

func get_faith_bonuses(unit_name: String) -> Dictionary:
 if not faith_data.has(unit_name):
  return {}

 var faith = faith_data[unit_name].faith
 var bonuses = {}

 if faith >= 30:
  bonuses["hp_percent"] = 10
  bonuses["atk_percent"] = 10
  bonuses["def_percent"] = 10

 if faith >= 60:
  bonuses["hp_percent"] = 20
  bonuses["atk_percent"] = 20
  bonuses["def_percent"] = 20
  bonuses["special_unlocked"] = true

 if faith >= 90:
  bonuses["hp_percent"] = 30
  bonuses["atk_percent"] = 30
  bonuses["def_percent"] = 30
  bonuses["special_unlocked"] = true
  bonuses["evolution_ready"] = true

 return bonuses

func apply_faith_bonuses(unit_name: String, level: String) -> void:
 var bonuses = get_faith_bonuses(unit_name)
 faith_data[unit_name].bonuses = bonuses

func get_all_apostles() -> Array:
 return faith_data.keys()

func get_apostle_info(unit_name: String) -> Dictionary:
 if faith_data.has(unit_name):
  var data = faith_data[unit_name]
  return {
   "name": unit_name,
   "faith": data.faith,
   "level": data.level,
   "bonuses": data.bonuses,
   "next_level": get_next_level_info(data.faith)
  }
 return {}

func get_next_level_info(faith: int) -> Dictionary:
 if faith < 30:
  return {"level": "Leal", "faith_needed": 30 - faith}
 elif faith < 60:
  return {"level": "Devoto", "faith_needed": 60 - faith}
 elif faith < 90:
  return {"level": "Apóstolo", "faith_needed": 90 - faith}
 else:
  return {"level": "Máximo", "faith_needed": 0}
