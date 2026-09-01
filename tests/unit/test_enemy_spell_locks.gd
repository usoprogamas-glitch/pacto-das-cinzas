extends "res://addons/gut/test.gd"

## Locks do cast inimigo (GDD §3.2, AUDIT P1 #10): inimigo canaliza feitiço —
## locks aparecem; golpe do jogador com o tipo certo dentes; quebrar todos =
## spellbreak (stun). Contador zerado = feitiço sai. Núcleo puro + dados.

const ArenaCombatLib := preload("res://scripts/arena_combat.gd")


func _make_unit(name: String, side: bool, hp: int = 50) -> Unit:
	var u := Unit.new()
	var d := UnitData.new()
	d.unit_name = name
	d.is_player = side
	d.max_hp = hp
	d.attack = 12
	d.defense = 8
	u.data = d
	u.current_hp = hp
	return u


func _spec() -> Dictionary:
	return {"name": "Corrente Rúnica", "damage": 14, "charge_turns": 2, "locks": [{"type": "Corte", "hits": 2}]}


func test_enemy_spell_data_driven():
	var inquisidor: Dictionary = EnemyDatabase.get_enemy("inquisidor")
	assert_true(inquisidor.has("enemy_spell"), "inquisidor declara enemy_spell")
	assert_gt(inquisidor["enemy_spell"]["locks"].size(), 0, "spell declara locks")
	var mercenario: Dictionary = EnemyDatabase.get_enemy("mercenario")
	assert_false(mercenario.has("enemy_spell"), "não-caster não declara spell")
	var bosses := ["santo_cardeal", "cardeal_ignis", "cardeal_zephyr", "cardeal_aqua", "cardeal_terra", "cardeal_umbra", "aurius_fase1", "aurius_fase2", "aurius_fase3"]
	for b in bosses:
		assert_true(EnemyDatabase.get_enemy(b).has("enemy_spell"), "boss %s declara enemy_spell" % b)


func test_start_charge_creates_locks():
	var combat := ArenaCombatLib.new()
	var foe := _make_unit("Inquisidor", false)
	var charge: Dictionary = combat.start_charge(foe, _spec())
	assert_eq(charge["turns_left"], 2, "charge começa com contador cheio")
	assert_eq(charge["locks"].size(), 1, "lock criado")
	assert_eq(charge["locks"][0]["remaining"], 2, "lock com hits declarados")
	assert_true(combat.is_charging(foe), "inimigo canalizando")
	assert_eq(combat.get_charge(foe)["spell_name"], "Corrente Rúnica")


func test_player_hit_consumes_matching_lock():
	var combat := ArenaCombatLib.new()
	var foe := _make_unit("Inquisidor", false)
	combat.start_charge(foe, _spec())
	var r: Dictionary = combat.hit_charge(foe, ArenaCombatLib.PLAYER_PHYSICAL_TYPE)
	assert_true(r["hit"], "Corte dente o lock de Corte")
	assert_false(r["interrupted"], "ainda falta um hit")
	assert_eq(combat.get_charge(foe)["locks"][0]["remaining"], 1, "lock consumido")


func test_wrong_type_does_not_touch_lock():
	var combat := ArenaCombatLib.new()
	var foe := _make_unit("Inquisidor", false)
	combat.start_charge(foe, _spec())
	var r: Dictionary = combat.hit_charge(foe, ArenaCombatLib.PLAYER_MAGIC_TYPE)
	assert_false(r["hit"], "Éter não dente lock de Corte")
	assert_eq(combat.get_charge(foe)["locks"][0]["remaining"], 2, "lock intacto")


func test_breaking_all_locks_interrupts_and_stuns():
	var combat := ArenaCombatLib.new()
	var foe := _make_unit("Inquisidor", false)
	combat.start_charge(foe, _spec())
	combat.hit_charge(foe, ArenaCombatLib.PLAYER_PHYSICAL_TYPE)
	var r: Dictionary = combat.hit_charge(foe, ArenaCombatLib.PLAYER_PHYSICAL_TYPE)
	assert_true(r["interrupted"], "spellbreak ao quebrar todos")
	assert_false(combat.is_charging(foe), "charge limpo")
	assert_true(combat.tick_stun(foe), "inimigo atordoado perde o turno")
	assert_false(combat.tick_stun(foe), "stun de 1 turno só")


func test_charge_tick_casts_when_counter_expires():
	var combat := ArenaCombatLib.new()
	var foe := _make_unit("Inquisidor", false)
	combat.start_charge(foe, _spec())
	assert_eq(combat.tick_charge(foe), "charging", "primeiro tick continua canalizando")
	assert_eq(combat.tick_charge(foe), "casting", "contador zerado: feitiço sai")
	assert_false(combat.is_charging(foe), "estado limpo após o cast")


func test_charge_tick_without_charge_is_noop():
	var combat := ArenaCombatLib.new()
	var foe := _make_unit("Inquisidor", false)
	assert_eq(combat.tick_charge(foe), "", "sem canal não há tick")
	assert_false(combat.tick_stun(foe), "sem stun não há consumo")


func test_multi_lock_requires_all_types():
	var combat := ArenaCombatLib.new()
	var foe := _make_unit("Santo Cardeal", false)
	combat.start_charge(foe, {"name": "Julgamento Solar", "damage": 24, "charge_turns": 3, "locks": [{"type": "Éter", "hits": 1}, {"type": "Corte", "hits": 1}]})
	assert_false(combat.hit_charge(foe, ArenaCombatLib.PLAYER_MAGIC_TYPE)["interrupted"], "só Éter não quebra")
	assert_true(combat.hit_charge(foe, ArenaCombatLib.PLAYER_PHYSICAL_TYPE)["interrupted"], "Éter + Corte quebram")
	assert_true(combat.tick_stun(foe), "stun aplicado no spellbreak")
