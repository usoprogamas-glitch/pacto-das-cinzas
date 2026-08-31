class_name TerrainEffectSystem
extends RefCounted

## Efeitos de Terreno no Dano (GDD v2 §3 Pipeline: Base → Flat → Mult)
##
## Tabela data-driven de modificadores de terreno para combate.
## Cada terreno pode afetar: defesa do defensor, ataque do atacante, dano fixo por turno.
##
## Núcleo puramente lógico: não conhece cena, árvore ou BattleManager.
## Exemplo de uso:
##   var effects = TerrainEffectSystem.new()
##   var mult = effects.get_defense_multiplier("forest")   # 1.15
##   var burn = effects.get_turn_damage("lava")             # 5

## --- Tabela de efeitos (data-driven: alterar aqui) ---
## Cada entrada: { defense_mult, attack_mult, turn_damage }
const EFFECTS: Dictionary = {
	"grass":  { "defense_mult": 1.0,  "attack_mult": 1.0,  "turn_damage": 0 },
	"dirt":   { "defense_mult": 1.0,  "attack_mult": 1.0,  "turn_damage": 0 },
	"stone":  { "defense_mult": 1.0,  "attack_mult": 1.10, "turn_damage": 0 },
	"forest": { "defense_mult": 1.15, "attack_mult": 1.0,  "turn_damage": 0 },
	"water":  { "defense_mult": 1.0,  "attack_mult": 0.80, "turn_damage": 0 },
	"cave":   { "defense_mult": 0.90, "attack_mult": 1.0,  "turn_damage": 0 },
	"castle": { "defense_mult": 1.20, "attack_mult": 1.0,  "turn_damage": 0 },
	"lava":   { "defense_mult": 1.0,  "attack_mult": 1.0,  "turn_damage": 5 },
}

const _DEFAULT := { "defense_mult": 1.0, "attack_mult": 1.0, "turn_damage": 0 }


## Retorna o multiplicador de defesa para o terreno informado.
## Ex: forest → 1.15, castle → 1.20, cave → 0.90
func get_defense_multiplier(terrain: String) -> float:
	return _get_entry(terrain).defense_mult


## Retorna o multiplicador de ataque para o terreno informado.
## Ex: water → 0.80, stone → 1.10
func get_attack_multiplier(terrain: String) -> float:
	return _get_entry(terrain).attack_mult


## Retorna o dano fixo por turno para o terreno informado.
## Ex: lava → 5, grass → 0
func get_turn_damage(terrain: String) -> int:
	return _get_entry(terrain).turn_damage


## Retorna true se o terreno causa dano fixo por turno.
func has_turn_damage(terrain: String) -> bool:
	return get_turn_damage(terrain) > 0


## Retorna a tabela completa de um terreno (para debug/UI).
func get_terrain_info(terrain: String) -> Dictionary:
	return _get_entry(terrain).duplicate()


## Retorna todos os terrenos com efeito ativo (diferente do default).
func get_all_effective_terrains() -> Array:
	var result: Array = []
	for key in EFFECTS:
		var entry: Dictionary = EFFECTS[key]
		if entry.defense_mult != 1.0 or entry.attack_mult != 1.0 or entry.turn_damage > 0:
			result.append(key)
	return result


## --- Interno ---

func _get_entry(terrain: String) -> Dictionary:
	if EFFECTS.has(terrain):
		return EFFECTS[terrain]
	return _DEFAULT
