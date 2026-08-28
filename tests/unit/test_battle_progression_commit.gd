extends "res://addons/gut/test.gd"
## Testes GUT: _commit_progression() do battle_scene
## Valida que o progresso ganho EM BATALHA (sistema local da cena) é transferido
## para o GameManager.progression_system PERSISTENTE ao vencer — o bug #fix onde
## os ganhos (XP/memória/almas) se perdiam ao sair da batalha.

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node
var _before: Dictionary

func before_each() -> void:
	bs = BattleSceneScript.new()
	bs.progression_system = preload("res://scripts/narrative/progression_system.gd").new()
	# Simular acumulado de batalha: derrotar inimigos dá memória/XP/almas
	bs.progression_system.add_memory(10)
	bs.progression_system.add_experience(25)
	bs.progression_system.add_named_soul()
	# Estado base do GM persistente (para medir delta)
	_before = GameManager.progression_system.serialize()

func after_each() -> void:
	if is_instance_valid(bs):
		bs.free()

func test_commit_transfers_accumulated_progress_to_game_manager():
	bs._commit_progression()
	var gm_prog = GameManager.progression_system
	assert_eq(gm_prog.total_memory, _before["total_memory"] + 10, "memória da batalha persistida")
	assert_eq(gm_prog.total_experience, _before["total_experience"] + 25, "XP da batalha persistida")
	assert_eq(gm_prog.named_souls, _before["named_souls"] + 1, "alma nomeada persistida")

func test_commit_is_noop_when_no_local_system():
	bs.progression_system = null
	# Não deve crashar nem alterar o GM
	bs._commit_progression()
	assert_eq(GameManager.progression_system.total_memory, _before["total_memory"], "sem sistema local não muda nada")

func test_commit_does_not_duplicate_on_idempotent_system_reset():
	# Se a cena já commitou, os valores foram zerados/resetados — garantir que um
	# sistema local vazio não injeta lixo (0 adições, deltas positivos apenas).
	var empty = preload("res://scripts/narrative/progression_system.gd").new()
	bs.progression_system = empty
	bs._commit_progression()
	assert_eq(GameManager.progression_system.total_memory, _before["total_memory"], "progression vazia = nenhum ganho")
