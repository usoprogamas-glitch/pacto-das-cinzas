extends "res://addons/gut/test.gd"

## Locks nascem do cast inimigo (GDD v2 §3.2, simetria — AUDIT P1 #10):
## caster anuncia spell com locks → locks vivem nele; jogador quebra com o
## tipo de dano certo → cast interrompido + stun; contador zera com locks
## vivos → spell dispara no jogador mais próximo.

var bm: Node


func before_each() -> void:
	bm = BattleManager
	bm.wave_config = []
	bm.current_wave = 0
	bm._stunned.clear()
	bm.grid.clear()
	bm.player_units.clear()
	bm.enemy_units.clear()
	bm.all_units.clear()
	bm.lock_system.clear_all()
	bm.initialize_grid()


func after_each() -> void:
	bm.wave_config = []
	bm.current_wave = 0
	bm._stunned.clear()
	bm.lock_system.clear_all()


func _make_unit(unit_name: String, is_player: bool, grid_pos: Vector2i, hp: int = 80, attack_type: String = "Corte") -> Unit:
	var u := Unit.new()
	var d := UnitData.new()
	d.unit_name = unit_name
	d.is_player = is_player
	d.max_hp = hp
	d.attack = 10
	d.defense = 5
	d.speed = 8
	d.attack_type = attack_type
	d.max_mp = 50
	u.data = d
	u.current_hp = hp
	u.current_mp = 50
	u.grid_position = grid_pos
	bm.register_unit(u)
	return u


func _make_caster(grid_pos: Vector2i) -> Unit:
	var u := _make_unit("Inquisidor", false, grid_pos)
	u.data.spell = "shadow_bolt"
	u.data.magic = 10
	return u


func test_cast_with_locks_announces_instead_of_damaging():
	var caster := _make_caster(Vector2i(8, 5))
	var kael := _make_unit("Kael", true, Vector2i(2, 5))
	var hp_before: int = kael.current_hp
	var started := {"count": 0}
	bm.lock_system.enemy_cast_started.connect(func(_e, _s, _l, _t): started["count"] += 1)

	bm.cast_magic(caster, "shadow_bolt", kael)

	assert_eq(started["count"], 1, "cast anunciado")
	assert_eq(kael.current_hp, hp_before, "dano NÃO acontece no anúncio")
	assert_eq(caster.current_mp, 50, "MP só gasta quando o cast resolve")
	var locks: Array = bm.lock_system.get_locks(caster)
	assert_eq(locks.size(), 1, "lock nasceu no caster")
	assert_eq(locks[0]["type"], "Perfuração", "lock do shadow_bolt é Perfuração")
	assert_eq(locks[0]["remaining"], 2, "2 hits para quebrar")
	assert_eq(bm.lock_system.get_pending_spell(caster)["turns_remaining"], 2, "cast carrega 2 turnos")


func test_spell_without_locks_casts_immediately():
	var caster := _make_caster(Vector2i(8, 5))
	var kael := _make_unit("Kael", true, Vector2i(2, 5))
	var hp_before: int = kael.current_hp

	bm.cast_magic(caster, "water_splash", kael)  # sem locks declarados

	assert_lt(kael.current_hp, hp_before, "spell sem locks dispara direto")
	assert_lt(caster.current_mp, 50, "MP gasto no cast imediato")


func test_player_hit_reduces_lock_with_matching_type():
	var caster := _make_caster(Vector2i(8, 5))
	var _kael := _make_unit("Kael", true, Vector2i(2, 5))
	bm.cast_magic(caster, "shadow_bolt", bm.player_units[0])
	var kroug := _make_unit("Kroug", true, Vector2i(2, 4), 120, "Perfuração")

	bm.attack_unit(kroug, caster)

	var locks: Array = bm.lock_system.get_locks(caster)
	assert_eq(locks[0]["remaining"], 1, "golpe Perfuração reduz o lock")


