class_name ProgressionSystem
extends RefCounted
## §8 Progressão Global — Tabela Síntese por Ato + Experience Curve
## Gerencia progresso do protagonista através dos 4 Atos, evolução de apóstolos,
## e curva de experiência para desbloqueio de habilidades.

signal act_unlocked(act_number: int)
signal memory_threshold_reached(percentage: int)

# Tabela de Progressão por Ato (GDD v2 §8)
const ACTS: Dictionary = {
	1: {
		"name": "A Fronteira Cinzenta",
		"protagonist_form": "Imp Menor",
		"memory_percent": 0,
		"focus": "Furtividade, Coleta & Sobrevivência",
		"main_enemy": "Hienas Bestiais & Batedores",
		"highlight_apostle": "kroug",
		"unlocks": ["goblin_tribe", "basic_camp"]
	},
	2: {
		"name": "O Despertar",
		"protagonist_form": "Nobre Abissal",
		"memory_percent": 25,
		"focus": "Combate Tático & Fortificação",
		"main_enemy": "Inquisidores de Aço",
		"highlight_apostle": "lira",
		"unlocks": ["fortress", "diplomacy_basic"]
	},
	3: {
		"name": "A Guerra Fria",
		"protagonist_form": "Arquidemônio",
		"memory_percent": 75,
		"focus": "Batalhas de 1.000+ Unidades & Diplomacia",
		"main_enemy": "Santos Cardeais & Paladinos",
		"highlight_apostle": "thalkor",
		"unlocks": ["army_command", "alliance_dwarves_elves"]
	},
	4: {
		"name": "O Clímax Cósmico",
		"protagonist_form": "Avatar Primordial",
		"memory_percent": 100,
		"focus": "Confronto Divino & Reescrita Cósmica",
		"main_enemy": "Aurius, o Falso Deus",
		"highlight_apostle": "all",
		"unlocks": ["divine_decree", "reality_rewrite"]
	}
}

# Curva de experiência: XP necessário por nível (1-50)
# Fórmula: base * (level ^ 1.5)
const XP_BASE: int = 100
const XP_CURVE_EXPONENT: float = 1.5
const MAX_LEVEL: int = 50

var current_act: int = 1
var total_memory: int = 0  # 0-100%
var named_souls: int = 0
var total_experience: int = 0

# Referência ao sistema de progressão de personagem existente
var _character_progression: CharacterProgression = null

# Referência ao LineageSystem canônico (GDD §3.4/§4) — evolui os apóstolos no avanço de ato
var _lineage_system: LineageSystem = null


func _init(char_progression: CharacterProgression = null) -> void:
	_character_progression = char_progression


func set_character_progression(char_progression: CharacterProgression) -> void:
	_character_progression = char_progression


func set_lineage_system(lineage_system: LineageSystem) -> void:
	_lineage_system = lineage_system


func get_xp_for_level(level: int) -> int:
	if level < 1 or level > MAX_LEVEL:
		return 0
	return int(XP_BASE * pow(level, XP_CURVE_EXPONENT))


func get_current_level() -> int:
	var accumulated_xp: int = 0
	for level in range(1, MAX_LEVEL + 1):
		accumulated_xp += get_xp_for_level(level)
		if total_experience < accumulated_xp:
			return level
	return MAX_LEVEL


func add_experience(amount: int) -> void:
	var old_level: int = get_current_level()
	total_experience += amount
	var new_level: int = get_current_level()

	if new_level > old_level:
		_on_level_up(old_level, new_level)


func _on_level_up(old_level: int, new_level: int) -> void:
	# Desbloquear habilidades baseado no novo nível
	# Level-up força avanço de ato (ignora requisitos de memória/almas)
	if new_level >= 10 and current_act < 2:
		_force_advance_to_act(2)
	elif new_level >= 25 and current_act < 3:
		_force_advance_to_act(3)
	elif new_level >= 40 and current_act < 4:
		_force_advance_to_act(4)


func _force_advance_to_act(act_number: int) -> void:
	"""Avança de ato sem verificar requisitos (usado por level-up)"""
	if act_number <= current_act or act_number > 4:
		return

	current_act = act_number
	act_unlocked.emit(act_number)

	# Evoluir os apóstolos (gates de ato respeitados por evolve_creature; idempotente)
	if _lineage_system:
		for creature in _lineage_system.get_all_creatures():
			_lineage_system.evolve_creature(creature, act_number)

	if _character_progression:
		var form_name: String = ACTS[act_number]["protagonist_form"]
		if _character_progression.forms.has(form_name):
			_character_progression.evolve_form(form_name)


func add_memory(percent: int) -> void:
	var old_memory: int = total_memory
	total_memory = mini(total_memory + percent, 100)

	# Dispara cada threshold UMA vez, apenas ao cruzá-lo (não re-emite em chamadas posteriores)
	var thresholds: Array = [25, 50, 75, 100]
	for threshold in thresholds:
		if old_memory < threshold and total_memory >= threshold:
			memory_threshold_reached.emit(threshold)

			# Avançar de Ato baseado em memória
			match threshold:
				25:
					try_advance_to_act(2)
				75:
					try_advance_to_act(3)
				100:
					try_advance_to_act(4)


func add_named_soul() -> void:
	named_souls += 1

	# Caminho alternativo do GDD: almas nomeadas destravam Atos sozinhas (10/100/1000)
	if named_souls >= 1000:
		try_advance_to_act(4)
	elif named_souls >= 100:
		try_advance_to_act(3)
	elif named_souls >= 10:
		try_advance_to_act(2)


func try_advance_to_act(act_number: int) -> bool:
	if act_number <= current_act or act_number > 4:
		return false

	if not _can_unlock_act(act_number):
		return false

	current_act = act_number
	act_unlocked.emit(act_number)

	# Evoluir os apóstolos (gates de ato respeitados; idempotente em re-chamadas)
	if _lineage_system:
		for creature in _lineage_system.get_all_creatures():
			_lineage_system.evolve_creature(creature, act_number)

	# Atualizar forma do protagonista no CharacterProgression
	if _character_progression:
		var form_name: String = ACTS[act_number]["protagonist_form"]
		if _character_progression.forms.has(form_name):
			_character_progression.evolve_form(form_name)

	return true


func _can_unlock_act(act_number: int) -> bool:
	match act_number:
		2:
			return total_memory >= 25 or named_souls >= 10
		3:
			return total_memory >= 75 or named_souls >= 100
		4:
			return total_memory >= 100 or named_souls >= 1000
		_:
			return false


func get_current_act_info() -> Dictionary:
	return ACTS.get(current_act, {})


func get_act_info(act_number: int) -> Dictionary:
	return ACTS.get(act_number, {})


func get_progress_summary() -> Dictionary:
	return {
		"current_act": current_act,
		"act_name": ACTS[current_act]["name"],
		"memory_percent": total_memory,
		"named_souls": named_souls,
		"total_xp": total_experience,
		"level": get_current_level(),
		"protagonist_form": ACTS[current_act]["protagonist_form"]
	}


# Para uso em save/load
func serialize() -> Dictionary:
	return {
		"current_act": current_act,
		"total_memory": total_memory,
		"named_souls": named_souls,
		"total_experience": total_experience
	}


func deserialize(data: Dictionary) -> void:
	current_act = data.get("current_act", 1)
	total_memory = data.get("total_memory", 0)
	named_souls = data.get("named_souls", 0)
	total_experience = data.get("total_experience", 0)
