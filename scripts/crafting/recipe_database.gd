class_name RecipeDatabase
extends RefCounted

static var recipes: Dictionary = {
 # === ARMAS BÁSICAS ===
 "espada_simples": {
  "id": "espada_simples",
  "name": "Espada Simples",
  "category": "weapon",
  "materials": [
   {"id": "fragmento_pedra", "count": 3},
   {"id": "fibra_resistente", "count": 2}
  ],
  "gold_cost": 30,
  "result": {
   "item_id": "item_espada_simples",
   "quantity": 1
  },
  "unlock": "default",
  "description": "Espada básica de pedra"
 },
 "machado_goblin": {
  "id": "machado_goblin",
  "name": "Machado Goblin",
  "category": "weapon",
  "materials": [
   {"id": "fragmento_pedra", "count": 2},
   {"id": "osso_velho", "count": 3}
  ],
  "gold_cost": 40,
  "result": {
   "item_id": "item_machado_goblin",
   "quantity": 1
  },
  "unlock": "default",
  "description": "Machado tosco feito por goblins"
 },
 "adaga_sombria": {
  "id": "adaga_sombria",
  "name": "Adaga Sombria",
  "category": "weapon",
  "materials": [
   {"id": "presa_sombria", "count": 2},
   {"id": "couro_reforcado", "count": 1}
  ],
  "gold_cost": 80,
  "result": {
   "item_id": "item_adaga_sombria",
   "quantity": 1
  },
  "unlock": "faith_30",
  "description": "Adaga com toque de escuridão"
 },
 "cajado_elemental": {
  "id": "cajado_elemental",
  "name": "Cajado Elemental",
  "category": "weapon",
  "materials": [
   {"id": "cristal_mana", "count": 2},
   {"id": "essencia_elemental", "count": 1}
  ],
  "gold_cost": 120,
  "result": {
   "item_id": "item_cajado_elemental",
   "quantity": 1
  },
  "unlock": "faith_60",
  "description": "Cajado que amplifica magia"
 },
 "lamina_carmesim": {
  "id": "lamina_carmesim",
  "name": "Lâmina Carmesim",
  "category": "weapon",
  "materials": [
   {"id": "lamina_corrompida", "count": 1},
   {"id": "essencia_elemental", "count": 2},
   {"id": "coracao_vulcanico", "count": 1}
  ],
  "gold_cost": 300,
  "result": {
   "item_id": "item_lamina_carmesim",
   "quantity": 1
  },
  "unlock": "boss_paladino",
  "description": "Espada lendária forjada em fogo"
 },

 # === ARMADURAS BÁSICAS ===
 "couro_simples": {
  "id": "couro_simples",
  "name": "Armadura de Couro",
  "category": "armor",
  "materials": [
   {"id": "pele_grudenta", "count": 3},
   {"id": "fibra_resistente", "count": 2}
  ],
  "gold_cost": 25,
  "result": {
   "item_id": "item_couro_simples",
   "quantity": 1
  },
  "unlock": "default",
  "description": "Armadura leve de couro"
 },
 "cota_mailha": {
  "id": "cota_mailha",
  "name": "Cota de Malha",
  "category": "armor",
  "materials": [
   {"id": "couro_reforcado", "count": 2},
   {"id": "fragmento_pedra", "count": 2}
  ],
  "gold_cost": 70,
  "result": {
   "item_id": "item_cota_mailha",
   "quantity": 1
  },
  "unlock": "faith_30",
  "description": "Armadura de malha resistente"
 },
 "peito_das_sombras": {
  "id": "peito_das_sombras",
  "name": "Peitoral das Sombras",
  "category": "armor",
  "materials": [
   {"id": "presa_sombria", "count": 3},
   {"id": "cristal_mana", "count": 1}
  ],
  "gold_cost": 150,
  "result": {
   "item_id": "item_peito_sombras",
   "quantity": 1
  },
  "unlock": "faith_60",
  "description": "Armadura que absorve escuridão"
 },

 # === ACESSÓRIOS ===
 "anel_fer": {
  "id": "anel_fer",
  "name": "Anel de Ferro",
  "category": "accessory",
  "materials": [
   {"id": "fragmento_pedra", "count": 2}
  ],
  "gold_cost": 20,
  "result": {
   "item_id": "item_anel_ferro",
   "quantity": 1
  },
  "unlock": "default",
  "description": "Anel simples que fortalece"
 },
 "amuleto_vida": {
  "id": "amuleto_vida",
  "name": "Amuleto da Vida",
  "category": "accessory",
  "materials": [
   {"id": "amuleto_fendido", "count": 1},
   {"id": "cristal_mana", "count": 1}
  ],
  "gold_cost": 100,
  "result": {
   "item_id": "item_amuleto_vida",
   "quantity": 1
  },
  "unlock": "faith_30",
  "description": "Amuleto que restaura HP"
 },

 # === CONSUMÍVEIS ===
 "pocao_cura": {
  "id": "pocao_cura",
  "name": "Poção de Cura",
  "category": "consumable",
  "materials": [
   {"id": "fibra_resistente", "count": 1},
   {"id": "osso_velho", "count": 1}
  ],
  "gold_cost": 10,
  "result": {
   "item_id": "item_pocao_cura",
   "quantity": 2
  },
  "unlock": "default",
  "description": "Restaura 30% HP"
 },
 "pocao_mana": {
  "id": "pocao_mana",
  "name": "Poção de Maná",
  "category": "consumable",
  "materials": [
   {"id": "cristal_mana", "count": 1},
   {"id": "fibra_resistente", "count": 1}
  ],
  "gold_cost": 15,
  "result": {
   "item_id": "item_pocao_mana",
   "quantity": 2
  },
  "unlock": "default",
  "description": "Restaura 30% MP"
 },
 "elxir_forca": {
  "id": "elxir_forca",
  "name": "Elixir da Força",
  "category": "consumable",
  "materials": [
   {"id": "garras_afiadas", "count": 2},
   {"id": "essencia_elemental", "count": 1}
  ],
  "gold_cost": 50,
  "result": {
   "item_id": "item_elxir_forca",
   "quantity": 1
  },
  "unlock": "faith_30",
  "description": "+10 ATK por 3 turnos"
 }
}

static func get_recipe(recipe_id: String) -> Dictionary:
 if recipes.has(recipe_id):
  return recipes[recipe_id]
 return {}

static func get_recipes_by_category(category: String) -> Array:
 var result = []
 for recipe_id in recipes:
  if recipes[recipe_id].category == category:
   result.append(recipes[recipe_id])
 return result

static func get_recipes_by_unlock(unlock_condition: String) -> Array:
 var result = []
 for recipe_id in recipes:
  if recipes[recipe_id].unlock == unlock_condition or recipes[recipe_id].unlock == "default":
   result.append(recipes[recipe_id])
 return result

static func can_craft(recipe_id: String, inventory: Dictionary, gold: int) -> bool:
 var recipe = get_recipe(recipe_id)
 if recipe.is_empty():
  return false

 if gold < recipe.gold_cost:
  return false

 for mat in recipe.materials:
  if not inventory.has(mat.id) or inventory[mat.id] < mat.count:
   return false

 return true

static func get_crafting_cost(recipe_id: String) -> Dictionary:
 var recipe = get_recipe(recipe_id)
 return {
  "materials": recipe.materials,
  "gold": recipe.gold_cost
 }

static func get_all_recipes() -> Array:
 return recipes.values()
