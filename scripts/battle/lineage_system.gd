class_name LineageSystem
extends RefCounted

## Árvore de Linhagens Genético-Mágicas (GDD v2 §3.4)
##
## Matriz de evolução das criaturas após a nomeação.
## Cada criatura nomeada tem uma árvore de evolução com ramificações táticas.
## O jogador escolhe o caminho evolutivo ao atingir marcos de ato/nomes.

signal creature_evolved(creature_name: String, old_form: String, new_form: String)
signal branch_chosen(creature_name: String, branch: String)

## --- Evolução dos Apóstolos (GDD §4) ---
## Formas lineares dos apóstolos principais (cada um evolui em 3 atos)
const APOSTLE_EVOLUTIONS: Dictionary = {
	"Kroug": [
		{"form": "Goblin da Lama", "act": 0, "scale": 0.9, "focus": "Fuga / Provocação",
		 "stat_modifiers": {"hp": 0, "atk": 0, "def": 0, "speed": 0}},
		{"form": "Hobgoblin de Ferro", "act": 1, "scale": 1.9, "focus": "Parede de Escudos",
		 "stat_modifiers": {"hp": 50, "atk": 10, "def": 25, "speed": -5}},
		{"form": "Rei Ogro de Fogo", "act": 3, "scale": 3.8, "focus": "Quebra de Linhas & Lava",
		 "stat_modifiers": {"hp": 150, "atk": 40, "def": 50, "speed": -10}},
	],
	"Lira": [
		{"form": "Muda Mágica", "act": 0, "scale": 0.4, "focus": "Cura Básica de Área",
		 "stat_modifiers": {"hp": 0, "atk": 0, "def": 0, "speed": 0}},
		{"form": "Dríade Sombria", "act": 1, "scale": 1.7, "focus": "Suporte e Paralisia",
		 "stat_modifiers": {"hp": 30, "atk": 15, "def": 10, "speed": 5}},
		{"form": "Rainha Ent Primordial", "act": 3, "scale": 4.5, "focus": "Regeneração de Exército",
		 "stat_modifiers": {"hp": 100, "atk": 30, "def": 20, "speed": 10}},
	],
	"Thal'kor": [
		{"form": "Corvo Bestial", "act": 0, "scale": 0.6, "focus": "Exploração de Mapa",
		 "stat_modifiers": {"hp": 0, "atk": 0, "def": 0, "speed": 0}},
		{"form": "Harpia Noturna", "act": 2, "scale": 1.5, "focus": "Assassinato Rápido",
		 "stat_modifiers": {"hp": 20, "atk": 30, "def": 5, "speed": 20}},
		{"form": "Serafim Negro", "act": 3, "scale": 2.8, "focus": "Caçador de Generais",
		 "stat_modifiers": {"hp": 60, "atk": 70, "def": 15, "speed": 35}},
	],
	"Garm": [
		{"form": "Lobo Caolho", "act": 0, "scale": 0.7, "focus": "Montaria Veloz",
		 "stat_modifiers": {"hp": 0, "atk": 0, "def": 0, "speed": 0}},
		{"form": "Cão do Inferno Sombrio", "act": 1, "scale": 1.8, "focus": "Caça de Infantaria",
		 "stat_modifiers": {"hp": 40, "atk": 25, "def": 10, "speed": 15}},
		{"form": "Fenrir Menor", "act": 3, "scale": 3.5, "focus": "Quebra de Muralhas",
		 "stat_modifiers": {"hp": 120, "atk": 60, "def": 30, "speed": 25}},
	],
}

## --- Ramificações Táticas (GDD §3.4) ---
## Goblins da Lama podem evoluir para Vanguarda de Ferro OU Xamãs do Éter
## Dríades podem evoluir para Protetoras da Floresta OU Lianas Abissais
const BRANCHES: Dictionary = {
	"Goblin da Lama": [
		{"branch": "Vanguarda de Ferro", "role": "tank",
		 "stat_modifiers": {"hp": 80, "atk": 5, "def": 35, "speed": -5},
		 "description": "Mestre da defesa e provocação"},
		{"branch": "Xamãs do Éter", "role": "caster",
		 "stat_modifiers": {"hp": 20, "atk": 30, "def": 5, "speed": 10},
		 "description": "Mago de suporte com magia etérea"},
	],
	"Muda Mágica": [
		{"branch": "Protetoras da Floresta", "role": "healer",
		 "stat_modifiers": {"hp": 60, "atk": 10, "def": 15, "speed": 5},
		 "description": "Curandeira de área com vínculo natural"},
		{"branch": "Lianas Abissais", "role": "controller",
		 "stat_modifiers": {"hp": 40, "atk": 25, "def": 10, "speed": 15},
		 "description": "Controladora com raízes venenosas"},
	],
}

## --- Estado por criatura ---
## { "Kroug": { "current_form_index": 1, "branch": null } }
var _creature_states: Dictionary = {}


