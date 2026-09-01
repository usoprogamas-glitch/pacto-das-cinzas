extends "res://addons/gut/test.gd"

## Ondas escaladas na arena SoS (Ato III, decisão ROADMAP #7): mapa 3 declara
## "waves" data-driven; ao limpar uma onda, a arena reinjeta a próxima com
## stats escalados — battle_ended só após a última onda.

const ArenaScript := preload("res://scripts/arena_battle.gd")

var _arena: Node
var _sig_victory  # null = sinal ainda não disparado
var _sig_count := 0


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 3
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	if _arena and is_instance_valid(_arena):
		_arena.free()
	_arena = null


func _open() -> Node:
	_arena = add_child_autofree(ArenaScript.new())
	return _arena


func _open_frozen() -> Node:
	# Sem loop de turnos: nenhuma IA age durante o teste (estados determinísticos).
	var arena = ArenaScript.new()
	arena.combat_frozen = true
	_arena = add_child_autofree(arena)
	return arena


func _connect_signal(arena: Node) -> void:
	_sig_victory = null
	_sig_count = 0
	arena.battle_ended.connect(_on_ended)


func _on_ended(victory: bool, _rewards: Dictionary) -> void:
	_sig_victory = victory
	_sig_count += 1


func _kill_enemies(arena: Node) -> void:
	for u in arena.combatants:
		if not u.is_player_side():
			u.current_hp = 0


func test_map3_declares_waves_data_driven():
	var waves: Array = MapDatabase.get_map(3).get("waves", [])
	assert_eq(waves.size(), 3, "Castelo Solaris declara 3 ondas")
	assert_true(waves[0].has("stat_scale"), "cada onda declara stat_scale")
	assert_gt(waves[2]["stat_scale"], waves[0]["stat_scale"], "escala cresce por onda")
	assert_eq(MapDatabase.get_map(0).get("waves", []).size(), 0, "mapa sem ondas não declara")


func test_arena_loads_wave_config_from_map():
	var arena := _open_frozen()
	assert_eq(arena._wave_specs.size(), 3, "arena carrega as ondas do mapa")
	assert_eq(arena._wave_index, 1, "onda 1 é o spawn inicial em cena")
	var enemies_in_w1: int = MapDatabase.get_map(3)["waves"][0]["enemies"].size()
	assert_eq(arena.combatants.size() - 2, enemies_in_w1, "composição da onda 1 spawna (não o enemy_count)")


func test_clearing_wave_reinjects_next_scaled_wave():
	var arena := _open_frozen()
	var initial_enemies: int = arena.combatants.size() - 2  # -Kael -Kroug
	_kill_enemies(arena)
	assert_false(arena._check_end(), "vitória pendente: batalha continua")
	assert_eq(arena._wave_index, 2, "onda 2 reinjetada; próxima a reinjetar é a 3")
	var reinforced: int = arena.combatants.size() - 2
	assert_gt(reinforced, initial_enemies, "reforços entraram (2ª onda maior)")
	# Stats escalados: onda 2 tem stat_scale 1.25 (paladino base 85 HP).
	var wave2: Unit = arena.combatants.back()
	assert_true(wave2.data.unit_name.contains("Onda 2"), "reforço identificado por onda")


func test_battle_ends_only_after_last_wave():
	var arena := _open_frozen()
	_connect_signal(arena)
	_kill_enemies(arena)
	arena._check_end()  # reinjeta onda 2
	_kill_enemies(arena)
	arena._check_end()  # reinjeta onda 3 (santo_cardeal)
	_kill_enemies(arena)
	arena._check_end()  # última onda limpa
	assert_eq(_sig_count, 0, "battle_ended espera o resultado ser visto")
	arena._on_result_continue_pressed()
	assert_eq(_sig_count, 1, "battle_ended uma vez (após Continuar)")
	assert_true(bool(_sig_victory), "vitória só após a 3ª onda")
	assert_false(arena.result_visible(), "result screen fechada após Continuar")


func test_wave_reinforcements_enter_with_full_hp_and_scaled_stats():
	var arena := _open_frozen()
	var paladino_base: Dictionary = EnemyDatabase.get_enemy("paladino")
	_kill_enemies(arena)
	arena._check_end()  # reinjeta onda 2 (stat_scale 1.25)
	var scale := 1.25
	var found := false
	for u in arena.combatants:
		if u.data.unit_name.contains("Paladino (Onda 2)"):
			found = true
			assert_eq(u.data.max_hp, int(round(float(paladino_base["hp"]) * scale)), "HP escalado por 1.25")
			assert_eq(u.current_hp, u.data.max_hp, "reforço entra com vida cheia")
			assert_eq(u.data.attack, int(round(float(paladino_base["atk"]) * scale)), "ATK escalado")
	assert_true(found, "paladino da onda 2 em cena")


func test_map_without_waves_ends_immediately():
	GameManager.game_data["current_map"] = 0
	var arena := _open_frozen()
	assert_eq(arena._wave_specs.size(), 0, "mapa 0 sem ondas")
	_kill_enemies(arena)
	arena._check_end()
	assert_true(arena.result_visible(), "batalha única mostra resultado direto")
