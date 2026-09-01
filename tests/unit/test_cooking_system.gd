extends "res://addons/gut/test.gd"

## Testes GUT para CookingSystem (Culinária e Elixires, GDD v2 §7.2)


func test_collect_ingredient():
	var cs = CookingSystem.new()
	cs.collect_ingredient("ervas_silvestres", 3)
	assert_eq(cs.get_ingredient_amount("ervas_silvestres"), 3, "3 ervas coletadas")


func test_collect_unknown_ingredient():
	var cs = CookingSystem.new()
	cs.collect_ingredient("ingrediente_falso", 5)
	assert_eq(cs.get_ingredient_amount("ingrediente_falso"), 0, "Ingrediente inválido = 0")


func test_collect_multiple_types():
	var cs = CookingSystem.new()
	cs.collect_ingredient("ervas_silvestres", 2)
	cs.collect_ingredient("cogumelo_luminoso", 1)
	assert_eq(cs.get_ingredient_amount("ervas_silvestres"), 2, "2 ervas")
	assert_eq(cs.get_ingredient_amount("cogumelo_luminoso"), 1, "1 cogumelo")


func test_has_ingredients_true():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	assert_true(cs.has_ingredients({"carne_troll": 2, "ervas_silvestres": 1}))


func test_has_ingredients_false():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 1)
	assert_false(cs.has_ingredients({"carne_troll": 2, "ervas_silvestres": 1}))


func test_can_craft_recipe():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	assert_true(cs.can_craft("guisado_goblin"))


func test_can_craft_elixir():
	var cs = CookingSystem.new()
	cs.collect_ingredient("pedra_eterea", 2)
	cs.collect_ingredient("lagrima_fada", 1)
	assert_true(cs.can_craft("elixir_etereo"))


func test_cannot_craft_without_ingredients():
	var cs = CookingSystem.new()
	assert_false(cs.can_craft("guisado_goblin"))


func test_craft_consumes_ingredients():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	cs.craft("guisado_goblin")
	assert_eq(cs.get_ingredient_amount("carne_troll"), 0, "Carne consumida")
	assert_eq(cs.get_ingredient_amount("ervas_silvestres"), 0, "Ervas consumidas")


func test_craft_returns_bonuses():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	var result = cs.craft("guisado_goblin")
	assert_eq(result.hp, 20, "+20 HP")
	assert_eq(result.defense, 5, "+5 DEF")


func test_craft_invalid_recipe():
	var cs = CookingSystem.new()
	var result = cs.craft("receita_inexistente")
	assert_eq(result, {}, "Receita inválida retorna vazio")


func test_craft_insufficient_ingredients():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 1)
	var result = cs.craft("guisado_goblin")
	assert_eq(result, {}, "Insuficiente retorna vazio")


func test_active_bonuses_after_craft():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	cs.craft("guisado_goblin")
	var bonuses = cs.get_active_bonuses()
	assert_eq(bonuses.size(), 1, "1 bônus ativo")


func test_tick_bonuses():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	cs.craft("guisado_goblin")
	var expired = cs.tick_bonuses()
	assert_eq(expired.size(), 0, "Nenhum expirado no turno 1")
	assert_eq(cs.get_active_bonuses()[0].remaining_turns, 2, "2 turnos restantes")


func test_bonuses_expire_after_duration():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	cs.craft("guisado_goblin")  ## duration 3
	cs.tick_bonuses()  ## 2
	cs.tick_bonuses()  ## 1
	var expired = cs.tick_bonuses()  ## 0 → expire
	assert_eq(expired.size(), 1, "Expirou após 3 turnos")
	assert_eq(expired[0], "Guisado de Goblin", "Nome do prato")


func test_permanent_elixir_no_expire():
	var cs = CookingSystem.new()
	cs.collect_ingredient("pedra_eterea", 2)
	cs.collect_ingredient("lagrima_fada", 1)
	cs.craft("elixir_etereo")  ## duration -1: não entra em buffs temporários
	for i in range(10):
		cs.tick_bonuses()
	assert_eq(cs.get_active_bonuses().size(), 0, "elixir não fica em buffs temporários")
	assert_eq(cs.get_crafted_count("elixir_etereo"), 1, "elixir registrado como craft permanente")


func test_get_total_bonuses():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	cs.craft("guisado_goblin")
	var totals = cs.get_total_bonuses()
	assert_eq(totals.hp, 20, "+20 HP total")
	assert_eq(totals.defense, 5, "+5 DEF total")


func test_crafted_count():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 4)
	cs.collect_ingredient("ervas_silvestres", 2)
	cs.craft("guisado_goblin")
	cs.craft("guisado_goblin")
	assert_eq(cs.get_crafted_count("guisado_goblin"), 2, "Crafted 2 vezes")


func test_collect_signal():
	var cs = CookingSystem.new()
	watch_signals(cs)
	cs.collect_ingredient("ervas_silvestres", 1)
	assert_signal_emitted(cs, "ingredient_collected")


func test_craft_signal():
	var cs = CookingSystem.new()
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	watch_signals(cs)
	cs.craft("guisado_goblin")
	assert_signal_emitted(cs, "recipe_crafted")


func test_get_all_recipes():
	var cs = CookingSystem.new()
	var recipes = cs.get_all_recipes()
	assert_true(recipes.has("guisado_goblin"), "Tem guisado")


## Balanceamento §7.2: prato mais caro (raridade-ponderada) deve dar bônus maiores.
func test_luxury_food_cost_proportional():
	var cs = CookingSystem.new()
	assert_gt(cs.recipe_cost("banquete_rei"), cs.recipe_cost("guisado_goblin"),
		"banquete custa mais que guisado (raridade-ponderada)")
	assert_gt(cs.recipe_cost("banquete_rei"), cs.recipe_cost("sopa_luminosa"),
		"banquete custa mais que sopa")
	var banquete = cs.get_all_recipes()["banquete_rei"].bonuses
	var guisado = cs.get_all_recipes()["guisado_goblin"].bonuses
	var banquete_value = banquete.hp + banquete.mp + banquete.attack + banquete.defense
	var guisado_value = guisado.hp + guisado.defense
	assert_gt(banquete_value, guisado_value, "banquete dá mais benefício que guisado")


func test_recipe_cost_derives_from_rarity():
	var cs = CookingSystem.new()
	# guisado: 2 carne(1) + 1 erva(1) = 3
	assert_eq(cs.recipe_cost("guisado_goblin"), 3, "guisado = 3")
	# elixir_etereo: 2 pedra(uncommon=2) + 1 lagrima(rare=3) = 7
	assert_eq(cs.recipe_cost("elixir_etereo"), 7, "elixir = 7")


func test_get_all_elixirs():
	var cs = CookingSystem.new()
	var elixirs = cs.get_all_elixirs()
	assert_true(elixirs.has("elixir_etereo"), "Tem elixir")


func test_get_all_ingredients():
	var cs = CookingSystem.new()
	var ingredients = cs.get_all_ingredients()
	assert_eq(ingredients.size(), 10, "10 ingredientes")
