class_name EnemyAI
extends RefCounted

enum AIState { IDLE, PATROL, CHASE, ATTACK, FLEE, CAST }

static func decide_action(enemy: Unit, all_units: Array[Unit], grid: BattleGrid) -> Dictionary:
 var ai_type = get_ai_type(enemy)
 var nearest_player = find_nearest_player(enemy, all_units)
 var nearest_ally = find_nearest_ally(enemy, all_units)
 var health_percent = float(enemy.current_hp) / float(enemy.data.max_hp)

 match ai_type:
  "aggressive":
   return aggressive_ai(enemy, nearest_player, grid)
  "ranged":
   return ranged_ai(enemy, nearest_player, grid)
  "caster":
   return caster_ai(enemy, nearest_player, all_units, grid)
  "tank":
   return tank_ai(enemy, nearest_player, nearest_ally, grid)
  "brute":
   return brute_ai(enemy, nearest_player, grid)
  "flanker":
   return flanker_ai(enemy, nearest_player, all_units, grid)
  "swarmer":
   return swarmer_ai(enemy, nearest_player, all_units, grid)
  "zombie":
   return zombie_ai(enemy, nearest_player, grid)
  "boss":
   return boss_ai(enemy, nearest_player, all_units, grid)
  _:
   return default_ai(enemy, nearest_player, grid)

static func aggressive_ai(enemy: Unit, target: Unit, grid: BattleGrid) -> Dictionary:
 if not target:
  return {"action": "wait"}

 var dist = enemy.grid_position.distance_to(target.grid_position)

 if dist <= enemy.data.attack_range:
  return {"action": "attack", "target": target}
 elif dist <= enemy.data.move_range + enemy.data.attack_range:
  var move_pos = get_closer_position(enemy, target, grid)
  if move_pos != enemy.grid_position:
   return {"action": "move", "position": move_pos}
  return {"action": "attack", "target": target}
 else:
  var move_pos = get_closer_position(enemy, target, grid)
  if move_pos != enemy.grid_position:
   return {"action": "move", "position": move_pos}
  return {"action": "wait"}

static func ranged_ai(enemy: Unit, target: Unit, grid: BattleGrid) -> Dictionary:
 if not target:
  return {"action": "wait"}

 var dist = enemy.grid_position.distance_to(target.grid_position)

 if dist <= enemy.data.attack_range:
  return {"action": "attack", "target": target}
 elif dist <= 2:
  var retreat_pos = get_away_position(enemy, target, grid)
  if retreat_pos != enemy.grid_position:
   return {"action": "move", "position": retreat_pos}
  return {"action": "attack", "target": target}
 else:
  var move_pos = get_closer_position(enemy, target, grid)
  if move_pos != enemy.grid_position:
   return {"action": "move", "position": move_pos}
  return {"action": "wait"}

static func caster_ai(enemy: Unit, target: Unit, all_units: Array, grid: BattleGrid) -> Dictionary:
 if not target:
  return {"action": "wait"}

 var allies_near = count_allies_near(target, all_units)

 if allies_near >= 2:
  return {"action": "attack", "target": target, "aoe": true}

 var dist = enemy.grid_position.distance_to(target.grid_position)
 if dist <= enemy.data.attack_range:
  return {"action": "attack", "target": target}
 else:
  var move_pos = get_closer_position(enemy, target, grid)
  if move_pos != enemy.grid_position:
   return {"action": "move", "position": move_pos}
  return {"action": "wait"}

static func tank_ai(enemy: Unit, target: Unit, ally: Unit, grid: BattleGrid) -> Dictionary:
 if ally and ally.current_hp < ally.data.max_hp * 0.3:
  var protect_pos = get_between_position(enemy, ally, target, grid)
  if protect_pos != enemy.grid_position:
   return {"action": "move", "position": protect_pos}

 if not target:
  return {"action": "wait"}

 var dist = enemy.grid_position.distance_to(target.grid_position)
 if dist <= enemy.data.attack_range:
  return {"action": "attack", "target": target}
 else:
  var move_pos = get_closer_position(enemy, target, grid)
  if move_pos != enemy.grid_position:
   return {"action": "move", "position": move_pos}
  return {"action": "wait"}

