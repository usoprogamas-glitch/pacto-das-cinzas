class_name TimedCombatSystem
extends RefCounted

## Timed Hits & Blocks (GDD v2 §3.1 — janela 0.2s–0.3s)
##
## Mecânica Sea of Stars: jogador aperta botão no momento do impacto
## para aumentar dano (Timed Hit) ou reduzir dano recebido (Timed Block).
##
## Núcleo puramente lógico: não processa input, apenas resolve timing.
## O battle_scene chama resolve_timing() / resolve_block_timing() quando
## o jogador pressiona o botão dentro da janela.
##
## Janelas (GDD §3.1):
##   Attack window: 0.3s (Perfect 0.1s, Great 0.2s, Good 0.3s)
##   Block window: 0.2s (Perfect 0.05s, Great 0.1s, Good 0.2s)

signal timed_hit_resolved(grade: String, multiplier: float)
signal timed_block_resolved(grade: String, reduction: float)

## --- Constantes de timing ---
const ATTACK_WINDOW: float = 0.3
const BLOCK_WINDOW: float = 0.2

## Grade de bônus: { tempo_max → { grade, multiplier } }
const ATTACK_GRADES: Array = [
	{ "max_time": 0.1, "grade": "PERFECT", "multiplier": 1.5 },
	{ "max_time": 0.2, "grade": "GREAT", "multiplier": 1.25 },
	{ "max_time": 0.3, "grade": "GOOD", "multiplier": 1.1 },
]

const BLOCK_GRADES: Array = [
	{ "max_time": 0.05, "grade": "PERFECT", "reduction": 0.5 },
	{ "max_time": 0.1, "grade": "GREAT", "reduction": 0.3 },
	{ "max_time": 0.2, "grade": "GOOD", "reduction": 0.1 },
]

const MISS_MULTIPLIER: float = 0.5
const MISS_REDUCTION: float = 0.0
const DEFAULT_ATTACK_MULTIPLIER: float = 1.0
const DEFAULT_BLOCK_REDUCTION: float = 0.0


## Calcula o grade do Timed Hit baseado no tempo decorrido (em segundos).
## Retorna: { "grade": String, "multiplier": float }
func resolve_timing(elapsed: float) -> Dictionary:
	for grade in ATTACK_GRADES:
		if elapsed <= grade.max_time:
			var result := { "grade": grade.grade, "multiplier": grade.multiplier }
			timed_hit_resolved.emit(grade.grade, grade.multiplier)
			return result
	var result := { "grade": "MISS", "multiplier": MISS_MULTIPLIER }
	timed_hit_resolved.emit("MISS", MISS_MULTIPLIER)
	return result


## Calcula o grade do Timed Block baseado no tempo decorrido.
## Retorna: { "grade": String, "reduction": float }
func resolve_block_timing(elapsed: float) -> Dictionary:
	for grade in BLOCK_GRADES:
		if elapsed <= grade.max_time:
			var result := { "grade": grade.grade, "reduction": grade.reduction }
			timed_block_resolved.emit(grade.grade, grade.reduction)
			return result
	var result := { "grade": "MISS", "reduction": MISS_REDUCTION }
	timed_block_resolved.emit("MISS", MISS_REDUCTION)
	return result


## Retorna o multiplicador de dano aplicado pelo Timed Hit.
## Usado pelo BattleManager: damage = int(base_damage * get_attack_multiplier(grade_result))
func get_attack_multiplier(grade_result: Dictionary) -> float:
	return grade_result.get("multiplier", DEFAULT_ATTACK_MULTIPLIER)


## Retorna a fração de dano bloqueado pelo Timed Block.
## Redução de 0.5 = 50% do dano é bloqueado.
func get_block_reduction(grade_result: Dictionary) -> float:
	return grade_result.get("reduction", DEFAULT_BLOCK_REDUCTION)


## Aplica o bloqueio ao dano recebido.
## damage * (1.0 - reduction)
func apply_block(damage: int, grade_result: Dictionary) -> int:
	var reduction := get_block_reduction(grade_result)
	var blocked := int(damage * reduction)
	return maxi(0, damage - blocked)


## Retorna a duração da janela de ataque (para UI/input).
func get_attack_window() -> float:
	return ATTACK_WINDOW


## Retorna a duração da janela de bloqueio (para UI/input).
func get_block_window() -> float:
	return BLOCK_WINDOW
