class_name BossSystem
extends RefCounted

## Sistema de Chefes — Os Cinco Santos Cardeais + Aurius (GDD v2 §5)
##
## Gerencia encontros de boss com múltiplas fases, partes quebráveis,
## barras de feitiços com locks complexos e mecânicas temáticas.

signal boss_phase_changed(boss_name: String, phase: int)
signal boss_part_broken(boss_name: String, part_name: String)
signal boss_spell_charging(boss_name: String, spell_name: String, turns_left: int)
signal boss_defeated(boss_name: String)
signal boss_hp_changed(boss_name: String, hp: int, max_hp: int)

## --- Configuração dos Cinco Santos Cardeais (GDD §5) ---
const CARDINALS: Dictionary = {
	"Ignis": {
		"title": "Santo Cardeal do Fogo",
		"element": "Fogo",
		"theme": "Lava Branca",
		"hp": 500,
		"armor": 30,
		"parts": [
			{"name": "Coroa Solar", "hp": 150, "weakness": "Éter", "break_effect": "remove_shield"},
			{"name": "Cetro de Chamas", "hp": 100, "weakness": "Veneno", "break_effect": "reduce_damage"},
		],
		"spells": [
			{"name": "Erupção Vulcânica", "charge_turns": 3, "damage": 200, "locks": [{"type": "Contusão", "hits": 2}, {"type": "Éter", "hits": 1}]},
			{"name": "Lava Branca", "charge_turns": 4, "damage": 150, "locks": [{"type": "Veneno", "hits": 2}]},
		],
		"passive": "Combate em plataformas sobre lava branca; exige controle de temperatura",
	},
	"Zephyr": {
		"title": "Santo Cardeal do Vento",
		"element": "Vento",
		"theme": "Tempestades de Vento",
		"hp": 450,
		"armor": 20,
		"parts": [
			{"name": "Asas de Vento", "hp": 120, "weakness": "Corte", "break_effect": "remove_flight"},
			{"name": "Grito Sônico", "hp": 80, "weakness": "Contusão", "break_effect": "silence"},
		],
		"spells": [
			{"name": "Tempestade de Lâminas", "charge_turns": 2, "damage": 180, "locks": [{"type": "Corte", "hits": 3}]},
			{"name": "Tornado Devastador", "charge_turns": 3, "damage": 120, "locks": [{"type": "Fogo", "hits": 2}]},
		],
		"passive": "Combate aéreo com tempestades de vento que repelem unidades leves",
	},
	"Aqua": {
		"title": "Santo Cardeal da Água",
		"element": "Água",
		"theme": "Água Benta Corrosiva",
		"hp": 480,
		"armor": 25,
		"parts": [
			{"name": " Cálice Sagrado", "hp": 130, "weakness": "Fogo", "break_effect": "remove_heal"},
			{"name": "Corrente de Água", "hp": 90, "weakness": "Corte", "break_effect": "slow"},
		],
		"spells": [
			{"name": "Maré Corrosiva", "charge_turns": 3, "damage": 160, "locks": [{"type": "Fogo", "hits": 2}, {"type": "Contusão", "hits": 1}]},
			{"name": "Dilúvio de Prata", "charge_turns": 4, "damage": 200, "locks": [{"type": "Éter", "hits": 2}]},
		],
		"passive": "Marés de água benta corrosiva que desintegram armaduras",
	},
	"Terra": {
		"title": "Santo Cardeal da Terra",
		"element": "Terra",
		"theme": "Muralhas Vivas de Mármore",
		"hp": 600,
		"armor": 50,
		"parts": [
			{"name": "Muralha de Mármore", "hp": 200, "weakness": "Perfuração", "break_effect": "remove_wall"},
			{"name": "Punho de Pedra", "hp": 150, "weakness": "Fogo", "break_effect": "reduce_damage"},
		],
		"spells": [
			{"name": "Terremoto", "charge_turns": 4, "damage": 250, "locks": [{"type": "Perfuração", "hits": 2}, {"type": "Corte", "hits": 2}]},
			{"name": "Esmagar", "charge_turns": 2, "damage": 180, "locks": [{"type": "Contusão", "hits": 3}]},
		],
		"passive": "Muralhas de mármore que se movem, esmagando unidades lentas",
	},
	"Umbra": {
		"title": "Santo Cardeal das Trevas",
		"element": "Sombra",
		"theme": "Ilusões de Luz Negra",
		"hp": 420,
		"armor": 22,
		"parts": [
			{"name": "Máscara de Sombra", "hp": 100, "weakness": "Sagrado", "break_effect": "remove_illusions"},
			{"name": "Lâmina Negra", "hp": 110, "weakness": "Éter", "break_effect": "stun"},
		],
		"spells": [
			{"name": "Inquisição Noturna", "charge_turns": 3, "damage": 170, "locks": [{"type": "Sagrado", "hits": 2}, {"type": "Éter", "hits": 1}]},
			{"name": "Ilusão de Luz Negra", "charge_turns": 2, "damage": 140, "locks": [{"type": "Sagrado", "hits": 3}]},
		],
		"passive": "Inquisição noturna com ilusões de luz negra, exigindo percepção de Kaelen",
	},
}