static func brute_ai(enemy: Unit, target: Unit, grid: BattleGrid) -> Dictionary:
 if not target:
  return {"action": "wait"}

 var dist = enemy.grid_position.distance_to(target.grid_position)
 if dist <= 1:
  return {"action": "attack", "target": target}
 else:
  var move_pos = get_closer_position(enemy, target, grid)
  if move_pos != enemy.grid_position:
   return {"action": "move", "position": move_pos}
  return {"action": "wait"}

static func flanker_ai(enemy: Unit, target: Unit, all_units: Array, grid: BattleGrid) -> Dictionary:
 if not target:
  return {"action": "wait"}

 var flank_pos = get_flank_position(enemy, target, all_units, grid)
 if flank_pos != enemy.grid_position:
  return {"action": "move", "position": flank_pos}

 var dist = enemy.grid_position.distance_to(target.grid_position)
 if dist <= enemy.data.attack_range:
  return {"action": "attack", "target": target}

 return {"action": "wait"}

static func swarmer_ai(enemy: Unit, target: Unit, all_units: Array, grid: BattleGrid) -> Dictionary:
 var isolated_player = find_isolated_player(enemy, all_units)

 if isolated_player:
  var dist = enemy.grid_position.distance_to(isolated_player.grid_position)
  if dist <= enemy.data.attack_range:
   return {"action": "attack", "target": isolated_player}
  var move_pos = get_closer_position(enemy, isolated_player, grid)
  if move_pos != enemy.grid_position:
   return {"action": "move", "position": move_pos}

 return aggressive_ai(enemy, target, grid)

static func zombie_ai(enemy: Unit, target: Unit, grid: BattleGrid) -> Dictionary:
 var health_percent = float(enemy.current_hp) / float(enemy.data.max_hp)
 if health_percent < 0.2:
  return {"action": "wait"}

 return brute_ai(enemy, target, grid)

static func boss_ai(enemy: Unit, target: Unit, all_units: Array, grid: BattleGrid) -> Dictionary:
 var health_percent = float(enemy.current_hp) / float(enemy.data.max_hp)

 if health_percent < 0.3:
  var weakest = find_weakest_player(all_units)
  if weakest:
   var dist = enemy.grid_position.distance_to(weakest.grid_position)
   if dist <= enemy.data.attack_range:
    return {"action": "attack", "target": weakest, "ultimate": true}

 var players_in_range = count_players_in_range(enemy, all_units)
 if players_in_range >= 2:
  return {"action": "attack", "target": target, "aoe": true}

 return aggressive_ai(enemy, target, grid)

static func default_ai(enemy: Unit, target: Unit, grid: BattleGrid) -> Dictionary:
 return aggressive_ai(enemy, target, grid)

static func get_ai_type(enemy: Unit) -> String:
 var name_lower = enemy.data.unit_name.to_lower()
 if "mercenario" in name_lower or "guerreiro" in name_lower:
  return "aggressive"
 elif "caçador" in name_lower or "arqueiro" in name_lower:
  return "ranged"
 elif "inquisidor" in name_lower or "mago" in name_lower:
  return "caster"
 elif "paladino" in name_lower:
  return "tank"
 elif "troll" in name_lower or "bruto" in name_lower:
  return "brute"
 elif "lobo" in name_lower:
  return "flanker"
 elif "aranha" in name_lower:
  return "swarmer"
 elif "esqueleto" in name_lower:
  return "zombie"
 elif "cardeal" in name_lower or "boss" in name_lower:
  return "boss"
 return "aggressive"

