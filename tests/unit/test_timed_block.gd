extends "res://addons/gut/test.gd"

## Testes GUT: Timed Block no pipeline do BattleManager (GDD v2 §3.1, ROADMAP #11)
## A defesa reativa espelha o timed hit: ataque inimigo em alvo jogador abre a
## janela de 0.2s e o resolver (callable) devolve a fração de dano bloqueada.
## O núcleo é testado headless instalando resolvers síncronos (sem input real).
## calculate_damage tem variação randômica ±15% — cada comparação usa a mesma
## seed nas duas corridas para isolar só o efeito do bloqueio.

var bm: Node
var _last_damage: int = 0


func before_each():
	var BM = load("res://scripts/BattleManager.gd")
	bm = BM.new()
	add_child_autofree(bm)
	_last_damage = 0


func _on_damage(_a, _t, dmg) -> void:
	_last_damage = dmg


func _make_pair(atk: int, defense: int, target_is_player: bool = true) -> Array:
	var attacker_data: UnitData = UnitData.new()
	attacker_data.is_player = false
	attacker_data.attack = atk
	attacker_data.magic = 0
	attacker_data.defense = 0
	var attacker: Unit = Unit.new()
	attacker.data = attacker_data
	attacker.current_hp = 50
	attacker.grid_position = Vector2i(0, 0)

	var target_data: UnitData = UnitData.new()
	target_data.is_player = target_is_player
	target_data.attack = 30
	target_data.magic = 0
	target_data.defense = defense
	var target: Unit = Unit.new()
	target.data = target_data
	target.current_hp = 100
	target.grid_position = Vector2i(1, 0)

	return [attacker, target]


func _register_pair(pair: Array) -> void:
	bm.register_unit(pair[0])
	bm.register_unit(pair[1])
	bm.unit_attacked.connect(_on_damage)


func test_no_resolver_equals_miss_block():
	# Sem resolver e com resolver MISS (0.0) o dano deve ser idêntico.
	var pair_a := _make_pair(30, 0)
	_register_pair(pair_a)
	seed(1234)
	await bm.attack_unit(pair_a[0], pair_a[1])
	var baseline := _last_damage
	assert_gt(baseline, 0, "ataque inimigo causa dano")

	_reset_pair(pair_a)
	seed(1234)
	bm.timed_block_resolver = func(_a, _t): return 0.0
	await bm.attack_unit(pair_a[0], pair_a[1])

	assert_eq(_last_damage, baseline, "resolver MISS = dano integral (comportamento antigo)")


func test_perfect_block_halves_damage():
	var pair := _make_pair(30, 0)
	_register_pair(pair)
	seed(1234)
	await bm.attack_unit(pair[0], pair[1])
	var baseline := _last_damage

	_reset_pair(pair)
	seed(1234)
	bm.timed_block_resolver = func(_a, _t): return 0.5
	await bm.attack_unit(pair[0], pair[1])

	assert_eq(_last_damage, int(baseline * 0.5), "PERFECT block (-50%) corta o dano pela metade")


func test_great_block_cuts_30_percent():
	var pair := _make_pair(30, 0)
	_register_pair(pair)
	seed(1234)
	await bm.attack_unit(pair[0], pair[1])
	var baseline := _last_damage

	_reset_pair(pair)
	seed(1234)
	bm.timed_block_resolver = func(_a, _t): return 0.3
	await bm.attack_unit(pair[0], pair[1])

	assert_eq(_last_damage, int(baseline * 0.7), "GREAT block (-30%) corta 30% do dano")


func test_block_window_signal_emitted_for_enemy_attack_on_player():
	var pair := _make_pair(30, 0)
	_register_pair(pair)
	watch_signals(bm)
	bm.timed_block_resolver = func(_a, _t): return 0.0

	await bm.attack_unit(pair[0], pair[1])

	assert_signal_emitted(bm, "timed_block_window", "janela defensiva abre para ataque inimigo em jogador")


func test_no_window_for_player_attack_on_enemy():
	var pair := _make_pair(30, 0)
	_register_pair(pair)
	watch_signals(bm)
	bm.timed_block_resolver = func(_a, _t): return 0.5

	await bm.attack_unit(pair[1], pair[0])

	assert_signal_not_emitted(bm, "timed_block_window", "ataque do jogador não abre janela defensiva")


func test_no_window_for_enemy_attack_on_enemy():
	var pair := _make_pair(30, 0)
	pair[1].data.is_player = false
	_register_pair(pair)
	watch_signals(bm)
	bm.timed_block_resolver = func(_a, _t): return 0.5

	await bm.attack_unit(pair[0], pair[1])

	assert_signal_not_emitted(bm, "timed_block_window", "alvo não-jogador não abre janela defensiva")


func test_invalid_resolver_ignored():
	var pair_a := _make_pair(30, 0)
	_register_pair(pair_a)
	seed(1234)
	await bm.attack_unit(pair_a[0], pair_a[1])
	var baseline := _last_damage

	_reset_pair(pair_a)
	seed(1234)
	bm.timed_block_resolver = Callable()
	await bm.attack_unit(pair_a[0], pair_a[1])

	assert_eq(_last_damage, baseline, "resolver inválido = dano integral, sem crash")


func _reset_pair(pair: Array) -> void:
	_last_damage = 0
	pair[0].current_hp = 50
	pair[1].current_hp = 100
