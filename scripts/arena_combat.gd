class_name ArenaCombat
extends RefCounted

## Núcleo de combate arena (molde Sea of Stars — decisão 2026-08-31):
## sem grid tático. Lógica pura, headless-testável; a cena (arena_battle.gd)
## só apresenta e consome este núcleo.
##
## Contrato de unidade (duck typing, igual TurnOrderManager):
##   get_speed() -> int | is_player_side() -> bool | is_alive() -> bool
##   current_hp / max_hp / atk / def / current_mp

const TIMED_HIT_WINDOW := 0.3  ## s (TimedCombatSystem.ATTACK_WINDOW)
const TIMED_BLOCK_WINDOW := 0.2  ## s (TimedCombatSystem.BLOCK_WINDOW)
const MAGIC_COST := 10
const MAGIC_MULTIPLIER := 1.6

## Canais de dano do jogador na arena (GDD §3.2): ataque físico = Corte,
## magia = Éter. Os locks de enemy_spell declaram apenas esses dois tipos —
## data não pode pedir dano que o jogador não tem como entregar.
const PLAYER_PHYSICAL_TYPE := "Corte"
const PLAYER_MAGIC_TYPE := "Éter"

var timed_combat := TimedCombatSystem.new()
var lock_system := LockSystem.new()

# Cast inimigo com locks (GDD §3.2): instance_id -> estado do cast canalizado.
var _charges: Dictionary = {}
var _stuns: Dictionary = {}  # instance_id -> turnos de stun restantes


## Ordem de ação do round: herda o velocity-sort do TurnOrderManager (GDD §5.1).
func build_turn_order(units: Array) -> Array:
 return TurnOrderManager.build_order(units)


## Leitura de stats com duck typing: Unit (data.attack/defense) ou objeto cru
## com atk/def diretos.
func _attack_of(u) -> int:
 if u.data != null and u.data.get("attack") != null:
  return int(u.data.attack)
 return int(u.atk)


func _defense_of(u) -> int:
 if u.data != null and u.data.get("defense") != null:
  return int(u.data.defense)
 return int(u.def)


## Dano base: attack vs defense com variação ±15% (mesma curva do grid).
func calculate_damage(attacker, target, timing_multiplier: float = 1.0) -> int:
 var base := maxi(1, _attack_of(attacker) - _defense_of(target))
 var variation := randf_range(0.85, 1.15)
 return maxi(1, int(base * variation * timing_multiplier))


## Magia: ignora metade da defesa (perfura o tank), custo em MP.
func cast_damage_spell(caster, target) -> Dictionary:
 if caster.current_mp < MAGIC_COST:
  return {"success": false, "damage": 0}
 caster.current_mp -= MAGIC_COST
 var base := maxi(1, int(_attack_of(caster) * MAGIC_MULTIPLIER) - int(_defense_of(target) * 0.5))
 var variation := randf_range(0.85, 1.15)
 return {"success": true, "damage": maxi(1, int(base * variation))}


## Aplica o golpe resolvido: dano já com timed hit/block embutidos pela cena.
func apply_hit(attacker, target, damage: int) -> int:
 target.current_hp = maxi(0, target.current_hp - damage)
 return target.current_hp


## IA inimiga: alvo jogador de menor HP (foca kill), desempate aleatório.
## Só considera unidades do lado do jogador (o array pode vir sujo).
func choose_enemy_target(players: Array):
 var alive := players.filter(func(u): return u.is_alive() and u.is_player_side())
 if alive.is_empty():
  return null
 alive.sort_custom(func(a, b): return a.current_hp < b.current_hp)
 return alive[0]


## Batalha terminou? Vantagem do jogador no desempate de checagem.
func is_battle_over(units: Array) -> String:
 var players_alive := false
 var enemies_alive := false
 for u in units:
  if u.is_alive():
   if u.is_player_side():
    players_alive = true
   else:
    enemies_alive = true
 if not players_alive:
  return "defeat"
 if not enemies_alive:
  return "victory"
 return ""


# --- Cast inimigo com locks (GDD §3.2) ---
# Inimigo canaliza: locks (ícones de fraqueza) aparecem; o jogador ataca com o
# tipo certo antes do contador zerar. Quebrar todos = stun no inimigo; deixar
# zerar = feitiço sai.

## Estado do cast do inimigo ({} se não está canalizando).
func get_charge(u) -> Dictionary:
 return _charges.get(u.get_instance_id(), {})


func is_charging(u) -> bool:
 return _charges.has(u.get_instance_id())


## Inicia o canal do feitiço: cria os locks via LockSystem e guarda o estado.
## spec = {"name", "damage", "charge_turns", "locks": [{"type", "hits"}]}.
func start_charge(u, spec: Dictionary) -> Dictionary:
 var locks: Array = []
 for lock_data in spec.get("locks", []):
  locks.append(lock_system.create_lock(u, lock_data))
 var charge := {
  "spell_name": String(spec.get("name", "Feitiço")),
  "damage": int(spec.get("damage", 0)),
  "turns_left": int(spec.get("charge_turns", 2)),
  "locks": locks,
 }
 _charges[u.get_instance_id()] = charge
 return charge


## Golpe do jogador no canalizador: dentes os locks do tipo correspondente
## ("Corte" físico / "Éter" mágico). Retorna {"hit": bool, "interrupted": bool}:
## hit = algum lock foi atingido; interrupted = todos quebrados (spellbreak —
## charge limpo + stun registrado). Dano físico sempre passa, mas só o tipo
## certo dentes o lock.
func hit_charge(u, attack_type: String) -> Dictionary:
 var charge: Dictionary = get_charge(u)
 if charge.is_empty():
  return {"hit": false, "interrupted": false}
 var hit_any := false
 for lock in charge["locks"]:
  var before: int = lock["remaining"]
  lock_system.hit_lock(u, lock, attack_type)
  if lock["remaining"] < before:
   hit_any = true
 if lock_system.all_broken(charge["locks"]):
  _charges.erase(u.get_instance_id())
  apply_stun(u, LockSystem.STUN_DURATION)
  return {"hit": true, "interrupted": true}
 return {"hit": hit_any, "interrupted": false}


## Tick no turno do próprio canalizador. "charging" = continua canalizando;
## "casting" = contador zerou e o feitiço sai (estado limpo); "" = não canaliza.
func tick_charge(u) -> String:
 var charge: Dictionary = get_charge(u)
 if charge.is_empty():
  return ""
 charge["turns_left"] = lock_system.decrement_spell_counter(u, charge["turns_left"], charge["spell_name"])
 if charge["turns_left"] <= 0:
  _charges.erase(u.get_instance_id())
  return "casting"
 return "charging"


## Marca stun (spellbreak): o inimigo perde `turns` turnos.
func apply_stun(u, turns: int) -> void:
 _stuns[u.get_instance_id()] = int(_stuns.get(u.get_instance_id(), 0)) + turns


## Consome o stun no início do turno do inimigo. True = perdeu o turno.
func tick_stun(u) -> bool:
 if not _stuns.has(u.get_instance_id()):
  return false
 var left := int(_stuns[u.get_instance_id()]) - 1
 if left <= 0:
  _stuns.erase(u.get_instance_id())
 else:
  _stuns[u.get_instance_id()] = left
 return true