static func find_nearest_player(enemy: Unit, all_units: Array[Unit]) -> Unit:
 var nearest: Unit = null
 var min_dist: float = INF
 for unit in all_units:
  if unit.data and unit.data.is_player:
   var dist = enemy.grid_position.distance_to(unit.grid_position)
   if dist < min_dist:
    min_dist = dist
    nearest = unit
 return nearest

static func find_nearest_ally(enemy: Unit, all_units: Array[Unit]) -> Unit:
 var nearest: Unit = null
 var min_dist: float = INF
 for unit in all_units:
  if unit.data and not unit.data.is_player and unit != enemy:
   var dist = enemy.grid_position.distance_to(unit.grid_position)
   if dist < min_dist:
    min_dist = dist
    nearest = unit
 return nearest

static func find_weakest_player(all_units: Array[Unit]) -> Unit:
 var weakest: Unit = null
 var min_hp: float = INF
 for unit in all_units:
  if unit.data and unit.data.is_player and unit.current_hp < min_hp:
   min_hp = unit.current_hp
   weakest = unit
 return weakest

static func find_isolated_player(enemy: Unit, all_units: Array[Unit]) -> Unit:
 for unit in all_units:
  if unit.data and unit.data.is_player:
   var nearby_allies = 0
   for other in all_units:
    if other.data and other.data.is_player and other != unit:
     if unit.grid_position.distance_to(other.grid_position) <= 2:
      nearby_allies += 1
   if nearby_allies == 0:
    return unit
 return null

static func count_allies_near(target: Unit, all_units: Array) -> int:
 var count = 0
 for unit in all_units:
  if unit.data and unit.data.is_player and unit != target:
   if target.grid_position.distance_to(unit.grid_position) <= 2:
    count += 1
 return count

static func count_players_in_range(enemy: Unit, all_units: Array) -> int:
 var count = 0
 for unit in all_units:
  if unit.data and unit.data.is_player:
   if enemy.grid_position.distance_to(unit.grid_position) <= enemy.data.attack_range:
    count += 1
 return count

static func get_closer_position(enemy: Unit, target: Unit, grid: BattleGrid) -> Vector2i:
 var best_pos = enemy.grid_position
 var best_dist = enemy.grid_position.distance_to(target.grid_position)

 for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
  for step in range(1, enemy.data.move_range + 1):
   var test_pos = enemy.grid_position + dir * step
   if BattleManager.is_valid_position(test_pos) and BattleManager.is_walkable(test_pos):
    var dist = test_pos.distance_to(target.grid_position)
    if dist < best_dist:
     best_dist = dist
     best_pos = test_pos
   else:
    break
 return best_pos

static func get_away_position(enemy: Unit, target: Unit, grid: BattleGrid) -> Vector2i:
 var best_pos = enemy.grid_position
 var best_dist = enemy.grid_position.distance_to(target.grid_position)

 for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
  for step in range(1, enemy.data.move_range + 1):
   var test_pos = enemy.grid_position + dir * step
   if BattleManager.is_valid_position(test_pos) and BattleManager.is_walkable(test_pos):
    var dist = test_pos.distance_to(target.grid_position)
    if dist > best_dist:
     best_dist = dist
     best_pos = test_pos
   else:
    break
 return best_pos

static func get_flank_position(enemy: Unit, target: Unit, all_units: Array, grid: BattleGrid) -> Vector2i:
 var behind_target = target.grid_position + (target.grid_position - enemy.grid_position).sign()
 if BattleManager.is_valid_position(behind_target) and BattleManager.is_walkable(behind_target):
  return behind_target
 return get_closer_position(enemy, target, grid)

static func get_between_position(enemy: Unit, ally: Unit, target: Unit, grid: BattleGrid) -> Vector2i:
 var mid_point = (ally.grid_position + target.grid_position) / 2
 var temp_unit = Unit.new()
 temp_unit.grid_position = mid_point
 return get_closer_position(enemy, temp_unit, grid)

