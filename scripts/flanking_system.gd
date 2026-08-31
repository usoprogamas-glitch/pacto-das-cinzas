class_name FlankingSystem
extends RefCounted

## Sistema de Flanqueamento (GDD v2 §3 — +25% dano pelas costas)
##
## Unidade que ataca por trás (direção oposta ao último movimento do alvo)
## recebe +25% de bônus de dano.
##
## Núcleo puramente lógico: não conhece cena, árvore ou BattleManager.
## Contrato (duck typing):
##   - grid_position: Vector2i  (posição atual da unidade)
##   - last_move_direction: Vector2i  (direção do último movimento)
##
## Regras:
##   1. Ao mover, a unidade registra a direção do movimento.
##   2. Um atacante está "nas costas" se sua posição está na direção
##      oposta ao último movimento do alvo.
##   3. Bônus: +25% ao dano base (multiplicador 1.25).

const FLANKING_BONUS: float = 0.25
const FLANKING_MULTIPLIER: float = 1.25


## Retorna true se attacker_pos está nas costas do alvo.
## target_last_dir é a direção do último movimento do alvo.
func is_flanking(attacker_pos: Vector2i, target_pos: Vector2i, target_last_dir: Vector2i) -> bool:
 if target_last_dir == Vector2i.ZERO:
  return false
 var behind_pos := target_pos - target_last_dir
 return attacker_pos == behind_pos


## Retorna o multiplicador de dano por flanqueamento.
## 1.25 se está flanqueando, 1.0 caso contrário.
func get_flanking_multiplier(is_flanking: bool) -> float:
 return FLANKING_MULTIPLIER if is_flanking else 1.0


## Calcula se um atacante está flanqueando um alvo usando objetos com contrato.
## Aceita attacker e target com grid_position e last_move_direction.
func check_flanking(attacker, target) -> bool:
 if attacker == null or target == null:
  return false
 if not attacker.has_method("get_grid_position") or not target.has_method("get_grid_position"):
  return false
 return is_flanking(attacker.get_grid_position(), target.get_grid_position(), target.last_move_direction)
