extends "res://addons/gut/test.gd"

## Testes GUT para LockSystem (Lock & Spellbreak, GDD v2 §3.2)


func test_create_lock():
	var ls = LockSystem.new()
	var lock = ls.create_lock(null, {"type": "Corte", "hits": 2})
	assert_eq(lock.type, "Corte", "Lock deve ter tipo Corte")
	assert_eq(lock.remaining, 2, "Lock deve começar com 2 remaining")


func test_hit_lock_effective():
	var ls = LockSystem.new()
	var lock = ls.create_lock(null, {"type": "Corte", "hits": 2})
	var broken = ls.hit_lock(null, lock, "Corte")
	assert_eq(broken, false, "Não deve quebrar no primeiro hit")
	assert_eq(lock.remaining, 1, "Remaining deve ser 1")


func test_hit_lock_breaks():
	var ls = LockSystem.new()
	var lock = ls.create_lock(null, {"type": "Corte", "hits": 1})
	var broken = ls.hit_lock(null, lock, "Corte")
	assert_eq(broken, true, "Deve quebrar com 1 hit")
	assert_eq(lock.remaining, 0, "Remaining deve ser 0")


func test_hit_lock_ineffective():
	var ls = LockSystem.new()
	var lock = ls.create_lock(null, {"type": "Corte", "hits": 2})
	var broken = ls.hit_lock(null, lock, "Éter")
	assert_eq(broken, false, "Tipo errado não deve quebrar")
	assert_eq(lock.remaining, 2, "Remaining não deve mudar")


func test_is_effective():
	var ls = LockSystem.new()
	var lock = ls.create_lock(null, {"type": "Fogo", "hits": 1})
	assert_eq(ls.is_effective(lock, "Fogo"), true, "Fogo deve ser efetivo contra lock de Fogo")
	assert_eq(ls.is_effective(lock, "Corte"), false, "Corte não deve ser efetivo contra lock de Fogo")


func test_all_broken_true():
	var ls = LockSystem.new()
	var lock1 = ls.create_lock(null, {"type": "Corte", "hits": 1})
	var lock2 = ls.create_lock(null, {"type": "Éter", "hits": 1})
	ls.hit_lock(null, lock1, "Corte")
	ls.hit_lock(null, lock2, "Éter")
	assert_eq(ls.all_broken([lock1, lock2]), true, "Todos quebrados = true")


func test_all_broken_false():
	var ls = LockSystem.new()
	var lock1 = ls.create_lock(null, {"type": "Corte", "hits": 2})
	var lock2 = ls.create_lock(null, {"type": "Éter", "hits": 1})
	ls.hit_lock(null, lock1, "Corte")
	# lock2 ainda não atingido
	assert_eq(ls.all_broken([lock1, lock2]), false, "Um restante = false")


func test_decrement_spell_counter():
	var ls = LockSystem.new()
	var new_val = ls.decrement_spell_counter(null, 3, "Bola de Fogo")
	assert_eq(new_val, 2, "3 - 1 = 2")


func test_spell_counter_zero_casts():
	var ls = LockSystem.new()
	watch_signals(ls)
	var new_val = ls.decrement_spell_counter(null, 1, "Bola de Fogo")
	assert_eq(new_val, 0, "Deve chegar a 0")
	assert_signal_emitted(ls, "spell_cast", "Magia deve ser lançada ao zerar")


func test_resolve_spellbreak():
	var ls = LockSystem.new()
	var result = ls.resolve_spellbreak()
	assert_eq(result.stun_turns, 1, "Stun = 1 turno")
	assert_eq(result.cp_reward, 2, "Recompensa = 2 CP")


func test_is_valid_damage_type():
	var ls = LockSystem.new()
	assert_eq(ls.is_valid_damage_type("Corte"), true, "Corte deve ser válido")
	assert_eq(ls.is_valid_damage_type("Banana"), false, "Banana não deve ser válido")


func test_signal_lock_created_fires():
	var ls = LockSystem.new()
	watch_signals(ls)
	ls.create_lock(null, {"type": "Corte", "hits": 1})
	assert_signal_emitted(ls, "lock_created", "Sinal deve disparar ao criar lock")
