extends Node

signal turn_started(unit: Unit)
signal turn_ended(unit: Unit)
signal individual_turn_started(unit: Unit)
signal round_started(order: Array)
signal phase_changed(phase: String)
signal unit_moved(unit: Unit, from: Vector2i, to: Vector2i)
signal unit_attacked(attacker: Unit, target: Unit, damage: int)
signal unit_died(unit: Unit)
signal battle_won()
signal battle_lost()
signal soul_ether_gained(amount: int)
signal ether_boost_applied(unit, charges: int)
signal timed_block_window(attacker: Unit, target: Unit)
signal wave_started(wave_index: int, total_waves: int)

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

var _ether_system: EtherSystem = EtherSystem.new()
var _terrain_system: TerrainEffectSystem = TerrainEffectSystem.new()
var _flanking_system: FlankingSystem = FlankingSystem.new()
var _adjacency_system: AdjacencySystem = AdjacencySystem.new()
var _timed_combat_system: TimedCombatSystem = TimedCombatSystem.new()
var _magic_system: MagicSystem = MagicSystem.new()

# Timed Block (GDD v2 §3.1): callable opcional que resolve a janela defensiva
# reativa (0.2s) antes do dano de um ataque inimigo em alvo jogador. Recebe
# (attacker, target) e retorna a fração de dano bloqueada (0.0–0.5). O
# battle_scene instala o resolver; sem ele, o dano chega integral (comportamento
# antigo — testes headless ficam síncronos).
var timed_block_resolver: Callable = Callable()

# Ordem de turnos velocity-based (GDD v2 §5.1): quem é mais rápido age primeiro.
# Quando ativo, cada unidade tem seu próprio turno dentro do round.
var use_individual_turns: bool = false
var _turn_order: Array = []
var _turn_index: int = 0

# Ondas escaladas (GDD §1 Ato III, decisão ROADMAP #7): em vez de 1.000+ unidades,
# batalhas longas reinjetam inimigos com stats escalados por onda. Config vazio =
# batalha única (comportamento padrão). Cada onda: {"enemies": [spec...],
# "stat_scale": float}; spec de unidade no formato de spawn do battle_scene.
var wave_config: Array = []
var current_wave: int = 0

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
 current_wave = 0
 start_player_turn()

# --- Ondas escaladas (GDD §1 Ato III, ROADMAP #7) ---

## Configura as ondas da batalha: [{enemies: [UnitData-spec...], stat_scale: float}].
## Onda 1 já está em cena (spawn normal); ondas 2..N são reinjetadas ao limpar.
func setup_waves(config: Array) -> void:
 wave_config = config
 current_wave = 0

## Total de ondas (0 se batalha única).
func get_total_waves() -> int:
 return wave_config.size()

func has_pending_waves() -> bool:
 return current_wave < wave_config.size() - 1

## Spawna a próxima onda: cria Units com stats escalados por stat_scale,
## registra no grid (posições livres da base para cima) e emite wave_started.
## Retorna as unidades criadas ([] se config não tem a onda).
func spawn_next_wave(spawn_spec_factory: Callable = Callable()) -> Array:
 if not has_pending_waves():
  return []
 current_wave += 1
 var wave: Dictionary = wave_config[current_wave]
 var scale: float = float(wave.get("stat_scale", 1.0 + 0.25 * current_wave))
 var spawned: Array = []
 for spec in wave.get("enemies", []):
  var unit: Unit = _make_wave_unit(spec, scale, spawn_spec_factory)
  if unit == null:
   continue
  var pos := _find_free_spawn_position()
  unit.grid_position = pos
  register_unit(unit)
  spawned.append(unit)
 if not spawned.is_empty():
  wave_started.emit(current_wave, wave_config.size())
 return spawned

## Fábrica de Unit para onda: usa a factory do caller (battle_scene cria Units
## com sprites/HP bars) ou cria Unit+UnitData crua (testes/headless).
func _make_wave_unit(spec: Dictionary, scale: float, factory: Callable):
 if factory.is_valid():
  var unit = factory.call(spec, scale)
  if unit != null:
   return unit
 var u: Unit = Unit.new()
 var d := UnitData.new()
 d.unit_name = String(spec.get("unit_name", spec.get("name", "Inimigo")))
 d.is_player = false
 d.max_hp = int(float(spec.get("hp", 50)) * scale)
 d.attack = int(float(spec.get("atk", 10)) * scale)
 d.defense = int(float(spec.get("def", 8)) * scale)
 d.speed = int(float(spec.get("spd", 8)) * scale)
 d.max_mp = int(spec.get("mp", 0))
 u.data = d
 u.current_hp = d.max_hp
 u.current_mp = d.max_mp
 return u

