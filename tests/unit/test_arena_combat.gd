extends "res://addons/gut/test.gd"

## Núcleo de combate arena (molde Sea of Stars, opção 3): ordem por agilidade,
## dano/magia, IA de foco e condição de fim — tudo puro, sem cena.

var arena: ArenaCombat


func before_each() -> void:
	arena = ArenaCombat.new()


func _make(name: String, is_player: bool, hp: int, atk: int, def: int, spd: int) -> Unit:
	var u := Unit.new()
	var d := UnitData.new()
	d.unit_name = name
	d.is_player = is_player
	d.max_hp = hp
	d.current_hp = hp
	d.attack = atk
	d.defense = def
	d.speed = spd
	u.data = d
	u.current_hp = hp
	return u


func test_turn_order_follows_agility():
	var slow := _make("Bruto", false, 50, 10, 5, 5)
	var fast := _make("Kael", true, 80, 12, 8, 11)
	var order: Array = arena.build_turn_order([slow, fast])
	assert_eq(order[0], fast, "mais ágil age primeiro (SoS §5.1)")
	assert_eq(order[1], slow)


func test_damage_respects_defense_floor():
	var a := _make("Kael", true, 80, 20, 0, 10)
	var t := _make("Bruto", false, 100, 5, 15, 5)
	seed(42)
	var dmg: int = arena.calculate_damage(a, t)
	assert_between(dmg, 1, int((20 - 15) * 1.15), "dano = (atk - def) ±15%, mínimo 1")


func test_damage_minimum_is_one():
	var weak := _make("Fraco", true, 50, 2, 0, 10)
	var tank := _make("Muralha", false, 500, 0, 50, 5)
	seed(42)
	assert_eq(arena.calculate_damage(weak, tank), 1, "defesa altíssima não zera o dano")


func test_magic_costs_mp_and_pierces_defense():
	var mage := _make("Kael", true, 80, 20, 0, 10)
	mage.current_mp = 50
	var tank := _make("Muralha", false, 500, 0, 50, 5)
	var before := mage.current_mp
	var cast: Dictionary = arena.cast_damage_spell(mage, tank)
	assert_true(cast.success, "MP suficiente = cast bem-sucedido")
	assert_eq(mage.current_mp, before - ArenaCombat.MAGIC_COST, "custo descontado")
	assert_gt(cast.damage, 1, "magia perfura a defesa (dano > floor)")


func test_magic_fails_without_mp():
	var mage := _make("Kael", true, 80, 20, 0, 10)
	mage.current_mp = 0
	var t := _make("Bruto", false, 100, 5, 5, 5)
	var cast: Dictionary = arena.cast_damage_spell(mage, t)
	assert_false(cast.success, "sem MP = falha")
	assert_eq(mage.current_mp, 0, "MP não fica negativo")


func test_apply_hit_clamps_at_zero():
	var a := _make("Kael", true, 80, 99, 0, 10)
	var t := _make("Bruto", false, 10, 5, 0, 5)
	seed(42)
	arena.apply_hit(a, t, 999)
	assert_eq(t.current_hp, 0, "HP não fica negativo")
	assert_false(t.is_alive(), "HP 0 = morto")


func test_enemy_ai_focuses_lowest_hp_player():
	var full := _make("Kroug", true, 120, 10, 15, 8)
	var hurt := _make("Kael", true, 80, 12, 8, 11)
	hurt.current_hp = 20
	assert_eq(arena.choose_enemy_target([full, hurt]), hurt, "IA foca o jogador de menor HP")


func test_enemy_ai_returns_null_when_no_players():
	var foe := _make("Bruto", false, 50, 10, 5, 5)
	assert_null(arena.choose_enemy_target([foe]), "sem jogadores vivos = sem alvo")


func test_battle_over_conditions():
	var kael := _make("Kael", true, 80, 12, 8, 11)
	var foe := _make("Bruto", false, 50, 10, 5, 5)
	assert_eq(arena.is_battle_over([kael, foe]), "", "ambos vivos = batalha continua")
	foe.current_hp = 0
	assert_eq(arena.is_battle_over([kael, foe]), "victory", "inimigos mortos = vitória")
	kael.current_hp = 0
	assert_eq(arena.is_battle_over([kael, foe]), "defeat", "todos mortos = derrota")


func test_battle_over_ignores_dead_units():
	var kael := _make("Kael", true, 80, 12, 8, 11)
	var dead := _make("Cadáver", false, 0, 10, 5, 5)
	assert_eq(arena.is_battle_over([kael, dead]), "victory", "só mortos de um lado = fim")
