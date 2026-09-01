extends "res://addons/gut/test.gd"

## Testes GUT: IA inimiga caster lança magia de verdade via MagicSystem
## (GDD v2 §3.3). Valida a decisão do EnemyAI.caster_ai (escolhe spell, respeita
## MP/alcance) e a execução no BattleManager (cast_magic: desconta MP, dá dano,
## emite unit_attacked para a UI reagir).

var bm: Node


func before_each():
	# BattleManager é autoload; para teste isolado instanciamos o script direto.
	var BM = load("res://scripts/BattleManager.gd")
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
	# water_splash: spell SEM locks → caminho imediato (GDD §3.2 só afeta
	# spells que declaram locks, como fire_bolt/shadow_bolt).
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "water_splash"})
	var player := _make_unit(true, {"hp": 80})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)

	var before_hp = player.current_hp
	bm.cast_magic(enemy, "water_splash", player)
	assert_eq(enemy.current_mp, 32, "cast imediato desconta mp_cost (8)")
	assert_lt(player.current_hp, before_hp, "alvo toma dano")


func test_execute_enemy_ai_emits_unit_attacked_on_cast():
	# fire_bolt agora é spell ANUNCIADO (locks, GDD §3.2): o turno é gasto
	# conjurando — sem dano, sem MP ainda. Cast resolve no contador zero.
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "fire_bolt"})
	enemy.data.unit_name = "Inquisidor"  # IA caster (get_ai_type pelo nome)
	var player := _make_unit(true, {"hp": 80})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)

	watch_signals(bm)
	await bm.execute_enemy_ai(enemy)
	assert_eq(enemy.current_mp, 40, "MP intacto durante o canal do cast")
	assert_signal_not_emitted(bm, "unit_attacked", "anúncio não causa dano")
	var locks: Array = bm.lock_system.get_locks(enemy)
	assert_eq(locks.size(), 1, "locks nascem do cast da IA (GDD §3.2)")
	assert_eq(bm.lock_system.get_pending_spell(enemy)["turns_remaining"], 2, "fire_bolt carrega 2 turnos")


func test_execute_enemy_ai_cast_resolves_after_channel():
	# Canal completo: turno 1 anuncia (IA decide cast), turnos 2-3 consomem os
	# cast_turns ticks → cast resolve com dano + MP (GDD §3.2).
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "fire_bolt"})
	enemy.data.unit_name = "Inquisidor"  # IA caster (get_ai_type pelo nome)
	var player := _make_unit(true, {"hp": 80})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)

	await bm.execute_enemy_ai(enemy)  # anuncia (locks nascem)
	assert_eq(bm.lock_system.get_pending_spell(enemy)["turns_remaining"], 2, "fire_bolt carrega 2 turnos")
	watch_signals(bm)
	await bm.execute_enemy_ai(enemy)  # tick 1 (canal)
	await bm.execute_enemy_ai(enemy)  # tick 2 → cast resolve
	assert_eq(enemy.current_mp, 30, "MP gasto só quando o cast resolve (10)")
	assert_signal_emitted(bm, "unit_attacked", "cast resolvido emite unit_attacked")
	assert_eq(bm.lock_system.get_pending_spell(enemy), {}, "cast consumido")


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


func test_cast_magic_kill_resolves_death_and_battle():
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "water_splash"})
	var player := _make_unit(true, {"hp": 1})
	player.grid_position = Vector2i(2, 4)
	bm.register_unit(enemy)
	bm.register_unit(player)
	bm.soul_ether = 0

	watch_signals(bm)
	bm.cast_magic(enemy, "water_splash", player)
	assert_eq(player.current_hp, 0, "spell mata o jogador (hp 1)")
	assert_signal_emitted(bm, "unit_died", "morte por magia emite unit_died")
	assert_eq(bm.player_units.size(), 0, "morto sai das listas de combate")
	assert_eq(bm.get_tile_at(Vector2i(2, 4)), null, "tile do morto fica vazio")
	assert_signal_emitted(bm, "battle_lost", "sem player units -> battle_lost")
	assert_eq(bm.soul_ether, 10, "alma do morto é ganha mesmo sendo player (default 10), igual ao ataque físico")


func test_cast_magic_kill_of_enemy_emits_soul_ether_and_victory():
	var enemy := _make_unit(false, {"magic": 25, "mp": 40, "spell": "water_splash"})
	var last_player := _make_unit(true, {"hp": 1})
	var target := _make_unit(false, {"hp": 1})
	target.data.soul_ether_value = 30
	last_player.grid_position = Vector2i(2, 4)
	target.grid_position = Vector2i(2, 5)
	bm.register_unit(enemy)       # inimigo (caster) — sobrevive
	bm.register_unit(last_player)
	bm.register_unit(target)      # inimigo auxiliar morto pelo cast
	bm.soul_ether = 0

	watch_signals(bm)
	bm.cast_magic(enemy, "water_splash", target)
	assert_eq(target.current_hp, 0, "inimigo morto pelo cast")
	assert_signal_emitted(bm, "unit_died", "morte por magia de inimigo emite unit_died")
	assert_eq(bm.enemy_units.size(), 1, "somente o caster continua inimigo")
	assert_eq(bm.get_tile_at(Vector2i(2, 5)), null, "tile do morto vazio")
	assert_signal_not_emitted(bm, "battle_lost", "ainda ha player vivo")
	assert_eq(bm.soul_ether, 30, "alma do inimigo derrotado é ganha")