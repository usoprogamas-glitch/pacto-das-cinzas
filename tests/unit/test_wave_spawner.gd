extends "res://addons/gut/test.gd"

## Ondas escaladas (GDD §1 Ato III, decisão ROADMAP #7): BattleManager reinjeta
## inimigos com stats escalados por onda em vez de encerrar a batalha;
## battle_won só dispara após a última onda.

var bm: Node


func before_each() -> void:
	bm = BattleManager
	bm.wave_config = []
	bm.current_wave = 0
	bm.grid.clear()
	bm.player_units.clear()
	bm.enemy_units.clear()
	bm.all_units.clear()
	bm.initialize_grid()


func after_each() -> void:
	bm.wave_config = []
	bm.current_wave = 0


func _make_player(grid_pos: Vector2i) -> Unit:
	var u := Unit.new()
	var d := UnitData.new()
	d.unit_name = "Kael"
	d.is_player = true
	d.max_hp = 80
	u.data = d
	u.current_hp = 80
	u.grid_position = grid_pos
	bm.register_unit(u)
	return u


func _make_enemy(grid_pos: Vector2i, hp: int = 50) -> Unit:
	var u := Unit.new()
	var d := UnitData.new()
	d.unit_name = "Mercenário"
	d.is_player = false
	d.max_hp = hp
	d.attack = 10
	d.defense = 5
	d.speed = 8
	u.data = d
	u.current_hp = hp
	u.grid_position = grid_pos
	bm.register_unit(u)
	return u


func test_no_waves_config_battle_ends_immediately():
	var won := {"v": false}
	bm.battle_won.connect(func(): won["v"] = true)
	var _p := _make_player(Vector2i(0, 0))
	var _e := _make_enemy(Vector2i(10, 5))
	bm.unregister_unit(_e)
	bm.check_battle_end()
	assert_true(won["v"], "sem config de ondas: inimigos zerados = vitória")


func test_pending_wave_reinjects_enemies_instead_of_victory():
	var won := {"v": false}
	bm.battle_won.connect(func(): won["v"] = true)
	var waves := {"started": []}
	bm.wave_started.connect(func(i, total): waves["started"].append([i, total]))
	bm.setup_waves([
		{"enemies": [{"unit_name": "Mercenário", "hp": 50, "atk": 10, "def": 5, "spd": 8}], "stat_scale": 1.0},
		{"enemies": [{"unit_name": "Paladino", "hp": 80, "atk": 12, "def": 8, "spd": 6}], "stat_scale": 1.5},
	])
	var _p := _make_player(Vector2i(0, 0))
	var _e := _make_enemy(Vector2i(10, 5))
	bm.unregister_unit(_e)
	bm.check_battle_end()
	assert_false(won["v"], "não vence com onda pendente")
	assert_eq(waves["started"].size(), 1, "sinal wave_started emitido (onda 2/2)")
	assert_eq(waves["started"][0][0], 1, "índice da onda reinjetada")
	assert_eq(waves["started"][0][1], 2, "total de ondas no payload")
	assert_eq(bm.enemy_units.size(), 1, "inimigo da onda 2 em cena")


func test_wave_units_scale_stats_by_stat_scale():
	bm.setup_waves([
		{"enemies": [{"unit_name": "A", "hp": 50, "atk": 10, "def": 5, "spd": 8}], "stat_scale": 1.0},
		{"enemies": [{"unit_name": "B", "hp": 80, "atk": 12, "def": 8, "spd": 6}], "stat_scale": 2.0},
	])
	var _p := _make_player(Vector2i(0, 0))
	var _e := _make_enemy(Vector2i(10, 5))
	bm.unregister_unit(_e)
	bm.check_battle_end()
	var foe: Unit = bm.enemy_units[0]
	assert_eq(foe.data.unit_name, "B", "unidade da onda 2")
	assert_eq(foe.data.max_hp, 160, "HP escalado por 2.0")
	assert_eq(foe.data.attack, 24, "ATK escalado por 2.0")
	assert_eq(foe.data.defense, 16, "DEF escalada")
	assert_eq(foe.current_hp, 160, "vida cheia ao entrar")


