class_name EtherSystem
extends RefCounted

## Sistema de Éter / Boost de Éter (GDD v2 §3.3)
##
## Mecânica central de combate: ataques normais geram cargas de Éter.
## O jogador pode gastar até 3 cargas para infundir dano de Éter em
## ataques físicos ou multiplicar o poder de magias.
##
## Núcleo puramente lógico: não conhece cena, árvore ou BattleManager.
## Trabalha com qualquer objeto que exponha o contrato (duck typing):
##   - get_ether() -> int   (cargas de Éter atuais da unidade)
##   - set_ether(n: int)    (define cargas de Éter)
##   - is_alive() -> bool   (HP > 0?)
##
## Regras (GDD v2 §3.3):
##   1. Cada ataque normal gera 1 carga de Éter (máx. 3).
##   2. Gastar cargas: cada carga adiciona +30% ao dano base (físico)
##      ou +50% ao poder mágico.
##   3. No início de cada turno, regenera 1 carga (máx. 3).
##   4. Unidades mortas não geram nem gastam Éter.

## --- Constantes de balanceamento (data-driven: alterar aqui) ---
const MAX_CHARGES: int = 3
const REGEN_PER_TURN: int = 1
const PHYSICAL_BONUS_PER_CHARGE: float = 0.3   # +30% por carga gasta
const MAGIC_BONUS_PER_CHARGE: float = 0.5      # +50% por carga gasta

## --- Sinais para UI / BattleManager ---
signal ether_changed(unit, new_amount: int)
signal ether_spent(unit, spent: int, remaining: int)
signal ether_generated(unit, amount: int, total: int)


## Gera 1 carga de Éter para uma unidade (chamar ao acertar ataque).
## Retorna true se houve geração efetiva.
func generate_on_hit(unit) -> bool:
 if unit == null or not unit.is_alive():
  return false
 var current: int = unit.get_ether()
 if current >= MAX_CHARGES:
  return false
 unit.set_ether(current + 1)
 ether_generated.emit(unit, 1, unit.get_ether())
 ether_changed.emit(unit, unit.get_ether())
 return true


## Regenera Éter no início do turno (1 carga).
## Retorna true se houve regeneração efetiva.
func regen_turn_start(unit) -> bool:
 if unit == null or not unit.is_alive():
  return false
 var current: int = unit.get_ether()
 if current >= MAX_CHARGES:
  return false
 unit.set_ether(current + 1)
 ether_generated.emit(unit, 1, unit.get_ether())
 ether_changed.emit(unit, unit.get_ether())
 return true


## Gasta cargas de Éter de uma unidade.
## Retorna as cargas realmente gastas (pode ser menor que pedido).
func spend(unit, amount: int) -> int:
 if unit == null or not unit.is_alive() or amount <= 0:
  return 0
 var current: int = unit.get_ether()
 var to_spend := mini(amount, current)
 if to_spend <= 0:
  return 0
 unit.set_ether(current - to_spend)
 ether_spent.emit(unit, to_spend, unit.get_ether())
 ether_changed.emit(unit, unit.get_ether())
 return to_spend


## Retorna o multiplicador de dano físico com base nas cargas gastas.
## Ex: 1 carga -> 1.3, 2 cargas -> 1.6, 3 cargas -> 1.9
func get_physical_multiplier(charges_spent: int) -> float:
 return 1.0 + (charges_spent * PHYSICAL_BONUS_PER_CHARGE)


## Retorna o multiplicador de dano mágico com base nas cargas gastas.
## Ex: 1 carga -> 1.5, 2 cargas -> 2.0, 3 cargas -> 2.5
func get_magic_multiplier(charges_spent: int) -> float:
 return 1.0 + (charges_spent * MAGIC_BONUS_PER_CHARGE)


## Gera Éter para todas as unidades vivas de um exército.
## Chamar ao final de um round completo para_simular o "Éter Vivo".
func regen_round_end(units: Array) -> void:
 for unit in units:
  if unit != null and unit.is_alive():
   regen_turn_start(unit)