func test_wrong_attack_type_does_not_break_lock():
	var caster := _make_caster(Vector2i(8, 5))
	var _kael := _make_unit("Kael", true, Vector2i(2, 5))
	bm.cast_magic(caster, "shadow_bolt", bm.player_units[0])
	var brute := _make_unit("Bruto", true, Vector2i(2, 4), 120, "Contusão")

	bm.attack_unit(brute, caster)

	var locks: Array = bm.lock_system.get_locks(caster)
	assert_eq(locks[0]["remaining"], 2, "tipo errado não reduz o lock")


func test_breaking_all_locks_interrupts_cast_and_stuns():
	var caster := _make_caster(Vector2i(8, 5))
	var _kael := _make_unit("Kael", true, Vector2i(2, 5))
	bm.cast_magic(caster, "shadow_bolt", bm.player_units[0])
	var lancer := _make_unit("Lanceiro", true, Vector2i(2, 4), 120, "Perfuração")
	var stunned := {"count": 0}
	bm.enemy_stunned.connect(func(_e): stunned["count"] += 1)

	bm.attack_unit(lancer, caster)
	assert_eq(stunned["count"], 0, "1 lock quebrado ainda não atordoa")
	bm.attack_unit(lancer, caster)
	assert_eq(stunned["count"], 1, "todos os locks quebrados → stun")
	assert_true(bm._stunned.has(caster), "caster no registro de stun")
	assert_eq(bm.lock_system.get_pending_spell(caster), {}, "cast interrompido")
	assert_eq(bm.lock_system.get_locks(caster), [], "locks limpos após spellbreak")


func test_stunned_caster_skips_turn_and_recovers():
	var caster := _make_caster(Vector2i(8, 5))
	var kael := _make_unit("Kael", true, Vector2i(2, 5))
	caster.data.magic = 10
	bm._stunned[caster] = bm.lock_system.STUN_DURATION  # spellbreak aplicado
	var hp_before: int = kael.current_hp

	bm.execute_enemy_ai(caster)

	assert_eq(kael.current_hp, hp_before, "stun consome o turno (nada acontece)")
	assert_eq(bm._stunned[caster], 0, "stun decrementou para 0 (expira no próximo turno)")


func test_cast_resolves_when_counter_hits_zero_with_locks_alive():
	var caster := _make_caster(Vector2i(8, 5))
	var kael := _make_unit("Kael", true, Vector2i(2, 5))
	bm.cast_magic(caster, "shadow_bolt", kael)
	var hp_before: int = kael.current_hp

	assert_true(bm.tick_enemy_spell(caster), "turno 1: gasto no canal")
	assert_eq(kael.current_hp, hp_before, "ainda carregando")
	assert_true(bm.tick_enemy_spell(caster), "turno 2: cast resolve")
	assert_lt(kael.current_hp, hp_before, "spell dispara no contador zero")
	assert_eq(bm.lock_system.get_pending_spell(caster), {}, "cast consumido")


func test_caster_death_cancels_pending_cast():
	var caster := _make_caster(Vector2i(8, 5))
	var _kael := _make_unit("Kael", true, Vector2i(2, 5))
	bm.cast_magic(caster, "shadow_bolt", bm.player_units[0])
	var lancer := _make_unit("Lanceiro", true, Vector2i(2, 4), 120, "Perfuração")
	caster.current_hp = 1
	lancer.data.attack = 50

	bm.attack_unit(lancer, caster)  # mata o caster

	assert_eq(bm.lock_system.get_pending_spell(caster), {}, "cast morre com o conjurador")
	assert_eq(bm.lock_system.get_locks(caster), [], "locks morrem com o conjurador")


func test_tick_without_pending_spell_is_noop():
	var caster := _make_caster(Vector2i(8, 5))
	assert_false(bm.tick_enemy_spell(caster), "sem cast anunciado: tick é noop, turno segue normal")
