class_name LockSystem
extends RefCounted

## Sistema de Fechaduras e Quebra de Feitiços (GDD v2 §3.2)
##
## Inimigos preparam magias poderosas → locks (ícones de fraqueza) aparecem.
## O jogador deve atacar com os tipos de dano corretos antes do contador
## de turnos zerar. Quebrar todos = stun no inimigo + ganho de CP.

signal lock_created(enemy, lock: Dictionary)
signal lock_hit(enemy, lock: Dictionary, remaining: int)
signal lock_broken(enemy, lock: Dictionary)
signal all_locks_broken(enemy)
signal spell_cast(enemy, spell_name: String)

## Cast inimigo com lock defensivo (GDD §3.2): spell anunciado pelo inimigo,
## com locks que o jogador deve quebrar e turnos restantes até o cast resolver.
signal enemy_cast_started(enemy, spell_name: String, locks: Array, turns: int)

## --- Tipos de dano aceitos pelos locks (GDD §4) ---
enum DamageType { CORTE, PERFURACAO, CONTUSAO, ETER, FOGO, VENENO, SAGRADO }

## Mapeia nomes legíveis para o enum
const TYPE_NAMES: Dictionary = {
 "Corte": DamageType.CORTE,
 "Perfuração": DamageType.PERFURACAO,
 "Contusão": DamageType.CONTUSAO,
 "Éter": DamageType.ETER,
 "Fogo": DamageType.FOGO,
 "Veneno": DamageType.VENENO,
 "Sagrado": DamageType.SAGRADO,
}

## Dados de uma magia inimiga: quais locks ela gera
## Exemplo: { "spell_name": "Bola de Fogo", "locks": [{"type": "Corte", "hits": 2}], "turns": 3 }

## Estado vivo por inimigo: locks atuais + contador da magia anunciada
var _enemy_locks: Dictionary = {}  # enemy -> Array[Dictionary]
var _enemy_spells: Dictionary = {}  # enemy -> {spell_name, turns_remaining}


func get_locks(enemy) -> Array:
 return _enemy_locks.get(enemy, [])


func get_pending_spell(enemy) -> Dictionary:
 return _enemy_spells.get(enemy, {})


func clear_enemy(enemy) -> void:
 _enemy_locks.erase(enemy)
 _enemy_spells.erase(enemy)


func clear_all() -> void:
 _enemy_locks.clear()
 _enemy_spells.clear()


## Cria um lock em um inimigo.
## lock_data = { "type": "Corte", "hits": 2 }
## Retorna o lock criado com campo "remaining" adicionado.
func create_lock(enemy, lock_data: Dictionary) -> Dictionary:
 var lock := {
  "type": lock_data.type,
  "hits_required": lock_data.hits,
  "remaining": lock_data.hits,
 }
 lock_created.emit(enemy, lock)
 return lock


## Processa um ataque contra um lock específico.
## Retorna true se o lock foi quebrado.
func hit_lock(enemy, lock: Dictionary, attack_type: String) -> bool:
 if attack_type != lock.type:
  return false

 lock.remaining -= 1
 lock_hit.emit(enemy, lock, lock.remaining)

 if lock.remaining <= 0:
  lock_broken.emit(enemy, lock)
  return true
 return false


## Verifica se o tipo de ataque é efetivo contra o lock.
func is_effective(lock: Dictionary, attack_type: String) -> bool:
 return attack_type == lock.type


## Verifica se todos os locks de um inimigo foram quebrados.
## locks = Array de locks (dicionários com campo "remaining").
func all_broken(locks: Array) -> bool:
 for lock in locks:
  if lock.remaining > 0:
   return false
 return true


## Decrementa o turn counter de uma spell. Retorna o novo valor.
## Se chegar a 0, emite spell_cast e retorna 0.
func decrement_spell_counter(enemy, current_turns: int, spell_name: String) -> int:
 var new_val := maxi(0, current_turns - 1)
 if new_val == 0:
  spell_cast.emit(enemy, spell_name)
 return new_val


## --- Cast inimigo com lock defensivo (GDD §3.2, simetria) ---

## Inimigo anuncia uma magia: locks nascem nele (mesma mecânica dos chefes,
## espelhada pro jogador quebrar) e o contador de cast começa a girar.
## locks_data = spell.get("locks", []); turns = spell.get("cast_turns", 1).
func begin_enemy_cast(enemy, spell_id: String, locks_data: Array, turns: int) -> Array:
 var locks: Array = []
 for lock_data in locks_data:
  locks.append(create_lock(enemy, lock_data))
 _enemy_locks[enemy] = locks
 _enemy_spells[enemy] = {"spell_id": spell_id, "spell_name": spell_id, "turns_remaining": maxi(1, turns)}
 enemy_cast_started.emit(enemy, spell_id, locks, turns)
 return locks


## Jogador acerta o inimigo com um tipo de dano: processa os locks dele.
## Retorna true se algum lock foi quebrado neste golpe.
func player_hits_enemy(enemy, attack_type: String) -> bool:
 var broke_any := false
 var locks: Array = get_locks(enemy)
 for lock in locks:
  if lock.remaining > 0 and hit_lock(enemy, lock, attack_type):
   broke_any = true
 if broke_any and all_broken(locks):
  all_locks_broken.emit(enemy)
 return broke_any


## Avança o contador do cast anunciado do inimigo (1 por turno dele).
## Retorna: -1 sem cast pendente | n > 0 ainda carregando | 0 cast resolvido.
func tick_enemy_cast(enemy) -> int:
 var pending: Dictionary = _enemy_spells.get(enemy, {})
 if pending.is_empty():
  return -1
 var turns := decrement_spell_counter(enemy, int(pending.get("turns_remaining", 1)), String(pending.get("spell_name", "")))
 pending["turns_remaining"] = turns
 if turns <= 0:
  _enemy_spells.erase(enemy)
  return 0
 return turns


## Cast resolvido ou inimigo morto: locks somem.
func end_enemy_cast(enemy) -> void:
 clear_enemy(enemy)


## Retorna a penalidade de stun (em turnos) por quebrar todos os locks.
const STUN_DURATION: int = 1


## Resolve o resultado de quebrar todos os locks de uma magia.
## Retorna: { "stun_turns": int, "cp_reward": int }
func resolve_spellbreak() -> Dictionary:
 return {
  "stun_turns": STUN_DURATION,
  "cp_reward": 2,
 }


## Valida se uma string de tipo de dano é válida.
func is_valid_damage_type(type_name: String) -> bool:
 return TYPE_NAMES.has(type_name)


## Converte nome legível para enum DamageType. Retorna -1 se inválido.
func get_damage_type(type_name: String) -> int:
 return TYPE_NAMES.get(type_name, -1)
