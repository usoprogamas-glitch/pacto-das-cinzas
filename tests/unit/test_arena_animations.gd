extends "res://addons/gut/test.gd"

## Animações na arena (molde SoS, AUDIT 7d): cada combatente tem um
## UnitAnimator próprio (key por instância), entrada caminhando até a posição,
## lunge/hit/death nos golpes e victory/defeat no encerramento.

const ArenaScript := preload("res://scripts/arena_battle.gd")

var _arena: Node


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	if _arena and is_instance_valid(_arena):
		_arena.free()
	_arena = null


func _open() -> Node:
	_arena = add_child_autofree(ArenaScript.new())
	return _arena


func _open_frozen() -> Node:
	# Abre a arena sem iniciar turnos (IA não age durante o teste).
	var arena = ArenaScript.new()
	arena.combat_frozen = true
	_arena = add_child_autofree(arena)
	return _arena


func test_arena_registers_one_visible_sprite_animator_per_combatant():
	var arena := _open()
	assert_gt(arena.combatants.size(), 1, "party + inimigos na arena")
	var animator_ids := {}
	for u in arena.combatants:
		var a = arena._animator_for(u)
		assert_not_null(a, "animator registrado para %s" % u.data.unit_name)
		assert_not_null(a.sprite, "animator enxerga um sprite")
		assert_true(a.sprite.visible, "sprite VISÍVEL (não o dummy dos @onready)")
		animator_ids[a.get_instance_id()] = true
	assert_eq(animator_ids.size(), arena.combatants.size(), "um animator por unit (sem colisão)")


func test_entrance_snaps_units_to_home_positions():
	var arena := _open()
	arena._finish_entrance()
	for u in arena.combatants:
		assert_eq(u.position, arena._home_positions[u.get_instance_id()], "%s encaixado na posição" % u.data.unit_name)


func test_entrance_walk_delivers_units_to_positions():
	var arena := _open_frozen()
	var player = arena.combatants[0]
	assert_lt(player.position.x, 0.0, "jogadores entram pela esquerda (fora da tela)")
	var foe = null
	for u in arena.combatants:
		if not u.is_player_side():
			foe = u
			break
	assert_gt(foe.position.x, 1280.0, "inimigos entram pela direita (fora da tela)")
	for t in arena._entrance_tweens:
		await t.finished
	assert_eq(player.position, arena._home_positions[player.get_instance_id()], "caminhada entrega o jogador na posição")
	assert_eq(foe.position, arena._home_positions[foe.get_instance_id()], "caminhada entrega o inimigo na posição")


func test_attack_lunge_returns_to_origin_facing_target():
	var arena := _open()
	arena._finish_entrance()
	var attacker = arena.combatants[0]
	var foe = null
	for u in arena.combatants:
		if not u.is_player_side():
			foe = u
			break
	assert_not_null(foe, "inimigo presente")
	var a = arena._animator_for(attacker)
	var origin: Vector2 = attacker.position
	await a.play_attack(foe)
	assert_eq(attacker.position, origin, "lunge volta à origem")
	assert_eq(a.current_animation, "attack", "estado do animator registrado")


func test_victory_and_defeat_mark_survivors():
	var arena := _open()
	for u in arena.combatants:
		if not u.is_player_side():
			u.current_hp = 0
	arena._check_end()
	assert_eq(arena._animator_for(arena.combatants[0]).current_animation, "victory", "vitória: sobreviventes celebram")


func test_defeat_ends_cleanly_without_animations():
	# is_battle_over encerra em derrota só com a party inteira morta — não há
	# sobrevivente para animar (o luto é da result screen, não da arena).
	var arena := _open()
	var ended := {"victory": null}
	arena.battle_ended.connect(func(v, _r): ended["victory"] = v)
	for u in arena.combatants:
		if u.is_player_side():
			u.current_hp = 0
	arena._check_end()
	arena._on_result_continue_pressed()
	assert_false(ended["victory"], "derrota encerra a batalha")
	for u in arena.combatants:
		var a = arena._animator_for(u)
		if a:
			assert_ne(a.current_animation, "defeat", "arena não anima mortos")


func test_animator_still_finds_named_sprite_in_legacy_units():
	# Regressão: a reordenação do _find_sprite não pode quebrar o caminho legado
	# (sprite com nome explícito "Sprite2D" continua encontrado).
	var unit := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = ImageTexture.create_from_image(Image.create(64, 64, false, Image.FORMAT_RGBA8))
	unit.add_child(sprite)
	add_child_autofree(unit)
	var animator := UnitAnimator.new()
	add_child_autofree(animator)
	animator.setup(unit)
	assert_not_null(animator.sprite, "nome explícito continua funcionando")
	assert_eq(animator.sprite.texture.get_width(), 64)
