class_name ComboSystem
extends RefCounted

## Pontos de Combo (CP) — GDD v2 §3.3
##
## Acertos sincronizados (Timed Hit PERFECT) e quebra de locks geram CP.
## CP permite usar magias combinadas poderosas sem gasto de MP.
## Max 3 CP (GDD: "até 3 cargas").

signal cp_changed(current: int, max_val: int)
signal cp_spent(amount: int, combo_name: String)
signal combo_activated(combo_name: String, description: String)

const MAX_CP: int = 3

## CP ganho por ação
const PERFECT_HIT_CP: int = 1
const LOCK_BREAK_CP: int = 2
const GREAT_HIT_CP: int = 0

## Magias de combo definidas no GDD §4.1
## Cada combo = { name, cost, participants: Array[String], description }
const COMBOS: Array = [
	{
		"name": "Erupção de Éter",
		"cost": 1,
		"participants": ["Querubim", "Kroug"],
		"description": "Fusão de energia sagrada e terra para quebra de múltiplos locks",
	},
	{
		"name": "Tempestade das Cinzas",
		"cost": 3,
		"participants": ["Querubim", "Lira", "Thal'kor"],
		"description": "Dano massivo de veneno, corte e fogo que atordoa o exército inimigo",
	},
]


var _cp: int = 0


## Retorna o CP atual.
func get_cp() -> int:
	return _cp


## Adiciona CP (com clamp no máximo).
func add_cp(amount: int) -> void:
	_cp = clampi(_cp + amount, 0, MAX_CP)
	cp_changed.emit(_cp, MAX_CP)


## Gana CP de um Timed Hit PERFECT.
func earn_from_timed_hit(grade: String) -> void:
	if grade == "PERFECT":
		add_cp(PERFECT_HIT_CP)


## Ganha CP de uma quebra de lock.
func earn_from_lock_break() -> void:
	add_cp(LOCK_BREAK_CP)


## Gasta CP para usar uma combo spell.
## Retorna true se o jogador tem CP suficiente.
func spend_cp(cost: int, combo_name: String) -> bool:
	if cost < 0 or cost > MAX_CP:
		return false
	if _cp < cost:
		return false
	_cp -= cost
	cp_spent.emit(cost, combo_name)
	cp_changed.emit(_cp, MAX_CP)
	return true

## Ativa uma combo spell (gasta CP e dispara o efeito via sinal).
## Retorna true se a combo foi ativada.
func activate_combo(combo: Dictionary, active_participants: Array) -> bool:
	if not can_use_combo(combo, active_participants):
		return false
	if not spend_cp(combo.cost, combo.name):
		return false
	combo_activated.emit(combo.name, combo.description)
	return true


## Verifica se uma combo está disponível (CP suficiente e participantes no campo).
func can_use_combo(combo: Dictionary, active_participants: Array) -> bool:
	if _cp < combo.cost:
		return false
	for participant in combo.participants:
		if participant not in active_participants:
			return false
	return true


## Retorna lista de combos disponíveis com os participantes ativos.
func get_available_combos(active_participants: Array) -> Array:
	var available: Array = []
	for combo in COMBOS:
		if can_use_combo(combo, active_participants):
			available.append(combo)
	return available


## Reseta CP (novo round/batalha).
func reset() -> void:
	_cp = 0
	cp_changed.emit(_cp, MAX_CP)


## Retorna oCP máximo.
func get_max_cp() -> int:
	return MAX_CP
