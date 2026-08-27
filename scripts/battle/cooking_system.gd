class_name CookingSystem
extends RefCounted

## Sistema de Culinária e Elixires de Éter (GDD v2 §7.2)
##
## Coleta de ingredientes pelo mundo para preparo de pratos
## e elixires que concedem bônus táticos.

signal recipe_crafted(recipe_name: String, bonuses: Dictionary)
signal ingredient_collected(ingredient_name: String, amount: int)

## --- Ingredientes disponíveis ---
const INGREDIENTS: Dictionary = {
 "ervas_silvestres": {"name": "Ervas Silvestres", "type": "herb", "rarity": "common"},
 "cogumelo_luminoso": {"name": "Cogumelo Luminoso", "type": "fungus", "rarity": "common"},
 "raiz_profunda": {"name": "Raiz Profunda", "type": "root", "rarity": "uncommon"},
 "pedra_eterea": {"name": "Pedra Etérea", "type": "mineral", "rarity": "uncommon"},
 "lagrima_fada": {"name": "Lágrima de Fada", "type": "essence", "rarity": "rare"},
 "cinzas_ancestrais": {"name": "Cinzas Ancestrais", "type": "ash", "rarity": "rare"},
 "mel_abissal": {"name": "Mel Abissal", "type": "sweet", "rarity": "uncommon"},
 "carne_troll": {"name": "Carne de Troll", "type": "meat", "rarity": "common"},
 "peixe_luminoso": {"name": "Peixe Luminoso", "type": "fish", "rarity": "common"},
 "fruta_eterna": {"name": "Fruta Eterna", "type": "fruit", "rarity": "rare"},
}

## --- Receitas de pratos (buffs temporários) ---
const RECIPES: Dictionary = {
 "guisado_goblin": {
  "name": "Guisado de Goblin",
  "description": "Prato rústico que fortalece o corpo",
  "ingredients": {"carne_troll": 2, "ervas_silvestres": 1},
  "bonuses": {"hp": 20, "defense": 5},
  "duration": 3,  ## turnos
  "category": "food",
 },
 "sopa_luminosa": {
  "name": "Sopa Luminosa",
  "description": "Sopa que ilumina a mente",
  "ingredients": {"cogumelo_luminoso": 2, "peixe_luminoso": 1},
  "bonuses": {"mp": 30, "magic": 5},
  "duration": 3,
  "category": "food",
 },
 "banquete_rei": {
  "name": "Banquete do Rei",
  "description": "Festim digno de reis",
  "ingredients": {"carne_troll": 3, "fruta_eterna": 1, "mel_abissal": 1},
  "bonuses": {"hp": 50, "mp": 50, "attack": 10, "defense": 10},
  "duration": 5,
  "category": "food",
 },
}

## --- Receitas de elixires (buffs permanentes ou de longa duração) ---
const ELIXIRS: Dictionary = {
 "elixir_etereo": {
  "name": "Elixir Etéreo",
  "description": "Aumenta carga máxima de Éter",
  "ingredients": {"pedra_eterea": 2, "lagrima_fada": 1},
  "bonuses": {"max_ether": 1},
  "duration": -1,  ## permanente
  "category": "elixir",
 },
 "pocao_furia": {
  "name": "Poção de Fúria",
  "description": "Aumenta ATK em 10% permanentemente",
  "ingredients": {"cinzas_ancestrais": 2, "raiz_profunda": 1},
  "bonuses": {"attack_percent": 10},
  "duration": -1,
  "category": "elixir",
 },
 "essencia_vida": {
  "name": "Essência da Vida",
  "description": "Aumenta HP máximo em 50",
  "ingredients": {"lagrima_fada": 2, "fruta_eterna": 1},
  "bonuses": {"max_hp": 50},
  "duration": -1,
  "category": "elixir",
 },
}

## Peso de raridade para custo (common=1, uncommon=2, rare=3).
const RARITY_COST: Dictionary = {"common": 1, "uncommon": 2, "rare": 3}


## --- Estado do sistema ---
var _inventory: Dictionary = {}  ## {ingredient_id: amount}
var _active_bonuses: Array = []  ## Buffs ativos
var _crafted_count: Dictionary = {}  ## {recipe_id: times_crafted}


## --- Inventário ---

