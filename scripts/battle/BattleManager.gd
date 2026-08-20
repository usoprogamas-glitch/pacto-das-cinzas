extends Node

signal turn_started(unit: Unit)
signal turn_ended(unit: Unit)
signal phase_changed(phase: String)
signal unit_moved(unit: Unit, from: Vector2i, to: Vector2i)
signal unit_attacked(attacker: Unit, target: Unit, damage: int)
signal unit_died(unit: Unit)
signal battle_won()
signal battle_lost()
signal soul_ether_gained(amount: int)

enum Phase { PLAYER_TURN, ENEMY_TURN, ANIMATING }

var current_phase: Phase = Phase.PLAYER_TURN
var turn_count: int = 0
var selected_unit: Unit = null
var soul_ether: int = 0

var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var all_units: Array[Unit] = []

var grid_size: Vector2i = Vector2i(12, 12)
var grid: Array = []

func _ready() -> void:
 initialize_grid()

func initialize_grid() -> void:
 grid.clear()
 for y in grid_size.y:
  var row: Array = []
  for x in grid_size.x:
   row.append(null)
  grid.append(row)

func get_tile_at(grid_pos: Vector2i) -> Unit:
 if is_valid_position(grid_pos):
  return grid[grid_pos.y][grid_pos.x]
 return null

func set_tile_at(grid_pos: Vector2i, unit: Unit) -> void:
 if is_valid_position(grid_pos):
  grid[grid_pos.y][grid_pos.x] = unit

func is_valid_position(grid_pos: Vector2i) -> bool:
 return grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y

func is_walkable(grid_pos: Vector2i) -> bool:
 if not is_valid_position(grid_pos):
  return false
 return grid[grid_pos.y][grid_pos.x] == null

func register_unit(unit: Unit) -> void:
 all_units.append(unit)
 if unit.data and unit.data.is_player:
  player_units.append(unit)
 else:
  enemy_units.append(unit)
 set_tile_at(unit.grid_position, unit)

func unregister_unit(unit: Unit) -> void:
 all_units.erase(unit)
 player_units.erase(unit)
 enemy_units.erase(unit)
 set_tile_at(unit.grid_position, null)

func start_battle() -> void:
 turn_count = 0
 start_player_turn()

func start_player_turn() -> void:
 current_phase = Phase.PLAYER_TURN
 turn_count += 1
 for unit in player_units:
  unit.reset_turn()
 phase_changed.emit("PLAYER_TURN")
 turn_started.emit(null)

func start_enemy_turn() -> void:
 current_phase = Phase.ENEMY_TURN
 phase_changed.emit("ENEMY_TURN")
 for unit in enemy_units:
  if unit.current_hp <= 0:
   continue
  unit.reset_turn()
  await execute_enemy_ai(unit)
  await get_tree().create_timer(0.3).timeout
 check_battle_end()

func execute_enemy_ai(enemy: Unit) -> void:
 var action = EnemyAI.decide_action(enemy, all_units, null)

 match action.action:
  "move":
   if action.has("position"):
    move_unit(enemy, action.position)
    await get_tree().create_timer(0.2).timeout
  "attack":
   if action.has("target") and action.target.current_hp > 0:
    var dist = enemy.grid_position.distance_to(action.target.grid_position)
    if dist <= enemy.data.attack_range:
     attack_unit(enemy, action.target)
    else:
     var move_pos = get_closer_position(enemy, action.target)
     if move_pos != enemy.grid_position:
      move_unit(enemy, move_pos)
      await get_tree().create_timer(0.2).timeout
      if enemy.grid_position.distance_to(action.target.grid_position) <= enemy.data.attack_range:
       attack_unit(enemy, action.target)
  "wait":
   pass

func get_closer_position(enemy: Unit, target: Unit) -> Vector2i:
 var best_pos = enemy.grid_position
 var best_dist = enemy.grid_position.distance_to(target.grid_position)

 for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
  for step in range(1, enemy.data.move_range + 1):
   var test_pos = enemy.grid_position + dir * step
   if is_valid_position(test_pos) and is_walkable(test_pos):
    var dist = test_pos.distance_to(target.grid_position)
    if dist < best_dist:
     best_dist = dist
     best_pos = test_pos
   else:
    break
 return best_pos

func get_simple_path(start: Vector2i, end: Vector2i, max_steps: int) -> Array:
 var open: Array = []
 var closed: Array = []
 var came_from: Dictionary = {}
 var g_score: Dictionary = {}
 var f_score: Dictionary = {}

 var start_key = str(start)
 g_score[start_key] = 0
 f_score[start_key] = start.distance_to(end)
 open.append(start)

 while open.size() > 0:
  var current = open[0]
  var current_key = str(current)
  for pos in open:
   var pos_key = str(pos)
   if f_score.get(pos_key, INF) < f_score.get(current_key, INF):
    current = pos
    current_key = pos_key

  if current == end:
   var path = [current]
   while came_from.has(current_key):
    current = came_from[current_key]
    current_key = str(current)
    path.push_front(current)
   return path

  open.erase(current)
  closed.append(current)

  for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
   var neighbor = current + dir
   var neighbor_key = str(neighbor)
   if neighbor in closed:
    continue
   if not is_valid_position(neighbor) or not is_walkable(neighbor):
    continue

   var tentative_g = g_score[current_key] + 1
   if tentative_g > max_steps:
    continue

   if not open.has(neighbor):
    open.append(neighbor)
   elif tentative_g >= g_score.get(neighbor_key, INF):
    continue

   came_from[neighbor_key] = current
   g_score[neighbor_key] = tentative_g
   f_score[neighbor_key] = tentative_g + neighbor.distance_to(end)

 return []

func move_unit(unit: Unit, new_pos: Vector2i) -> void:
 var old_pos = unit.grid_position
 set_tile_at(old_pos, null)
 unit.grid_position = new_pos
 set_tile_at(new_pos, unit)
 unit_moved.emit(unit, old_pos, new_pos)

func attack_unit(attacker: Unit, target: Unit) -> void:
 var damage = attacker.calculate_damage(target)
 target.take_damage(damage)
 unit_attacked.emit(attacker, target, damage)

 if target.current_hp <= 0:
  unit_died.emit(target)
  unregister_unit(target)
  soul_ether_gained.emit(target.data.soul_ether_value)
  soul_ether += target.data.soul_ether_value

 check_battle_end()

func check_battle_end() -> void:
 if player_units.size() == 0:
  battle_lost.emit()
 elif enemy_units.size() == 0:
  battle_won.emit()

func end_player_turn() -> void:
 current_phase = Phase.ANIMATING
 for unit in player_units:
  turn_ended.emit(unit)
 await get_tree().create_timer(0.5).timeout
 start_enemy_turn()
