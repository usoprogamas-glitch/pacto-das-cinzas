extends "res://addons/gut/test.gd"

## Testes GUT para TerrainEffectSystem (Efeitos de Terreno, GDD v2 §3)


# --- Multiplicador de Defesa ---

func test_forest_defense_bonus():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_defense_multiplier("forest"), 1.15, "Floresta: +15% DEF")


func test_castle_defense_bonus():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_defense_multiplier("castle"), 1.20, "Castelo: +20% DEF")


func test_cave_defense_penalty():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_defense_multiplier("cave"), 0.90, "Caverna: -10% DEF")


func test_grass_neutral():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_defense_multiplier("grass"), 1.0, "Grama: neutro")


# --- Multiplicador de Ataque ---

func test_water_attack_penalty():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_attack_multiplier("water"), 0.80, "Água: -20% ATK")


func test_stone_attack_bonus():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_attack_multiplier("stone"), 1.10, "Pedra: +10% ATK")


# --- Dano por Turno ---

func test_lava_turn_damage():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_turn_damage("lava"), 5, "Lava: 5 HP por turno")


func test_grass_no_turn_damage():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_turn_damage("grass"), 0, "Grama: sem dano")


func test_has_turn_damage_lava():
	var t = TerrainEffectSystem.new()
	assert_true(t.has_turn_damage("lava"), "Lava deve ter dano por turno")


func test_has_turn_damage_grass():
	var t = TerrainEffectSystem.new()
	assert_false(t.has_turn_damage("grass"), "Grama não deve ter dano")


# --- Terreno desconhecido ---

func test_unknown_terrain_neutral():
	var t = TerrainEffectSystem.new()
	assert_eq(t.get_defense_multiplier("desert"), 1.0, "Terreno desconhecido: neutro DEF")
	assert_eq(t.get_attack_multiplier("desert"), 1.0, "Terreno desconhecido: neutro ATK")
	assert_eq(t.get_turn_damage("desert"), 0, "Terreno desconhecido: sem dano")


# --- get_all_effective_terrains ---

func test_effective_terrains_excludes_grass():
	var t = TerrainEffectSystem.new()
	var effective = t.get_all_effective_terrains()
	assert_false(effective.has("grass"), "Grama não deve estar na lista de efetivos")
	assert_true(effective.has("forest"), "Floresta deve estar na lista")
	assert_true(effective.has("lava"), "Lava deve estar na lista")