## Retorna a lista de formas de evolução de um apóstolo.
func get_evolution_path(creature_name: String) -> Array:
	return APOSTLE_EVOLUTIONS.get(creature_name, [])


## Retorna a forma atual de uma criatura.
func get_current_form(creature_name: String) -> String:
	if not _creature_states.has(creature_name):
		return ""
	var state = _creature_states[creature_name]
	var path = get_evolution_path(creature_name)
	if path.is_empty():
		return ""
	return path[state.current_form_index].form


## Retorna o índice da forma atual (0 = base, 1 = Ato I, 2 = Ato II/III).
func get_current_form_index(creature_name: String) -> int:
	if not _creature_states.has(creature_name):
		return -1
	return _creature_states[creature_name].current_form_index


## Inicializa uma criatura nomeada com a forma base.
func register_creature(creature_name: String) -> void:
	if not APOSTLE_EVOLUTIONS.has(creature_name):
		return
	_creature_states[creature_name] = {
		"current_form_index": 0,
		"branch": null,
	}


## Evolui uma criatura para a próxima forma linear (baseado no ato).
## Retorna true se a evolução ocorreu.
func evolve_creature(creature_name: String, current_act: int) -> bool:
	if not _creature_states.has(creature_name):
		return false
	var path = get_evolution_path(creature_name)
	var state = _creature_states[creature_name]
	var next_index = state.current_form_index + 1
	if next_index >= path.size():
		return false  ## Já está na forma máxima
	var next_form = path[next_index]
	if current_act < next_form.act:
		return false  ## Ato insuficiente
	var old_form = path[state.current_form_index].form
	state.current_form_index = next_index
	creature_evolved.emit(creature_name, old_form, next_form.form)
	return true


## Escolhe uma ramificação tática para uma criatura.
## Retorna true se a escolha foi válida.
func choose_branch(creature_name: String, branch_name: String) -> bool:
	if not _creature_states.has(creature_name):
		return false
	var state = _creature_states[creature_name]
	var path = get_evolution_path(creature_name)
	var current_form = path[state.current_form_index].form
	if not BRANCHES.has(current_form):
		return false  ## Forma atual não tem ramificações
	var branches = BRANCHES[current_form]
	for branch in branches:
		if branch.branch == branch_name:
			state.branch = branch_name
			branch_chosen.emit(creature_name, branch_name)
			return true
	return false  ## Ramificação não encontrada


## Retorna a ramificação escolhida de uma criatura.
func get_branch(creature_name: String) -> String:
	if not _creature_states.has(creature_name):
		return ""
	return _creature_states[creature_name].branch


## Retorna as ramificações disponíveis para a forma atual de uma criatura.
func get_available_branches(creature_name: String) -> Array:
	if not _creature_states.has(creature_name):
		return []
	var state = _creature_states[creature_name]
	var path = get_evolution_path(creature_name)
	if path.is_empty():
		return []
	var current_form = path[state.current_form_index].form
	return BRANCHES.get(current_form, [])


## Retorna os modificadores de stat da forma atual (incluindo ramificação).
func get_stat_modifiers(creature_name: String) -> Dictionary:
	if not _creature_states.has(creature_name):
		return {}
	var state = _creature_states[creature_name]
	var path = get_evolution_path(creature_name)
	if path.is_empty():
		return {}
	var modifiers = path[state.current_form_index].stat_modifiers.duplicate()
	## Aplicar bônus de ramificação se houver
	if state.branch:
		var branches = get_available_branches(creature_name)
		for branch in branches:
			if branch.branch == state.branch:
				for key in branch.stat_modifiers:
					modifiers[key] = modifiers.get(key, 0) + branch.stat_modifiers[key]
				break
	return modifiers


## Retorna true se uma criatura pode ser evoluida no ato atual.
func can_evolve(creature_name: String, current_act: int) -> bool:
	if not _creature_states.has(creature_name):
		return false
	var path = get_evolution_path(creature_name)
	var state = _creature_states[creature_name]
	var next_index = state.current_form_index + 1
	if next_index >= path.size():
		return false
	return current_act >= path[next_index].act


## Retorna true se a criatura está na forma máxima.
func is_max_form(creature_name: String) -> bool:
	if not _creature_states.has(creature_name):
		return false
	var path = get_evolution_path(creature_name)
	return _creature_states[creature_name].current_form_index >= path.size() - 1


## Retorna o estado completo de uma criatura (para UI/salvar).
func get_creature_state(creature_name: String) -> Dictionary:
	if not _creature_states.has(creature_name):
		return {}
	return _creature_states[creature_name].duplicate(true)


## Retorna todas as criaturas registradas.
func get_all_creatures() -> Array:
	return _creature_states.keys()


# Para uso em save/load
func serialize() -> Dictionary:
	return _creature_states.duplicate(true)


func deserialize(data: Dictionary) -> void:
	for name in data:
		if _creature_states.has(name):
			var s = _creature_states[name]
			s.current_form_index = data[name].get("current_form_index", 0)
			s.branch = data[name].get("branch", null)
