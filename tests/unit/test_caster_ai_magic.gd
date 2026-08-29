extends "res://addons/gut/test.gd"

## Testes GUT: IA inimiga caster lança magia de verdade via MagicSystem
## (GDD v2 §3.3). Valida a decisão do EnemyAI.caster_ai (escolhe spell, respeita
## MP/alcance) e a execução no BattleManager (cast_magic: desconta MP, dá dano,
## emite unit_attacked para a UI reagir).

var bm: Node


func before_each():
	# BattleManager é autoload; para teste isolado instanciamos o script direto.
	var BM = load("res://scripts/battle/BattleManager.gd")
	bm = BM.new()
	add_child_autofree(bm)


func _make_unit(player_side: bool, config: Dictionary = {}) -> Unit:
	var hp: int = config.get("hp", 80)
	var magic: int = config.get("magic", 0)
	var mp: int = config.get("mp", 50)
	var spell: String = config.get("spell", "fire_bolt")
	var data: UnitData = UnitData.new()
	data.speed = config.get("speed", 10)
	data.is_player = player_side
	data.max_hp = hp
	data.current_hp = hp
	data.magic = magic
	data.max_mp = mp
	data.current_mp = mp
	data.spell = spell
	data.unit_class = "Mago"
	data.unit_name = "Inquisidor" if spell == "shadow_bolt" else ("Kael" if player_side else "Mercenário")
	var unit: Unit = Unit.new()
	unit.data = data
	unit.current_hp = hp
	unit.current_mp = mp
	unit.grid_position = Vector2i(2, 2)
	return unit


func test_caster_ai_returns_cast_when_in_range():
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "shadow_bolt"})
	var player := _make_unit(true)
	player.grid_position = Vector2i(2, 4)  # dist 2 <= shadow_bolt range 3
	var action = EnemyAI.caster_ai(enemy, player, [], null)
	assert_eq(action.action, "cast", "caster em alcance com MP casta")
	assert_eq(action.spell_id, "shadow_bolt", "usa o spell configurado")
	assert_eq(action.target, player, "alvo é o jogador")


func test_caster_ai_falls_back_to_fire_bolt():
	var enemy := _make_unit(false, {"magic": 10, "mp": 40, "spell": ""})
	var player := _make_unit(true)
	player.grid_position = Vector2i(2, 4)
	var action = EnemyAI.caster_ai(enemy, player, [], null)
	assert_eq(action.action, "cast", "inherita fire_bolt default")
	assert_eq(action.spell_id, "fire_bolt", "spell vazio -> default fire_bolt")


func test_caster_ai_moves_when_out_of_spell_range():
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "shadow_bolt"})
	var player := _make_unit(true)
	player.grid_position = Vector2i(2, 10)  # dist 8 > shadow_bolt range 3, > attack_range
	var action = EnemyAI.caster_ai(enemy, player, [], null)
	assert_eq(action.action, "move", "fora do alcance -> move (não pode castar)")


func test_caster_ai_attacks_when_mp_insufficient():
	var enemy := _make_unit(false, {"magic": 25, "mp": 5, "spell": "shadow_bolt"})
	var player := _make_unit(true)
	player.grid_position = Vector2i(2, 3)  # dist 1 <= attack_range
	var action = EnemyAI.caster_ai(enemy, player, [], null)
	assert_eq(action.action, "attack", "sem MP -> ataque físico (não desperdiça turno)")


func test_cast_magic_reduces_mp_and_damages_target():
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "fire_bolt"})
	var player := _make_unit(true, {"hp": 80})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)

	var before_hp = player.current_hp
	bm.cast_magic(enemy, "fire_bolt", player)
	assert_eq(enemy.current_mp, 30, "cast desconta mp_cost (10)")
	assert_lt(player.current_hp, before_hp, "alvo toma dano")


func test_execute_enemy_ai_emits_unit_attacked_on_cast():
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "shadow_bolt"})
	var player := _make_unit(true, {"hp": 80})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)

	watch_signals(bm)
	await bm.execute_enemy_ai(enemy)
	assert_eq(enemy.current_mp, 28, "shadow_bolt (cust 12) -> 40-12=28")
	assert_signal_emitted(bm, "unit_attacked", "cast emite unit_attacked p/ feedback")


func test_execute_enemy_ai_no_cast_when_mp_low():
	var enemy := _make_unit(false, {"magic": 25, "mp": 5, "spell": "fire_bolt"})
	var player := _make_unit(true, {"hp": 80})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)

	watch_signals(bm)
	await bm.execute_enemy_ai(enemy)
	assert_eq(enemy.current_mp, 5, "MP intacto (caster_ai não casta sem MP)")


func test_cast_magic_silent_when_not_enough_mp():
	var enemy := _make_unit(false, {"magic": 25, "mp": 5, "spell": "fire_bolt"})
	var player := _make_unit(true, {"hp": 80})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)

	# chamada direta de cast_com MP insuficiente -> guarda no MagicSystem, sem emit
	watch_signals(bm)
	bm.cast_magic(enemy, "fire_bolt", player)
	assert_eq(enemy.current_mp, 5, "cast não consomue MP")
	assert_signal_not_emitted(bm, "unit_attacked", "sem dano emitido sem cast real")