func test_last_wave_clear_emits_battle_won():
	var won := {"v": false}
	bm.battle_won.connect(func(): won["v"] = true)
	bm.setup_waves([
		{"enemies": [{"unit_name": "A", "hp": 50, "atk": 10}], "stat_scale": 1.0},
		{"enemies": [{"unit_name": "B", "hp": 80, "atk": 12}], "stat_scale": 1.5},
	])
	var _p := _make_player(Vector2i(0, 0))
	var _e := _make_enemy(Vector2i(10, 5))
	bm.unregister_unit(_e)
	bm.check_battle_end()  # reinjeta onda 2
	var _e2: Unit = bm.enemy_units[0]
	bm.unregister_unit(_e2)
	bm.check_battle_end()  # última onda limpa
	assert_true(won["v"], "vitória só após a última onda")
	assert_false(bm.has_pending_waves(), "sem ondas pendentes")


func test_factory_is_used_when_provided():
	var calls := {"n": 0}
	bm.setup_waves([
		{"enemies": [{"unit_name": "A", "hp": 50, "atk": 10}], "stat_scale": 1.0},
		{"enemies": [{"unit_name": "Orc da Onda", "hp": 90, "atk": 14, "def": 6, "spd": 7}], "stat_scale": 1.5},
	])
	var _p := _make_player(Vector2i(0, 0))
	var _e := _make_enemy(Vector2i(10, 5))
	var factory := func(spec, scale):
		calls["n"] += 1
		var u := Unit.new()
		var d := UnitData.new()
		d.unit_name = "ORQUESTRADO:%s" % String(spec.get("unit_name", "?"))
		d.is_player = false
		d.max_hp = int(float(spec.get("hp", 50)) * scale)
		u.data = d
		u.current_hp = d.max_hp
		return u
	var _e2 := _make_enemy(Vector2i(10, 6))
	bm.unregister_unit(_e)
	bm.unregister_unit(_e2)
	bm.spawn_next_wave(factory)
	assert_eq(int(calls["n"]), 1, "factory chamada para cada spec")
	assert_eq(bm.enemy_units[0].data.unit_name, "ORQUESTRADO:Orc da Onda", "factory dona da Unit (sprites/HP bars do battle_scene)")


func test_spawn_positions_are_valid_and_free():
	bm.setup_waves([
		{"enemies": [{"unit_name": "A", "hp": 50, "atk": 10}], "stat_scale": 1.0},
		{"enemies": [
			{"unit_name": "B1", "hp": 60, "atk": 10},
			{"unit_name": "B2", "hp": 60, "atk": 10},
			{"unit_name": "B3", "hp": 60, "atk": 10},
			{"unit_name": "B4", "hp": 60, "atk": 10}
		], "stat_scale": 1.5},
	])
	var _p := _make_player(Vector2i(0, 0))
	var _e := _make_enemy(Vector2i(10, 5))
	bm.unregister_unit(_e)
	var spawned: Array = bm.spawn_next_wave()
	assert_eq(spawned.size(), 4, "todos os specs da onda spawnam")
	var seen := {}
	for u in spawned:
		var p: Vector2i = u.grid_position
		assert_true(bm.is_valid_position(p), "posição no grid")
		assert_true(p.x >= bm.grid_size.x / 2, "spawna no lado inimigo (metade direita)")
		assert_false(seen.has(p), "sem colisão de posição")
		seen[p] = true


func test_spawn_next_wave_without_pending_is_noop():
	assert_eq(bm.spawn_next_wave().size(), 0, "sem config: noop")
	bm.setup_waves([{"enemies": [{"unit_name": "A", "hp": 50, "atk": 10}], "stat_scale": 1.0}])
	assert_eq(bm.spawn_next_wave().size(), 0, "na última onda: noop")
