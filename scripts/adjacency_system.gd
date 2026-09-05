class_name AdjacencySystem
extends RefCounted

## Elos Sinérgicos — Bônus passivos de adjacência (GDD v2 §4 Apóstolos)
##
## Se um Apóstolo está adjacente (distância Manhattan ≤ 1) ao Protagonista,
## aplica bônus passivo definido na tabela data-driven.
##
## Núcleo puramente lógico: não conhece cena, árvore ou BattleManager.
## Contrato (duck typing):
##   - grid_position: Vector2i
##   - data.unit_name: String
##   - data.is_player: bool
##   - current_hp: int
##   - data.max_hp: int

## --- Tabela de Elos Sinérgicos (data-driven: alterar aqui) ---
## Cada entrada: { "stat": "defense"|"hp_regen"|"attack", "bonus_type": "mult"|"flat", "value": float }
const SYNERGY_TABLE: Dictionary = {
 "kroug": {
  "stat": "defense",
  "bonus_type": "mult",
  "value": 1.15,
  "description": "+15% DEF para Protagonista adjacente"
 },
 "lira": {
  "stat": "hp_regen",
  "bonus_type": "percent_max",
  "value": 0.02,
  "description": "Regenera 2% HP do Protagonista por turno"
 },
 "thalkor": {
  "stat": "attack",
  "bonus_type": "mult",
  "value": 1.10,
  "description": "+10% ATK para Protagonista adjacente"
 },
}


## Retorna true se duas posições são adjacentes (distância Manhattan ≤ 1).
func are_adjacent(pos_a: Vector2i, pos_b: Vector2i) -> bool:
 return pos_a.distance_to(pos_b) == 1


## Retorna o nome normalizado de uma unidade para lookup na tabela.
func _normalize_name(unit_name: String) -> String:
 return unit_name.to_lower().replace(" ", "_").replace("'", "")


## Retorna o elos sinérgicos para um apóstolo (se existe na tabela).
func get_apostle_synergy(apostle_name: String) -> Dictionary:
 var key := _normalize_name(apostle_name)
 if SYNERGY_TABLE.has(key):
  return SYNERGY_TABLE[key]
 return {}


## Retorna true se uma unidade é apóstolo com elo sinérgico.
func has_synergy(apostle_name: String) -> bool:
 return SYNERGY_TABLE.has(_normalize_name(apostle_name))


## Calcula bônus de defesa total a partir de apóstolos adjacentes.
## Retorna o multiplicador acumulado (ex: 1.15 se Kroug adjacente).
## protagonist_pos: posição do protagonista
## allies: array de unidades aliadas (com grid_position, data.unit_name, data.is_player)
func get_defense_multiplier(protagonist_pos: Vector2i, allies: Array) -> float:
 var mult := 1.0
 for ally in allies:
  if ally == null or not ally.data or ally.data.is_player:
   continue
  if are_adjacent(protagonist_pos, ally.grid_position):
   var synergy := get_apostle_synergy(ally.data.unit_name)
   if synergy.get("stat") == "defense" and synergy.get("bonus_type") == "mult":
    mult *= synergy.value
 return mult


## Calcula bônus de ataque total a partir de apóstolos adjacentes.
## Retorna o multiplicador acumulado.
func get_attack_multiplier(protagonist_pos: Vector2i, allies: Array) -> float:
 var mult := 1.0
 for ally in allies:
  if ally == null or not ally.data or ally.data.is_player:
   continue
  if are_adjacent(protagonist_pos, ally.grid_position):
   var synergy := get_apostle_synergy(ally.data.unit_name)
   if synergy.get("stat") == "attack" and synergy.get("bonus_type") == "mult":
    mult *= synergy.value
 return mult


## Calcula regeneração de HP por turno a partir de apóstolos adjacentes.
## Retorna a quantidade de HP a regenerar.
func get_hp_regen(protagonist_pos: Vector2i, allies: Array, max_hp: int) -> int:
 var total_regen := 0
 for ally in allies:
  if ally == null or not ally.data or ally.data.is_player:
   continue
  if are_adjacent(protagonist_pos, ally.grid_position):
   var synergy := get_apostle_synergy(ally.data.unit_name)
   if synergy.get("stat") == "hp_regen" and synergy.get("bonus_type") == "percent_max":
    total_regen += int(max_hp * synergy.value)
 return total_regen


## Retorna lista de apóstolos adjacentes a uma posição.
func get_adjacent_apostles(pos: Vector2i, allies: Array) -> Array:
 var result: Array = []
 for ally in allies:
  if ally == null or not ally.data or ally.data.is_player:
   continue
  if are_adjacent(pos, ally.grid_position) and has_synergy(ally.data.unit_name):
   result.append(ally)
 return result