## --- Configuração de Aurius (3 fases, GDD §5) ---
const AURIUS: Dictionary = {
	"name": "Aurius",
	"title": "O Falso Deus",
	"phases": [
		{
			"phase": 1,
			"name": "O Falso Demiurgo",
			"hp": 800,
			"armor": 40,
			"parts": [
				{"name": "Trono Monumental", "hp": 200, "weakness": "Éter", "break_effect": "remove_prayer_shield"},
				{"name": "Coroa Solar", "hp": 150, "weakness": "Corte", "break_effect": "reduce_armor"},
			],
			"spells": [
				{"name": "Oração dos Devotos", "charge_turns": 4, "damage": 300, "locks": [{"type": "Éter", "hits": 3}, {"type": "Sagrado", "hits": 2}]},
				{"name": "Raio de Juízo", "charge_turns": 3, "damage": 200, "locks": [{"type": "Corte", "hits": 2}]},
			],
			"description": "Trono monumental; usa orações dos devotos como escudo absoluto",
		},
		{
			"phase": 2,
			"name": "O Serafim Tirano",
			"hp": 600,
			"armor": 30,
			"parts": [
				{"name": "Asas Solares", "hp": 180, "weakness": "Fogo", "break_effect": "remove_flight"},
				{"name": "Lança de Luz", "hp": 120, "weakness": "Éter", "break_effect": "disarm"},
			],
			"spells": [
				{"name": "Bombardeio de Lanças", "charge_turns": 2, "damage": 250, "locks": [{"type": "Corte", "hits": 3}, {"type": "Fogo", "hits": 2}]},
				{"name": "Geometria Solar", "charge_turns": 3, "damage": 180, "locks": [{"type": "Éter", "hits": 2}]},
			],
			"description": "Combate em voo; bombardeio de lanças de luz geométrica",
		},
		{
			"phase": 3,
			"name": "A Luz Desesperada",
			"hp": 500,
			"armor": 15,
			"parts": [
				{"name": "Núcleo de Luz", "hp": 250, "weakness": "Éter", "break_effect": "stun"},
				{"name": "Aura Instável", "hp": 100, "weakness": "Veneno", "break_effect": "weaken"},
			],
			"spells": [
				{"name": "Explosão de Solaria", "charge_turns": 5, "damage": 500, "locks": [{"type": "Éter", "hits": 3}, {"type": "Corte", "hits": 2}, {"type": "Veneno", "hits": 2}]},
				{"name": "Luz Devastadora", "charge_turns": 2, "damage": 300, "locks": [{"type": "Sagrado", "hits": 3}]},
			],
			"description": "Forma instável de puro brilho; tenta explodir Solaria para apagar o Éter",
		},
	],
}

## --- Estado do boss atual ---
var _current_boss: String = ""
var _current_phase: int = 0
var _boss_hp: int = 0
var _part_hp: Dictionary = {}
var _spell_counters: Dictionary = {}


## Inicializa um boss cardinal para o encontro.
func init_cardinal(cardinal_name: String) -> void:
	if not CARDINALS.has(cardinal_name):
		return
	_current_boss = cardinal_name
	_current_phase = 0
	var boss = CARDINALS[cardinal_name]
	_boss_hp = boss.hp
	_part_hp.clear()
	_spell_counters.clear()
	for part in boss.parts:
		_part_hp[part.name] = part.hp
	for spell in boss.spells:
		_spell_counters[spell.name] = spell.charge_turns
	boss_hp_changed.emit(_current_boss, _boss_hp, _max_hp())