## Primeira posição livre no lado inimigo (metade direita do grid), varrendo
## colunas da direita para a esquerda e linhas do meio para fora.
func _find_free_spawn_position() -> Vector2i:
 var mid := grid_size.y / 2
 for x in range(grid_size.x - 1, grid_size.x / 2 - 1, -1):
  for offset in range(grid_size.y):
   for dy: int in [0, -1, 1, -2, 2]:
    var y: int = mid + dy + offset * (1 if offset % 2 == 0 else -1)
    if y < 0 or y >= grid_size.y:
     continue
    if is_walkable(Vector2i(x, y)):
     return Vector2i(x, y)
 return Vector2i(grid_size.x - 1, mid)

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
     await attack_unit(enemy, action.target)
    else:
     var move_pos = get_closer_position(enemy, action.target)
     if move_pos != enemy.grid_position:
      move_unit(enemy, move_pos)
      await get_tree().create_timer(0.2).timeout
      if enemy.grid_position.distance_to(action.target.grid_position) <= enemy.data.attack_range:
       await attack_unit(enemy, action.target)
  "cast":
   if action.has("spell_id") and action.has("target") and action.target.current_hp > 0:
    cast_magic(enemy, action.spell_id, action.target)
  "wait":
   pass

## Lança magia via MagicSystem no turno inimigo. Libera a UI (unit_attacked) pro
## dano aparecer; se matar o alvo, resolve a morte igual ao ataque físico
## (unit_died + unregister + soul_ether) pra batalha poder acabar. Se falhar
## (sem MP / spell desconhecido), nada acontece.
func cast_magic(enemy: Unit, spell_id: String, target: Unit) -> void:
 var spell = _magic_system.get_spell(spell_id)
 if spell.is_empty() or enemy.current_mp < spell.mp_cost:
  return
 var result = _magic_system.cast_spell(enemy, spell_id, [target])
 if result.success:
  for r in result.results:
   if r.has("damage"):
    unit_attacked.emit(enemy, target, r.damage)
  if target.current_hp <= 0:
   unit_died.emit(target)
   unregister_unit(target)
   soul_ether_gained.emit(target.data.soul_ether_value)
   soul_ether += target.data.soul_ether_value
   check_battle_end()

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
 # Salvar direção do movimento para flanqueamento (GDD v2 §3)
 unit.last_move_direction = (new_pos - old_pos).sign()
 set_tile_at(old_pos, null)
 unit.grid_position = new_pos
 set_tile_at(new_pos, unit)
 unit_moved.emit(unit, old_pos, new_pos)

func attack_unit(attacker: Unit, target: Unit, attacker_terrain: String = "", target_terrain: String = "", timing_bonus: float = 1.0, defense_bonus: int = 0) -> void:
 var damage = attacker.calculate_damage(target)

 # Pipeline: Base → Terreno → Flanqueamento → Adjacência (GDD v2 §3/§4)

 # Efeitos de terreno no dano
 if attacker_terrain != "":
  damage = int(damage * _terrain_system.get_attack_multiplier(attacker_terrain))
 if target_terrain != "":
  damage = int(damage * _terrain_system.get_defense_multiplier(target_terrain))

 # Flanqueamento: +25% se atacante está nas costas do alvo
 var is_flanking := _flanking_system.check_flanking(attacker, target)
 damage = int(damage * _flanking_system.get_flanking_multiplier(is_flanking))

 # Adjacência: bônus ATK/DEF de apóstolos adjacentes ao protagonista
 if attacker.data and not attacker.data.is_player:
  # Atacante inimigo — protag como alvo ganha DEF de apóstolos adjacentes
  var target_adj_def := _adjacency_system.get_defense_multiplier(target.grid_position, player_units)
  damage = int(damage * target_adj_def)
 elif attacker.data and attacker.data.is_player:
  # Atacante é protagonista — ganha ATK de apóstolos adjacentes
  var attacker_adj_atk := _adjacency_system.get_attack_multiplier(attacker.grid_position, player_units)
  damage = int(damage * attacker_adj_atk)

 # Timed Hit bonus (GDD v2 §3.1)
 damage = int(damage * timing_bonus)

 # Timed Block (GDD v2 §3.1): defesa reativa — ataque inimigo em alvo jogador
 # abre a janela de 0.2s; o resolver do battle_scene retorna a redução obtida.
 var block_reduction := 0.0
 if timed_block_resolver.is_valid() and not is_player_side(attacker) and is_player_side(target):
  timed_block_window.emit(attacker, target)
  block_reduction = await timed_block_resolver.call(attacker, target)
 damage = int(damage * (1.0 - block_reduction))

 damage = maxi(1, damage)

 target.take_damage(damage, defense_bonus)
 unit_attacked.emit(attacker, target, damage)

 # Éter Vivo: ataque gera 1 carga (GDD v2 §3.3)
 _ether_system.generate_on_hit(attacker)

 if target.current_hp <= 0:
  unit_died.emit(target)
  unregister_unit(target)
  soul_ether_gained.emit(target.data.soul_ether_value)
  soul_ether += target.data.soul_ether_value

 check_battle_end()

