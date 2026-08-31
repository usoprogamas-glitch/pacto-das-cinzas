class_name SeamlessEncounterSystem
extends RefCounted

## Sistema de Encontros Sem Tela de Carregamento (GDD v2 §6.2)
##
## Inimigos visíveis no mapa de exploração. Batalha ocorre no exato local
## sem transição para telas ou arenas de carregamento separadas.

signal encounter_started(enemy_data: Dictionary, position: Vector2i)
signal encounter_ended(victory: bool, rewards: Dictionary)

## --- Configuração de encontros ---
const ENCOUNTER_CONFIG: Dictionary = {
 "aggro_range": 2,  ## Distância para inimigo começar a perseguir
 "contact_range": 1,  ## Distância para batalha iniciar
 "flee_chance": 0.3,  ## Chance de fugir se nível muito alto
 "surprise_attack_bonus": 1.5,  ## Bônus de ataque surpresa
 "ambush_penalty": 0.7,  ## Penalidade se encurralado
}

## --- Tipos de encontro ---
const ENCOUNTER_TYPES: Dictionary = {
 "random": {
  "description": "Encontro aleatório ao explorar",
  "can_avoid": true,
  "preemptive_strike": false,
 },
 "scripted": {
  "description": "Encontro pré-definido no mapa",
  "can_avoid": false,
  "preemptive_strike": true,
 },
 "ambush": {
  "description": "Emboscada - inimigos cercam o jogador",
  "can_avoid": false,
  "preemptive_strike": false,
 },
 "boss": {
  "description": "Encontro com chefe",
  "can_avoid": false,
  "preemptive_strike": true,
 },
}

## --- Estado do sistema ---
var _active_enemies: Array[Dictionary] = []  ## Inimigos visíveis no mapa
var _current_encounter: Dictionary = {}
var _is_in_battle: bool = false
var _player_position: Vector2i = Vector2i.ZERO
var _encounter_history: Array[String] = []  ## Histórico de encontros


## --- Configuração ---

## Registrar inimigo no mapa de exploração.
func register_enemy(enemy_id: String, grid_pos: Vector2i, enemy_type: String, level: int) -> void:
 var enemy = {
  "id": enemy_id,
  "position": grid_pos,
  "type": enemy_type,
  "level": level,
  "state": "idle",  ## idle, chasing, fleeing, dead
  "aggro_range": ENCOUNTER_CONFIG.aggro_range,
  "contact_range": ENCOUNTER_CONFIG.contact_range,
 }
 _active_enemies.append(enemy)


## Remover inimigo do mapa.
func unregister_enemy(enemy_id: String) -> void:
 for i in range(_active_enemies.size()):
  if _active_enemies[i].id == enemy_id:
   _active_enemies.remove_at(i)
   return


## --- Atualização por turno/frame ---

## Atualizar posição do jogador e verificar encontros.
func update_player_position(new_pos: Vector2i) -> Dictionary:
 _player_position = new_pos
 return check_proximity()


## Verificar proximidade com inimigos.
func check_proximity() -> Dictionary:
 for enemy in _active_enemies:
  if enemy.state == "dead":
   continue

  var distance = _manhattan_distance(_player_position, enemy.position)

  if distance <= enemy.contact_range:
   ## Contato - iniciar batalha
   return _initiate_encounter(enemy)
  elif distance <= enemy.aggro_range:
   ## Perseguição
   enemy.state = "chasing"

 return {"encountered": false}


## --- Iniciar encontro ---

func _initiate_encounter(enemy: Dictionary) -> Dictionary:
 if _is_in_battle:
  return {"encountered": false}

 var encounter_type = _determine_encounter_type(enemy)
 var preemptive = _check_preemptive(enemy, encounter_type)

 _current_encounter = {
  "enemy": enemy,
  "type": encounter_type,
  "preemptive": preemptive,
  "position": enemy.position,
 }

 _is_in_battle = true
 encounter_started.emit(enemy, enemy.position)

 return {
  "encountered": true,
  "enemy": enemy,
  "preemptive": preemptive,
 }


## Determinar tipo de encontro.
func _determine_encounter_type(enemy: Dictionary) -> String:
 if enemy.type.begins_with("boss"):
  return "boss"
 if enemy.has("scripted") and enemy.scripted:
  return "scripted"
 return "random"


## Verificar ataque preemptivo.
func _check_preemptive(enemy: Dictionary, encounter_type: String) -> bool:
 var type_data = ENCOUNTER_TYPES.get(encounter_type, {})
 if type_data.get("preemptive_strike", false):
  ## Chance baseada na velocidade do jogador vs inimigo
  return randf() < 0.4
 return false


## --- Finalizar encontro ---

## Chamar quando batalha termina.
func end_encounter(victory: bool, rewards: Dictionary = {}) -> void:
 if victory:
  ## Remover inimigo derrotado
  if _current_encounter.has("enemy"):
   var enemy = _current_encounter.enemy
   enemy.state = "dead"
   unregister_enemy(enemy.id)

  _encounter_history.append(_current_encounter.enemy.type)

 _is_in_battle = false
 _current_encounter = {}
 encounter_ended.emit(victory, rewards)


## --- Utilidades ---

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
 return abs(a.x - b.x) + abs(a.y - b.y)


## --- Getters ---

func get_active_enemies() -> Array:
 return _active_enemies

func get_enemy_count() -> int:
 var count = 0
 for enemy in _active_enemies:
  if enemy.state != "dead":
   count += 1
 return count

func is_in_battle() -> bool:
 return _is_in_battle

func get_current_encounter() -> Dictionary:
 return _current_encounter

func get_encounter_history() -> Array:
 return _encounter_history

func get_encounter_config() -> Dictionary:
 return ENCOUNTER_CONFIG

func get_encounter_types() -> Dictionary:
 return ENCOUNTER_TYPES
