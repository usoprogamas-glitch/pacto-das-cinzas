class_name TurnOrderManager
extends RefCounted

## Ordem de turnos velocity-based (GDD §5.1: "quem é mais rápido ataca primeiro").
##
## Núcleo puramente lógico: não conhece cena, árvore ou BattleManager.
## Trabalha com qualquer objeto que exponha o contrato (duck typing):
##   - get_speed()      -> int   (velocidade atual da unidade)
##   - is_player_side() -> bool  (lado do jogador?)
##   - is_alive()       -> bool  (HP > 0?)
##
## Regras:
##   1. Ordena por velocidade DECRESCENTE (mais rápido age primeiro).
##   2. Empate de velocidade: unidade do jogador age antes da inimiga
##      (padrão Fire Emblem — generoso com o player).
##   3. Unidades mortas são excluídas da ordem.

signal turn_order_changed(order: Array)
signal unit_turn_started(unit)
signal unit_turn_ended(unit)


## Constrói e retorna a ordem de ação do round atual.
## Recebe Array de unidades (contrato acima), retorna Array ordenado.
static func build_order(units: Array) -> Array:
 var alive: Array = []
 for u in units:
  if u != null and u.is_alive():
   alive.append(u)

 alive.sort_custom(func(a, b) -> bool:
  if a.get_speed() == b.get_speed():
   return _player_first_tiebreak(a, b)
  return a.get_speed() > b.get_speed())

 return alive


## Empate: jogador vem antes de inimigo. Mesmo lado -> ordem indefinida.
static func _player_first_tiebreak(a, b) -> bool:
 if a.is_player_side() and not b.is_player_side():
  return true
 return false


## Emite os sinais de início/fim do turno de uma unidade na ordem.
## (Usado pela integração futura com BattleManager.)
func announce_round(units: Array) -> void:
 var order := build_order(units)
 turn_order_changed.emit(order)
 for u in order:
  unit_turn_started.emit(u)
  unit_turn_ended.emit(u)
