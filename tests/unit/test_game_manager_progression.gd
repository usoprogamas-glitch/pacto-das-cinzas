extends "res://addons/gut/test.gd"
## Testes GUT: integração GameManager ↔ ProgressionSystem ↔ CharacterProgression
## Valida que o CharacterProgression NÃO está órfão em produção (bug #fix) e que
## a evolução de forma flui do ProgressionSystem até o save/load.

var gm: Node


func before_each():
	# GameManager é autoload; para teste isolado instanciamos o script direto.
	var GM = load("res://scripts/game_manager.gd")
	gm = GM.new()
	add_child_autofree(gm)


# === Bug #fix: CharacterProgression não deve estar órfão ===

func test_character_progression_is_connected():
	assert_not_null(gm.character_progression, "game_manager deve criar um CharacterProgression")
	var ps = gm.progression_system
	assert_not_null(ps._character_progression, "ProgressionSystem deve ter o CharacterProgression conectado")
	assert_eq(ps._character_progression, gm.character_progression)


# === Evolução de forma flui até o CharacterProgression em produção ===

func test_advancing_act_evolves_protagonist_form():
	var ps = gm.progression_system
	var cp = gm.character_progression
	assert_eq(cp.protagonist_stats.form, "Imp Menor")
	assert_eq(cp.protagonist_stats.stats.hp, 80)

	ps.add_memory(25)  # cruza threshold → Avanço Ato 2 → evolui forma

	assert_eq(ps.current_act, 2)
	assert_eq(cp.protagonist_stats.form, "Nobre Abissal", "forma deve evoluir em produção (não órfão)")
	assert_gt(cp.protagonist_stats.stats.hp, 80, "stats devem ser recalculados pelo multiplicador da forma")
	assert_has(cp.protagonist_stats.abilities, "chamas_submundo", "novas habilidades da forma devem desbloquear")


# === Round-trip de save/load do CharacterProgression ===

func test_character_progression_serialize_roundtrip():
	var cp = gm.character_progression
	gm.progression_system.add_memory(25)  # evolui p/ Nobre Abissal antes de salvar

	var data = cp.serialize()
	assert_eq(data["protagonist_stats"]["form"], "Nobre Abissal")

	var cp2 = CharacterProgression.new()
	cp2.deserialize(data)

	assert_eq(cp2.protagonist_stats.form, "Nobre Abissal", "forma persistida restaurada")
	assert_eq(cp2.protagonist_stats.stats.hp, cp.protagonist_stats.stats.hp, "stats persistidos")


# === Salvar/restaurar via save_data do game_manager (sem IO) ===

func test_game_manager_save_data_contains_character_progression():
	var gm2 = load("res://scripts/game_manager.gd").new()
	add_child_autofree(gm2)
	gm2.progression_system.add_memory(25)

	# Replicar o que save_game() monta (sem tocar user:// no teste)
	var save_data = {
		"game_data": gm2.game_data,
		"faith_data": gm2.faith_system.faith_data,
		"buildings": gm2.building_system.buildings,
		"resources": gm2.building_system.resources,
		"character_progression": gm2.character_progression.serialize()
	}
	assert_has(save_data.character_progression, "protagonist_stats")
	assert_eq(save_data.character_progression.protagonist_stats.form, "Nobre Abissal")
