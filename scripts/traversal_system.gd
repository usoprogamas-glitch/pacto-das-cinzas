class_name TraversalSystem
extends RefCounted

## Sistema de Travessia Dinâmica (GDD v2 §6.1)
##
## Gerencia movimentação vertical: escalada, salto, nado, planar.
## Cada habilidade tem requisitos e custos.

signal traversal_started(traversal_type: String)
signal traversal_completed(traversal_type: String)

## --- Tipos de terreno traversável ---
const TERRAIN_TYPES: Dictionary = {
 "ground": {"can_climb": false, "can_swim": false, "can_glide": false},
 "cliff": {"can_climb": true, "can_swim": false, "can_glide": false},
 "water": {"can_climb": false, "can_swim": true, "can_glide": false},
 "air": {"can_climb": false, "can_swim": false, "can_glide": true},
 "lava": {"can_climb": false, "can_swim": false, "can_glide": false, "damage_per_turn": 10},
 "ether_river": {"can_climb": false, "can_swim": true, "can_glide": false, "ether_regen": 2},
}

## --- Habilidades de travessia ---
const TRAVERSAL_ABILITIES: Dictionary = {
 "climb": {
  "name": "Escalar",
  "description": "Escalar penhascos e muralhas",
  "requires_wings": false,
  "stamina_cost": 20,
  "speed_multiplier": 0.5,
  "max_height": 5,
 },
 "jump": {
  "name": "Salto",
  "description": "Saltar de bordas e plataformas",
  "requires_wings": false,
  "stamina_cost": 15,
  "jump_height": 3,
  "jump_distance": 4,
 },
 "swim": {
  "name": "Nadar",
  "description": "Nadar em rios de éter e água",
  "requires_wings": false,
  "stamina_cost": 10,
  "speed_multiplier": 0.6,
  "can_dive": false,
 },
 "glide": {
  "name": "Planar",
  "description": "Usar Asas de Cinzas para planar",
  "requires_wings": true,
  "stamina_cost": 5,
  "speed_multiplier": 1.5,
  "max_distance": 8,
 },
 "ether_harpoon": {
  "name": "Arpêu do Éter",
  "description": "Atravessar fendas e puxar objetos",
  "requires_wings": true,
  "stamina_cost": 25,
  "range": 6,
  "can_pull_objects": true,
 },
 "dash": {
  "name": "Impulso",
  "description": "Dash rápido em qualquer direção",
  "requires_wings": false,
  "stamina_cost": 12,
  "dash_distance": 3,
  "cooldown": 1.0,
 },
}

## --- Estado do jogador ---
var _current_stamina: int = 100
var _max_stamina: int = 100
var _has_wings: bool = false
var _current_terrain: String = "ground"
var _is_traversing: bool = false
var _stamina_regen_rate: int = 5  ## por segundo

## --- Inicialização ---
func setup(has_wings: bool, max_stamina: int = 100) -> void:
 _has_wings = has_wings
 _max_stamina = max_stamina
 _current_stamina = max_stamina


## --- Consultas ---

## Retorna se o jogador pode usar uma habilidade de travessia.
func can_traverse(ability_name: String) -> Dictionary:
 if not TRAVERSAL_ABILITIES.has(ability_name):
  return {"can": false, "reason": "Habilidade desconhecida"}

 var ability = TRAVERSAL_ABILITIES[ability_name]

 if ability.requires_wings and not _has_wings:
  return {"can": false, "reason": "Precisa de asas"}

 if _current_stamina < ability.stamina_cost:
  return {"can": false, "reason": "Stamina insuficiente"}

 if not _can_use_in_terrain(ability_name):
  return {"can": false, "reason": "Não possível neste terreno"}

 return {"can": true, "reason": ""}


## Retorna se o jogador pode usar a habilidade no terreno atual.
func _can_use_in_terrain(ability_name: String) -> bool:
 var terrain = TERRAIN_TYPES.get(_current_terrain, {})
 match ability_name:
  "climb": return terrain.get("can_climb", false)
  "swim": return terrain.get("can_swim", false)
  "glide": return terrain.get("can_glide", false)
  _: return true  ## jump, dash, ether_harpoon podem ser usados em qualquer lugar


