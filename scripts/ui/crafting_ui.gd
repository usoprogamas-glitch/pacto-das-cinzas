class_name CraftingUI
extends Control

signal item_crafted(item_id: String)
signal back_pressed()

@onready var recipe_list: ItemList = $VBoxContainer/RecipeList
@onready var recipe_info: RichTextLabel = $VBoxContainer/RecipeInfo
@onready var craft_button: Button = $VBoxContainer/CraftButton
@onready var material_list: ItemList = $VBoxContainer/MaterialList
@onready var back_button: Button = $BackButton
@onready var gold_label: Label = $TopBar/GoldLabel

var crafting_manager: CraftingManager
var selected_recipe: String = ""

func _ready() -> void:
 crafting_manager = CraftingManager.new()
 populate_recipes()
 populate_materials()
 craft_button.pressed.connect(_on_craft)
 back_button.pressed.connect(_on_back)
 recipe_list.item_selected.connect(_on_recipe_selected)

func populate_recipes() -> void:
 recipe_list.clear()
 var recipes = crafting_manager.get_unlocked_recipes()
 for recipe in recipes:
  var can = crafting_manager.can_craft(recipe.id, GameManager.game_data.get("gold", 0))
  var icon = "✅" if can else "❌"
  recipe_list.add_item("%s %s" % [icon, recipe.name])

func populate_materials() -> void:
 material_list.clear()
 var inventory = crafting_manager.get_inventory()
 for material_id in inventory:
  var mat = MaterialDatabase.get_material(material_id)
  if not mat.is_empty():
   material_list.add_item("%s x%d" % [mat.name, inventory[material_id]])

func _on_recipe_selected(index: int) -> void:
 var recipes = crafting_manager.get_unlocked_recipes()
 if index < recipes.size():
  selected_recipe = recipes[index].id
  var recipe = recipes[index]

  var info = "[center]%s[/center]\n\n" % recipe.name
  info += "%s\n\n" % recipe.description
  info += "[b]Categoria:[/b] %s\n" % recipe.category
  info += "[b]Custo:[/b] %d ouro\n\n" % recipe.gold_cost
  info += "[b]Materiais necessários:[/b]\n"

  for mat in recipe.materials:
   var mat_data = MaterialDatabase.get_material(mat.id)
   var has = crafting_manager.get_material_count(mat.id)
   var color = "#00FF00" if has >= mat.count else "#FF0000"
   info += "  • %s: [color=%s]%d/%d[/color]\n" % [mat_data.name, color, has, mat.count]

  recipe_info.text = info
  craft_button.disabled = not crafting_manager.can_craft(recipe.id, GameManager.game_data.get("gold", 0))

func _on_craft() -> void:
 if selected_recipe:
  var result = crafting_manager.craft_item(selected_recipe, GameManager.game_data.get("gold", 0))
  if result.success:
   populate_recipes()
   populate_materials()
   item_crafted.emit(result.item_id)

func _on_back() -> void:
 back_pressed.emit()
