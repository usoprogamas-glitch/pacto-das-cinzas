extends "res://addons/gut/test.gd"

## Testes GUT para o MagicSystem (GDD v2 §3.3) — mecânica pura de feitiços:
## cast_spell, custo de MP, dano/cura, efectividade elementar e sinais.

var ms = MagicSystem.new()


func _make_unit(config: Dictionary = {}) -> Unit:
	var magic_val: int = config.get("magic", 20)
	var hp: int = config.get("hp", 100)
	var mp: int = config.get("mp", 50)
	var data: UnitData = UnitData.new()
	data.max_hp = hp
	data.current_hp = hp
	data.magic = magic_val
	data.max_mp = mp
	data.current_mp = mp
	var unit: Unit = Unit.new()
	unit.data = data
	unit.current_hp = hp
	unit.current_mp = mp
	return unit


func test_get_spell_known_and_unknown():
	assert_false(ms.get_spell("fire_bolt").is_empty(), "fire_bolt deve existir")
	assert_true(ms.get_spell("banana").is_empty(), "spell desconhecido = dict vazio")


func test_spell_not_found():
	var caster := _make_unit()
	var res = ms.cast_spell(caster, "inexistente", [])
	assert_eq(res.success, false, "spell inexistente falha")
	assert_eq(res.reason, "spell_not_found")


func test_not_enough_mp_keeps_mp():
	var caster := _make_unit({"mp": 5})  # fire_bolt custa 10
	var res = ms.cast_spell(caster, "fire_bolt", [])
	assert_eq(res.success, false, "MP insuficiente falha")
	assert_eq(res.reason, "not_enough_mp")
	assert_eq(caster.current_mp, 5, "MP intacto na falha")


func test_cast_damage_consumes_mp():
	var caster := _make_unit({"magic": 20})
	var target := _make_unit({"hp": 100, "magic": 0})
	caster.current_mp = 40
	var res = ms.cast_spell(caster, "fire_bolt", [target])
	assert_eq(res.success, true, "cast com MP suficiente sucede")
	assert_eq(caster.current_mp, 30, "desconta mp_cost (10)")
	assert_eq(res.results[0].has("damage"), true, "spell de dano tem chave damage")
	# dano bruto = (25 + magic 20) * variação 0.9-1.1 ≈ 40-49 (take_damage aplica a defesa do alvo)
	assert_between(res.results[0].damage, 40, 50, "dano do fire_bolt com mag 20")


func test_cast_heal_restores_hp():
	var caster := _make_unit({"magic": 20})
	var ally := _make_unit({"hp": 100})
	ally.current_hp = 30
	caster.current_mp = 40
	var res = ms.cast_spell(caster, "heal_wave", [ally])
	assert_eq(res.success, true, "heal_wave sucede")
	assert_eq(res.results[0].has("heal"), true, "spell de cura tem chave heal")
	assert_eq(ally.current_hp, 30 + res.results[0].heal, "HP restaurado pelo heal")


func test_get_element_effectiveness():
	assert_eq(ms.get_element_effectiveness(MagicSystem.Element.FIRE, MagicSystem.Element.EARTH), 1.5, "Fogo forte contra Terra")
	assert_eq(ms.get_element_effectiveness(MagicSystem.Element.FIRE, MagicSystem.Element.WATER), 0.5, "Fogo fraco contra Água")
	assert_eq(ms.get_element_effectiveness(MagicSystem.Element.FIRE, MagicSystem.Element.AIR), 1.0, "Elementos sem relação = neutro")
	assert_eq(ms.get_element_effectiveness(MagicSystem.Element.NONE, MagicSystem.Element.FIRE), 1.0, "Sem elemento = neutro")


func test_calculate_damage_scales_with_magic():
	# mesmo seed → mesmas amostras de variação; magic maior -> dano maior de forma
	# determinística (evita flakiness da rand 0.9-1.1)
	seed(42)
	var caster_low := _make_unit({"magic": 0})
	var target := _make_unit({"magic": 0})
	caster_low.current_mp = 40
	var spell = ms.get_spell("fire_bolt")
	var low_samples: Array = []
	for i in range(20):
		low_samples.append(ms.calculate_spell_damage(spell, caster_low, target))

	seed(42)
	var caster_high := _make_unit({"magic": 30})
	caster_high.current_mp = 40
	var high_samples: Array = []
	for i in range(20):
		high_samples.append(ms.calculate_spell_damage(spell, caster_high, target))

	for i in range(20):
		assert_true(high_samples[i] > low_samples[i], "magic maior ⇒ dano maior (amostra %d)" % i)
	assert_between(high_samples.max(), 54, 61, "mag 30 → 55 ±10%")


func test_signal_spell_cast_emitted():
	var caster := _make_unit()
	var target := _make_unit()
	caster.current_mp = 40
	watch_signals(ms)
	ms.cast_spell(caster, "fire_bolt", [target])
	assert_signal_emitted(ms, "spell_cast", "cast_spell emite spell_cast")


func test_signal_element_applied_on_damage():
	var caster := _make_unit()
	var target := _make_unit()
	caster.current_mp = 40
	watch_signals(ms)
	ms.cast_spell(caster, "fire_bolt", [target])
	assert_signal_emitted(ms, "element_applied", "spell de dano aplica elemento (Burning)")