func check_battle_end() -> void:
 if player_units.size() == 0:
  battle_lost.emit()
  return
 if enemy_units.size() > 0:
  return
 # Inimigos zerados: reinjeta a próxima onda antes de declarar vitória
 # (GDD §1 Ato III — batalhas longas em ondas escaladas, decisão #7).
 if has_pending_waves():
  spawn_next_wave()
  return
 battle_won.emit()

func end_player_turn() -> void:
 current_phase = Phase.ANIMATING
 for unit in player_units:
  turn_ended.emit(unit)
 await get_tree().create_timer(0.5).timeout
 start_enemy_turn()

# ---------------------------------------------------------------------------
# Turnos individuais velocity-based (GDD v2 §2/§5.1)
# ---------------------------------------------------------------------------

func get_speed(unit: Unit) -> int:
 # Contrato exigido pelo TurnOrderManager
 return unit.data.speed if unit and unit.data else 0

func is_player_side(unit: Unit) -> bool:
 return unit.data.is_player if unit and unit.data else false

func is_alive(unit: Unit) -> bool:
 return unit != null and unit.current_hp > 0

func start_round() -> void:
 ## Constrói a ordem do round via TurnOrderManager e inicia o primeiro turno individual.
 _turn_order = TurnOrderManager.build_order(all_units)
 _turn_index = 0
 turn_count += 1
 round_started.emit(_turn_order)
 if _turn_order.is_empty():
  check_battle_end()
  return
 _begin_unit_turn(_turn_order[0])

func _begin_unit_turn(unit: Unit) -> void:
 current_phase = Phase.PLAYER_TURN if is_player_side(unit) else Phase.ENEMY_TURN
 phase_changed.emit("PLAYER_TURN" if is_player_side(unit) else "ENEMY_TURN")
 unit.reset_turn()
 _ether_system.regen_turn_start(unit)

 # Dano ambiental de terreno (GDD v2 §3.3 — lava: 5 HP ao iniciar turno)
 var terrain_damage := _get_unit_terrain_damage(unit)
 if terrain_damage > 0:
  unit.take_damage(terrain_damage)

 # Adjacência: Lira adjacent ao protagonista regenera 2% HP (GDD v2 §4)
 if unit.data and unit.data.is_player:
  var lira_regen := _adjacency_system.get_hp_regen(unit.grid_position, player_units, unit.data.max_hp)
  if lira_regen > 0:
   unit.heal(lira_regen)

 individual_turn_started.emit(unit)


func _get_unit_terrain_damage(unit: Unit) -> int:
 ## Retorna dano fixo de terreno para a unidade na sua posição atual.
 ## Chamado pelo _begin_unit_turn e pelo battle_scene (que tem acesso ao grid).
 ## Para testes unitários, o battle_scene pode passar o terreno diretamente.
 ## Retorna 0 se não houver dano.
 var terrain := _get_unit_terrain(unit)
 if terrain != "":
  return _terrain_system.get_turn_damage(terrain)
 return 0


func _get_unit_terrain(unit: Unit) -> String:
 ## Tenta obter o terreno da posição da unidade via BattleGrid (se disponível na scene tree).
 ## Retorna "" se não encontrar (safe fallback para testes unitários).
 var grids := get_tree().get_nodes_in_group("battle_grid") if is_inside_tree() else []
 for node in grids:
  if node.has_method("get_terrain_at"):
   return node.get_terrain_at(unit.grid_position)
 return ""

func advance_turn() -> void:
 ## Chamar quando a unidade atual terminou suas ações (agiu ou esperou).
 var next := _next_alive_index()
 if next == -1:
  start_round()  # round acabou -> novo round
 else:
  _turn_index = next
  _begin_unit_turn(_turn_order[_turn_index])

func _next_alive_index() -> int:
 ## Próximo índice com unidade viva; -1 se o round terminou.
 var i := _turn_index + 1
 while i < _turn_order.size():
  var u = _turn_order[i]
  if is_alive(u):
   return i
  i += 1
 return -1

func current_turn_unit() -> Unit:
 ## Unidade que tem a vez agora (modo individual).
 if _turn_order.is_empty() or _turn_index >= _turn_order.size():
  return null
 return _turn_order[_turn_index]