## Inicializa Aurius para o encontro.
func init_aurius() -> void:
	_current_boss = "Aurius"
	_current_phase = 0
	_load_aurius_phase(0)
	boss_hp_changed.emit(_current_boss, _boss_hp, _max_hp())


## Carrega uma fase de Aurius.
func _load_aurius_phase(phase_index: int) -> void:
	if phase_index >= AURIUS.phases.size():
		return
	_current_phase = phase_index
	var phase = AURIUS.phases[phase_index]
	_boss_hp = phase.hp
	_part_hp.clear()
	_spell_counters.clear()
	for part in phase.parts:
		_part_hp[part.name] = part.hp
	for spell in phase.spells:
		_spell_counters[spell.name] = spell.charge_turns
	boss_phase_changed.emit("Aurius", phase_index + 1)


## Retorna os dados do boss cardinal.
func get_cardinal_data(cardinal_name: String) -> Dictionary:
	return CARDINALS.get(cardinal_name, {})


## Retorna os dados da fase atual de Aurius.
func get_aurius_phase_data() -> Dictionary:
	if _current_boss != "Aurius":
		return {}
	if _current_phase >= AURIUS.phases.size():
		return {}
	return AURIUS.phases[_current_phase]


## Retorna o HP atual do boss.
func get_boss_hp() -> int:
	return _boss_hp


## Retorna o HP de uma parte quebrável.
func get_part_hp(part_name: String) -> int:
	return _part_hp.get(part_name, 0)


## Aplica dano a uma parte quebrável.
## Retorna true se a parte foi quebrada.
func damage_part(part_name: String, damage: int) -> bool:
	if not _part_hp.has(part_name):
		return false
	_part_hp[part_name] = maxi(0, _part_hp[part_name] - damage)
	if _part_hp[part_name] <= 0:
		boss_part_broken.emit(_current_boss, part_name)
		return true
	return false


## Aplica dano direto ao boss (ignorando partes).
func damage_boss(damage: int) -> void:
	_boss_hp = maxi(0, _boss_hp - damage)
	boss_hp_changed.emit(_current_boss, _boss_hp, _max_hp())
	if _boss_hp <= 0:
		if _current_boss == "Aurius" and _current_phase < AURIUS.phases.size() - 1:
			## Aurius avança para próxima fase
			_load_aurius_phase(_current_phase + 1)
		else:
			boss_defeated.emit(_current_boss)


func _max_hp() -> int:
	var data := CARDINALS.get(_current_boss)
	if data:
		return data.hp
	if _current_boss == "Aurius":
		return AURIUS.phases[0].hp
	return 0


## Decrementa counters de magias (chamado no início do turno do boss).
## Retorna array de magias que terminaram o charge.
func tick_spell_counters() -> Array:
	var casted_spells: Array = []
	for spell_name in _spell_counters:
		_spell_counters[spell_name] -= 1
		if _spell_counters[spell_name] <= 0:
			casted_spells.append(spell_name)
			boss_spell_charging.emit(_current_boss, spell_name, 0)
	return casted_spells


## Retorna os locks restantes de uma magia.
func get_spell_locks(spell_name: String) -> Array:
	var boss_data = _get_current_boss_spells()
	for spell in boss_data:
		if spell.name == spell_name:
			return spell.locks.duplicate()
	return []


## Retorna as magias do boss atual.
func _get_current_boss_spells() -> Array:
	if _current_boss == "Aurius":
		return get_aurius_phase_data().get("spells", [])
	return CARDINALS.get(_current_boss, {}).get("spells", [])


## Retorna as partes quebráveis do boss atual.
func get_current_parts() -> Array:
	if _current_boss == "Aurius":
		return get_aurius_phase_data().get("parts", [])
	return CARDINALS.get(_current_boss, {}).get("parts", [])


## Retorna o nome do boss atual.
func get_current_boss_name() -> String:
	return _current_boss


## Retorna a fase atual (1-based para UI).
func get_current_phase() -> int:
	return _current_phase + 1


## Retorna se o boss está ativo (tem HP > 0).
func is_boss_active() -> bool:
	return _boss_hp > 0


## Retorna a lista de todos os cardinais.
func get_all_cardinals() -> Array:
	return CARDINALS.keys()
