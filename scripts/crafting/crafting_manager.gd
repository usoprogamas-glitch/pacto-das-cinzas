class_name CraftingManager
extends Node

signal item_crafted(item_id: String, quantity: int)
signal material_consumed(material_id: String, count: int)
signal recipe_unlocked(recipe_id: String)
signal crafting_failed(reason: String)

var inventory: Dictionary = {}
var equipment: Dictionary = {}
var unlocked_recipes: Array[String] = []

func _ready() -> void:
 unlock_default_recipes()

func unlock_default_recipes() -> void:
 var recipes = RecipeDatabase.get_all_recipes()
 for recipe in recipes:
  if recipe.unlock == "default":
   unlocked_recipes.append(recipe.id)

func unlock_recipe(recipe_id: String) -> void:
 if recipe_id not in unlocked_recipes:
  unlocked_recipes.append(recipe_id)
  recipe_unlocked.emit(recipe_id)

func has_material(material_id: String, count: int = 1) -> bool:
 return inventory.get(material_id, 0) >= count

func add_material(material_id: String, count: int = 1) -> void:
 if inventory.has(material_id):
  inventory[material_id] += count
 else:
  inventory[material_id] = count

func remove_material(material_id: String, count: int = 1) -> bool:
 if not has_material(material_id, count):
  return false

 inventory[material_id] -= count
 if inventory[material_id] <= 0:
  inventory.erase(material_id)

 material_consumed.emit(material_id, count)
 return true

func get_material_count(material_id: String) -> int:
 return inventory.get(material_id, 0)

func can_craft(recipe_id: String, gold: int) -> bool:
 if recipe_id not in unlocked_recipes:
  return false

 return RecipeDatabase.can_craft(recipe_id, inventory, gold)

func craft_item(recipe_id: String, gold: int) -> Dictionary:
 if not can_craft(recipe_id, gold):
  crafting_failed.emit("Não é possível criar este item")
  return {"success": false, "reason": "cannot_craft"}

 var recipe = RecipeDatabase.get_recipe(recipe_id)

 # Consumir materiais
 for mat in recipe.materials:
  if not remove_material(mat.id, mat.count):
   crafting_failed.emit("Materiais insuficientes")
   return {"success": false, "reason": "insufficient_materials"}

 # Adicionar item ao inventário
 var item_id = recipe.result.item_id
 var quantity = recipe.result.quantity

 if equipment.has(item_id):
  equipment[item_id] += quantity
 else:
  equipment[item_id] = quantity

 item_crafted.emit(item_id, quantity)
 return {"success": true, "item_id": item_id, "quantity": quantity}

func get_unlocked_recipes() -> Array:
 var result = []
 for recipe_id in unlocked_recipes:
  var recipe = RecipeDatabase.get_recipe(recipe_id)
  if not recipe.is_empty():
   result.append(recipe)
 return result

func get_craftable_recipes(gold: int) -> Array:
 var result = []
 for recipe_id in unlocked_recipes:
  if can_craft(recipe_id, gold):
   var recipe = RecipeDatabase.get_recipe(recipe_id)
   result.append(recipe)
 return result

func get_inventory() -> Dictionary:
 return inventory.duplicate()

func get_equipment_inventory() -> Dictionary:
 return equipment.duplicate()

func has_item(item_id: String) -> bool:
 return equipment.get(item_id, 0) > 0

func get_item_count(item_id: String) -> int:
 return equipment.get(item_id, 0)

func use_item(item_id: String, target: Unit) -> Dictionary:
 if not has_item(item_id):
  return {"success": false, "reason": "not_owned"}

 var item = EquipmentDatabase.get_equipment(item_id)
 if item.is_empty():
  return {"success": false, "reason": "invalid_item"}

 if item.type == "consumable":
  var result = EquipmentDatabase.use_consumable(target, item_id)
  if result.success:
   equipment[item_id] -= 1
   if equipment[item_id] <= 0:
    equipment.erase(item_id)
  return result

 return {"success": false, "reason": "not_consumable"}

func equip_item(unit: Unit, item_id: String) -> Dictionary:
 if not has_item(item_id):
  return {"success": false, "reason": "not_owned"}

 var item = EquipmentDatabase.get_equipment(item_id)
 if item.is_empty():
  return {"success": false, "reason": "invalid_item"}

 if item.type == "consumable":
  return {"success": false, "reason": "consumable"}

 EquipmentDatabase.apply_equipment(unit, item_id)
 return {"success": true}

func unequip_item(unit: Unit, item_id: String) -> Dictionary:
 var item = EquipmentDatabase.get_equipment(item_id)
 if item.is_empty():
  return {"success": false, "reason": "invalid_item"}

 EquipmentDatabase.remove_equipment(unit, item_id)
 return {"success": true}

func on_enemy_defeated(enemy_type: String) -> Array:
 var drops = MaterialDatabase.roll_drop(enemy_type)
 var obtained = []

 for material_id in drops:
  add_material(material_id, 1)
  obtained.append(material_id)

 return obtained

func save_data() -> Dictionary:
 return {
  "inventory": inventory,
  "equipment": equipment,
  "unlocked_recipes": unlocked_recipes
 }

func load_data(data: Dictionary) -> void:
 inventory = data.get("inventory", {})
 equipment = data.get("equipment", {})
 unlocked_recipes = data.get("unlocked_recipes", [])