## Coletar ingrediente.
func collect_ingredient(ingredient_id: String, amount: int = 1) -> void:
 if not INGREDIENTS.has(ingredient_id):
  return
 if not _inventory.has(ingredient_id):
  _inventory[ingredient_id] = 0
 _inventory[ingredient_id] += amount
 ingredient_collected.emit(ingredient_id, amount)


## Verificar se tem ingredientes suficientes.
func has_ingredients(ingredients_needed: Dictionary) -> bool:
 for ingredient_id in ingredients_needed:
  var needed = ingredients_needed[ingredient_id]
  var have = _inventory.get(ingredient_id, 0)
  if have < needed:
   return false
 return true


## Consumir ingredientes.
func _consume_ingredients(ingredients_needed: Dictionary) -> void:
 for ingredient_id in ingredients_needed:
  _inventory[ingredient_id] -= ingredients_needed[ingredient_id]


## --- Culinária ---

## Verificar se pode cozinhar uma receita.
func can_craft(recipe_id: String) -> bool:
 var recipe = RECIPES.get(recipe_id, {})
 if recipe.is_empty():
  recipe = ELIXIRS.get(recipe_id, {})
 if recipe.is_empty():
  return false
 return has_ingredients(recipe.ingredients)


## Cozinhar uma receita.
func craft(recipe_id: String) -> Dictionary:
 var recipe = RECIPES.get(recipe_id, {})
 var is_elixir = false
 if recipe.is_empty():
  recipe = ELIXIRS.get(recipe_id, {})
  is_elixir = true
 if recipe.is_empty():
  return {}

 if not has_ingredients(recipe.ingredients):
  return {}

 _consume_ingredients(recipe.ingredients)

 ## Aplicar bônus
 var bonus_entry = {
  "recipe_id": recipe_id,
  "name": recipe.name,
  "bonuses": recipe.bonuses,
  "duration": recipe.duration,
  "remaining_turns": recipe.duration,
 }
 _active_bonuses.append(bonus_entry)

 ## Registrar craft
 if not _crafted_count.has(recipe_id):
  _crafted_count[recipe_id] = 0
 _crafted_count[recipe_id] += 1

 recipe_crafted.emit(recipe.name, recipe.bonuses)
 return recipe.bonuses


## --- Bônus ativos ---

## Decrementar duração dos bônus (chamado a cada turno).
func tick_bonuses() -> Array:
 var expired = []
 var remaining = []

 for bonus in _active_bonuses:
  if bonus.duration == -1:
   remaining.append(bonus)  ## Permanente
  else:
   bonus.remaining_turns -= 1
   if bonus.remaining_turns <= 0:
    expired.append(bonus.name)
   else:
    remaining.append(bonus)

 _active_bonuses = remaining
 return expired


## Obter bônus totais ativos.
func get_total_bonuses() -> Dictionary:
 var totals = {}
 for bonus in _active_bonuses:
  for stat in bonus.bonuses:
   if not totals.has(stat):
    totals[stat] = 0
   totals[stat] += bonus.bonuses[stat]
 return totals


## --- Getters ---

func get_inventory() -> Dictionary:
 return _inventory

func get_ingredient_amount(ingredient_id: String) -> int:
 return _inventory.get(ingredient_id, 0)

func get_active_bonuses() -> Array:
 return _active_bonuses

func get_crafted_count(recipe_id: String) -> int:
 return _crafted_count.get(recipe_id, 0)

func get_all_recipes() -> Dictionary:
 return RECIPES

## Custo ponderado por raridade de uma receita/elixir (common=1, uncommon=2, rare=3).
func recipe_cost(recipe_id: String) -> int:
 var recipe = RECIPES.get(recipe_id, {})
 if recipe.is_empty():
  recipe = ELIXIRS.get(recipe_id, {})
 if recipe.is_empty():
  return 0
 var total: int = 0
 for ing_id: String in recipe.ingredients:
  var rarity: String = INGREDIENTS.get(ing_id, {}).get("rarity", "common")
  total += RARITY_COST.get(rarity, 1) * recipe.ingredients[ing_id]
 return total

func get_all_elixirs() -> Dictionary:
 return ELIXIRS

func get_all_ingredients() -> Dictionary:
 return INGREDIENTS