## Retorna o multiplicador de velocidade para o terreno atual.
func get_terrain_speed_multiplier() -> float:
 match _current_terrain:
  "water", "ether_river": return 0.6
  "cliff": return 0.4
  "lava": return 0.3
  _: return 1.0


## --- Ações ---

## Iniciar travessia (chamado quando jogador começa a se mover).
func start_traversal(ability_name: String) -> Dictionary:
 var check = can_traverse(ability_name)
 if not check.can:
  return check

 var ability = TRAVERSAL_ABILITIES[ability_name]
 _current_stamina -= ability.stamina_cost
 _is_traversing = true
 traversal_started.emit(ability_name)

 return {"can": true, "speed": ability.get("speed_multiplier", 1.0)}


## Finalizar travessia.
func end_traversal() -> void:
 _is_traversing = false
 traversal_completed.emit("")


## --- Nós de travessia do mapa (GDD §6.1, data-driven via MapDatabase) ---

## Valida + executa a travessia de um nó do mapa (fenda de arpéu, penhasco,
## desfiladeiro). meta opcional: {"height": int} para escalada, {"distance": int}
## para arpéu/impulso/salto. Consome stamina e emite traversal_started.
## Retorna {"can": true} ou {"can": false, "reason": motivo}.
func attempt_traversal(ability_name: String, meta: Dictionary = {}) -> Dictionary:
 var ability: Dictionary = TRAVERSAL_ABILITIES.get(ability_name, {})
 if ability.is_empty():
  return {"can": false, "reason": "Habilidade desconhecida"}

 # O nó do mapa é o próprio terreno: escalada = penhasco, planar = ar, nado = água.
 var terrain_map: Dictionary = {"climb": "cliff", "glide": "air", "swim": "water"}
 var old_terrain: String = _current_terrain
 if terrain_map.has(ability_name):
  _current_terrain = terrain_map[ability_name]
 var check = can_traverse(ability_name)
 _current_terrain = old_terrain
 if not check.can:
  return check

 var fail: String = _validate_node(ability, meta)
 if fail != "":
  return {"can": false, "reason": fail}

 _current_stamina = maxi(0, _current_stamina - int(ability.stamina_cost))
 _is_traversing = true
 traversal_started.emit(ability_name)
 return {"can": true, "speed": float(ability.get("speed_multiplier", 1.0))}


## Regras por nó: altura dentro do alcance da escalada, distância dentro do
## alcance da habilidade declarada no nó.
func _validate_node(ability: Dictionary, meta: Dictionary) -> String:
 if meta.has("height") and ability.has("max_height") and int(meta["height"]) > int(ability["max_height"]):
  return "Altura além do alcance da escalada"
 if meta.has("distance"):
  if ability.has("range") and int(meta["distance"]) > int(ability["range"]):
   return "Fora de alcance do arpéu"
  if ability.has("dash_distance") and int(meta["distance"]) > int(ability["dash_distance"]):
   return "Distância além do impulso"
  if ability.has("jump_distance") and int(meta["distance"]) > int(ability["jump_distance"]):
   return "Distância além do salto"
 return ""


## Atualizar stamina (chamado a cada frame ou timer).
func regen_stamina(delta: float) -> void:
 if not _is_traversing:
  _current_stamina = mini(_max_stamina, _current_stamina + int(_stamina_regen_rate * delta))


## Mudar terreno atual.
func set_terrain(terrain_type: String) -> void:
 _current_terrain = terrain_type


## --- Getters ---

func get_stamina() -> int:
 return _current_stamina

func get_max_stamina() -> int:
 return _max_stamina

func get_current_terrain() -> String:
 return _current_terrain

func has_wings() -> bool:
 return _has_wings

func is_traversing() -> bool:
 return _is_traversing

func get_ability_data(ability_name: String) -> Dictionary:
 return TRAVERSAL_ABILITIES.get(ability_name, {})

func get_all_abilities() -> Array:
 return TRAVERSAL_ABILITIES.keys()

func get_terrain_types() -> Array:
 return TERRAIN_TYPES.keys()
