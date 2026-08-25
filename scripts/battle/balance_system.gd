class_name BalanceSystem
extends RefCounted

## Medidor de Éter vs Fúria de Kaelen (GDD v2 §3.3)
##
## Barra de equilíbrio psicológico do protagonista.
## Ações diplomáticas/cura → preenchem Éter.
## Execuções/destruição → preenchem Fúria.
## O jogador pode ativar Modo Éter, Modo Fúria ou buscar a Simbiose Cinzenta.

signal ether_changed(value: int)
signal fury_changed(value: int)
signal mode_changed(mode: String)
signal symbiosis_reached()

## --- Configuração ---
const MAX_VALUE: int = 100
const SYMBIOSIS_THRESHOLD: int = 50  ## Equilíbrio = ambos ≥ 50

## Ações que preenchem Éter (GDD §3.3)
const ETHER_ACTIONS: Dictionary = {
	"heal": 10,
	"diplomacy": 15,
	"liberate_monster": 20,
	"buff_ally": 8,
}

## Ações que preenchem Fúria (GDD §3.3)
const FURY_ACTIONS: Dictionary = {
	"execute": 15,
	"mass_destruction": 20,
	"retaliation": 12,
	"critical_kill": 10,
}

## Bônus do Modo Éter (GDD §3.3)
const ETHER_MODE_BONUSES: Dictionary = {
	"hp_regen_percent": 5,       ## 5% HP regen por turno
	"area_defense_percent": 15,  ## +15% defesa em área
	"loyalty_bonus": 10,         ## +10% lealdade da tropa
}

## Bônus do Modo Fúria (GDD §3.3)
const FURY_MODE_BONUSES: Dictionary = {
	"armor_penetration_percent": 25,  ## Penetração de armadura
	"critical_damage_percent": 40,    ## +40% dano crítico
	"terror_aura_radius": 3,          ## Raio de terror em tiles
}

## Modos disponíveis
enum Mode { ETHER, FURY, SYMBIOSIS, NEUTRAL }

var _ether: int = 0
var _fury: int = 0
var _current_mode: Mode = Mode.NEUTRAL


## Retorna o valor atual do Éter.
func get_ether() -> int:
	return _ether


## Retorna o valor atual da Fúria.
func get_fury() -> int:
	return _fury


## Retorna o modo ativo.
func get_current_mode() -> String:
	match _current_mode:
		Mode.ETHER: return "ETHER"
		Mode.FURY: return "FURY"
		Mode.SYMBIOSIS: return "SYMBIOSIS"
		_: return "NEUTRAL"


## Registra uma ação de Éter e retorna o valor ganho.
func perform_ether_action(action_name: String) -> int:
	if not ETHER_ACTIONS.has(action_name):
		return 0
	var gain: int = ETHER_ACTIONS[action_name]
	_ether = clampi(_ether + gain, 0, MAX_VALUE)
	ether_changed.emit(_ether)
	_check_mode()
	return gain


## Registra uma ação de Fúria e retorna o valor ganho.
func perform_fury_action(action_name: String) -> int:
	if not FURY_ACTIONS.has(action_name):
		return 0
	var gain: int = FURY_ACTIONS[action_name]
	_fury = clampi(_fury + gain, 0, MAX_VALUE)
	fury_changed.emit(_fury)
	_check_mode()
	return gain


## Define o modo manualmente (alternar entre Éter e Fúria).
func set_mode(mode: Mode) -> void:
	if mode == Mode.SYMBIOSIS:
		return  ## Simbiose só é alcançada automaticamente
	_current_mode = mode
	mode_changed.emit(get_current_mode())


## Verifica se a Simbiose Cinzenta foi alcançada.
## Condição: ambos ≥ 50 (GDD: "equilíbrio perfeito no endgame").
func is_symbiosis() -> bool:
	return _ether >= SYMBIOSIS_THRESHOLD and _fury >= SYMBIOSIS_THRESHOLD


## Retorna os bônus do modo ativo como Dictionary.
func get_active_bonuses() -> Dictionary:
	match _current_mode:
		Mode.ETHER:
			return ETHER_MODE_BONUSES.duplicate()
		Mode.FURY:
			return FURY_MODE_BONUSES.duplicate()
		Mode.SYMBIOSIS:
			## Simbiose = ambos os bônus combinados
			var combined := ETHER_MODE_BONUSES.duplicate()
			for key in FURY_MODE_BONUSES:
				combined[key] = FURY_MODE_BONUSES[key]
			return combined
		_:
			return {}


## Retorna bônus específico do modo ativo.
func get_bonus(key: String) -> int:
	var bonuses = get_active_bonuses()
	return bonuses.get(key, 0)


## Verifica e atualiza o modo baseado nos valores.
func _check_mode() -> void:
	if is_symbiosis():
		if _current_mode != Mode.SYMBIOSIS:
			_current_mode = Mode.SYMBIOSIS
			mode_changed.emit("SYMBIOSIS")
			symbiosis_reached.emit()
	elif _current_mode == Mode.SYMBIOSIS:
		## Saiu da simbiose
		_current_mode = Mode.NEUTRAL
		mode_changed.emit("NEUTRAL")


## Reseta o medidor para o estado inicial.
func reset() -> void:
	_ether = 0
	_fury = 0
	_current_mode = Mode.NEUTRAL
	ether_changed.emit(_ether)
	fury_changed.emit(_fury)
	mode_changed.emit("NEUTRAL")


## Retorna o progresso de cada lado como porcentagem (0-100).
func get_progress() -> Dictionary:
	return {
		"ether_percent": _ether,
		"fury_percent": _fury,
		"is_symbiosis": is_symbiosis(),
	}
