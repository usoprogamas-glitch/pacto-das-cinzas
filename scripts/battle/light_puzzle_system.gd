class_name LightPuzzleSystem
extends RefCounted

## Sistema de Puzzles Ambientais de Luz e Eclipse (GDD v2 §6.3)
##
## Manipular tempo e luz para projetar eclipses locais usando
## espelhos de obsidiana e relógios cósmicos.

signal puzzle_solved(puzzle_id: String, reward: Dictionary)
signal mirror_aligned(mirror_id: String, angle: int)
signal eclipse_activated(eclipse_type: String)

## --- Tipos de puzzle ---
const PUZZLE_TYPES: Dictionary = {
 "mirror_alignment": {
  "name": "Alinhamento de Espelhos",
  "description": "Alinhar espelhos de obsidiana para direcionar feixe de luz",
  "mirrors_needed": 2,
  "has_clock": false,
 },
 "eclipse_timing": {
  "name": "Timing de Eclipse",
  "description": "Usar relógio cósmico para criar eclipse no momento certo",
  "mirrors_needed": 0,
  "has_clock": true,
 },
 "light_bridge": {
  "name": "Ponte de Luz",
  "description": "Criar ponte de luz solidificada alinhando espelhos",
  "mirrors_needed": 3,
  "has_clock": false,
 },
 "shadow_reveal": {
  "name": "Revelação de Sombra",
  "description": "Projetar sombras para revelar passagens secretas",
  "mirrors_needed": 1,
  "has_clock": true,
 },
}

## --- Configuração de espelhos ---
const MIRROR_CONFIG: Dictionary = {
 "rotation_steps": 8,  ## 8 direções (0-7, cada uma = 45°)
 "angle_per_step": 45,
 "max_range": 10,  ## Alcance do feixe de luz
}

## --- Estado do puzzle ---
var _current_puzzle: String = ""
var _puzzle_type: String = ""
var _mirrors: Dictionary = {}  ## {mirror_id: {angle: int, position: Vector2i, aligned: bool}}
var _clock_time: int = 0  ## Tempo do relógio cósmico (0-11)
var _light_source: Vector2i = Vector2i.ZERO
var _target_position: Vector2i = Vector2i.ZERO
var _eclipse_active: bool = false
var _solved_puzzles: Array[String] = []


## --- Configurar puzzle ---

## Iniciar um novo puzzle.
func start_puzzle(puzzle_id: String, puzzle_type: String, light_pos: Vector2i, target_pos: Vector2i) -> bool:
 if not PUZZLE_TYPES.has(puzzle_type):
  return false

 _current_puzzle = puzzle_id
 _puzzle_type = puzzle_type
 _light_source = light_pos
 _target_position = target_pos
 _mirrors.clear()
 _clock_time = 0
 _eclipse_active = false

 return true


## Adicionar espelho ao puzzle.
func add_mirror(mirror_id: String, position: Vector2i, initial_angle: int = 0) -> void:
 _mirrors[mirror_id] = {
  "angle": initial_angle,
  "position": position,
  "aligned": false,
 }
 _check_mirror_alignment(mirror_id)


## --- Interações ---

## Rotacionar espelho ( ciclo de 8 direções ).
func rotate_mirror(mirror_id: String, direction: int = 1) -> int:
 if not _mirrors.has(mirror_id):
  return -1

 var mirror = _mirrors[mirror_id]
 mirror.angle = (mirror.angle + direction) % MIRROR_CONFIG.rotation_steps
 if mirror.angle < 0:
  mirror.angle += MIRROR_CONFIG.rotation_steps

 mirror_aligned.emit(mirror_id, mirror.angle * MIRROR_CONFIG.angle_per_step)
 _check_mirror_alignment(mirror_id)

 return mirror.angle


## Avançar relógio cósmico.
func advance_clock() -> int:
 _clock_time = (_clock_time + 1) % 12
 _check_eclipse()
 return _clock_time


## Definir tempo do relógio diretamente.
func set_clock_time(time: int) -> void:
 _clock_time = clampi(time, 0, 11)
 _check_eclipse()


## --- Verificações ---

## Verificar se espelho está alinhado corretamente.
func _check_mirror_alignment(mirror_id: String) -> void:
 if not _mirrors.has(mirror_id):
  return

 var mirror = _mirrors[mirror_id]
 ## Espelho está alinhado se aponta na direção do alvo
 var direction_to_target = _target_position - mirror.position
 var target_angle = _calculate_angle(direction_to_target)
 var mirror_angle = mirror.angle * MIRROR_CONFIG.angle_per_step

 mirror.aligned = (absi(mirror_angle - target_angle) <= MIRROR_CONFIG.angle_per_step)


## Calcular ângulo em graus (simplificado para 8 direções).
func _calculate_angle(direction: Vector2i) -> int:
 if direction.x == 0 and direction.y < 0:
  return 0  ## Norte
 elif direction.x > 0 and direction.y < 0:
  return 45  ## Nordeste
 elif direction.x > 0 and direction.y == 0:
  return 90  ## Leste
 elif direction.x > 0 and direction.y > 0:
  return 135  ## Sudeste
 elif direction.x == 0 and direction.y > 0:
  return 180  ## Sul
 elif direction.x < 0 and direction.y > 0:
  return 225  ## Sudoeste
 elif direction.x < 0 and direction.y == 0:
  return 270  ## Oeste
 elif direction.x < 0 and direction.y < 0:
  return 315  ## Noroeste
 return 0


## Verificar se eclipse está ativo (relógio no tempo certo).
func _check_eclipse() -> void:
 var puzzle_data = PUZZLE_TYPES.get(_puzzle_type, {})
 if not puzzle_data.get("has_clock", false):
  return

 ## Eclipse occurs at specific times (3 and 9 = meio-dia e meia-noite)
 if _clock_time == 3 or _clock_time == 9:
  _eclipse_active = true
  eclipse_activated.emit("total" if _clock_time == 3 else "penumbral")
 else:
  _eclipse_active = false


## Verificar se puzzle está resolvido.
func check_solved() -> bool:
 var puzzle_data = PUZZLE_TYPES.get(_puzzle_type, {})
 var mirrors_needed = puzzle_data.get("mirrors_needed", 0)

 match _puzzle_type:
  "mirror_alignment":
   return _mirrors.size() >= mirrors_needed and _check_all_mirrors_aligned()
  "eclipse_timing":
   return _eclipse_active
  "light_bridge":
   return _mirrors.size() >= mirrors_needed and _check_all_mirrors_aligned() and _eclipse_active
  "shadow_reveal":
   return _mirrors.size() > 0 and _eclipse_active
 return false


func _check_all_mirrors_aligned() -> bool:
 if _mirrors.is_empty():
  return false
 for mirror_id in _mirrors:
  if not _mirrors[mirror_id].aligned:
   return false
 return true


## Finalizar puzzle (chamado quando resolvido).
func complete_puzzle(rewards: Dictionary = {}) -> bool:
 if not check_solved():
  return false

 _solved_puzzles.append(_current_puzzle)
 puzzle_solved.emit(_current_puzzle, rewards)
 _current_puzzle = ""
 return true


## --- Getters ---

func get_current_puzzle() -> String:
 return _current_puzzle

func get_puzzle_type() -> String:
 return _puzzle_type

func get_mirror(mirror_id: String) -> Dictionary:
 return _mirrors.get(mirror_id, {})

func get_all_mirrors() -> Dictionary:
 return _mirrors

func get_mirror_count() -> int:
 return _mirrors.size()

func get_clock_time() -> int:
 return _clock_time

func is_eclipse_active() -> bool:
 return _eclipse_active

func get_solved_puzzles() -> Array:
 return _solved_puzzles

func get_puzzle_types() -> Dictionary:
 return PUZZLE_TYPES

func is_puzzle_active() -> bool:
 return _current_puzzle != ""
