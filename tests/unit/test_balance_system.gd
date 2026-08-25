extends "res://addons/gut/test.gd"

## Testes GUT para BalanceSystem (Medidor de Éter vs Fúria, GDD v2 §3.3)


func test_initial_values():
	var bs = BalanceSystem.new()
	assert_eq(bs.get_ether(), 0, "Éter inicial = 0")
	assert_eq(bs.get_fury(), 0, "Fúria inicial = 0")
	assert_eq(bs.get_current_mode(), "NEUTRAL", "Modo inicial = NEUTRAL")


func test_ether_action_heal():
	var bs = BalanceSystem.new()
	var gain = bs.perform_ether_action("heal")
	assert_eq(gain, 10, "Cura = +10 Éter")
	assert_eq(bs.get_ether(), 10, "Éter deve ser 10")


func test_ether_action_liberate():
	var bs = BalanceSystem.new()
	var gain = bs.perform_ether_action("liberate_monster")
	assert_eq(gain, 20, "Libertação = +20 Éter")
	assert_eq(bs.get_ether(), 20, "Éter deve ser 20")


func test_ether_action_invalid():
	var bs = BalanceSystem.new()
	var gain = bs.perform_ether_action("unknown")
	assert_eq(gain, 0, "Ação inválida = 0 ganho")


func test_fury_action_execute():
	var bs = BalanceSystem.new()
	var gain = bs.perform_fury_action("execute")
	assert_eq(gain, 15, "Execução = +15 Fúria")
	assert_eq(bs.get_fury(), 15, "Fúria deve ser 15")


func test_fury_action_mass_destruction():
	var bs = BalanceSystem.new()
	var gain = bs.perform_fury_action("mass_destruction")
	assert_eq(gain, 20, "Destruição em massa = +20 Fúria")
	assert_eq(bs.get_fury(), 20, "Fúria deve ser 20")


func test_fury_action_invalid():
	var bs = BalanceSystem.new()
	var gain = bs.perform_fury_action("dance")
	assert_eq(gain, 0, "Ação inválida = 0 ganho")


func test_ether_clamps_max():
	var bs = BalanceSystem.new()
	bs.perform_ether_action("liberate_monster")  # 20
	bs.perform_ether_action("liberate_monster")  # 40
	bs.perform_ether_action("liberate_monster")  # 60
	bs.perform_ether_action("liberate_monster")  # 80
	bs.perform_ether_action("liberate_monster")  # 100
	bs.perform_ether_action("liberate_monster")  # 100 (clamp)
	assert_eq(bs.get_ether(), 100, "Éter deve ser limitado a 100")


func test_fury_clamps_max():
	var bs = BalanceSystem.new()
	for i in range(6):
		bs.perform_fury_action("mass_destruction")
	assert_eq(bs.get_fury(), 100, "Fúria deve ser limitada a 100")


func test_mode_switch_to_ether():
	var bs = BalanceSystem.new()
	bs.set_mode(BalanceSystem.Mode.ETHER)
	assert_eq(bs.get_current_mode(), "ETHER", "Modo deve ser Éter")


func test_mode_switch_to_fury():
	var bs = BalanceSystem.new()
	bs.set_mode(BalanceSystem.Mode.FURY)
	assert_eq(bs.get_current_mode(), "FURY", "Modo deve ser Fúria")


func test_symbiosis_reached():
	var bs = BalanceSystem.new()
	bs.perform_ether_action("liberate_monster")  # 5x = 100
	bs.perform_ether_action("liberate_monster")
	bs.perform_ether_action("liberate_monster")
	bs.perform_ether_action("liberate_monster")
	bs.perform_ether_action("liberate_monster")
	bs.perform_fury_action("mass_destruction")  # 5x = 100
	bs.perform_fury_action("mass_destruction")
	bs.perform_fury_action("mass_destruction")
	bs.perform_fury_action("mass_destruction")
	bs.perform_fury_action("mass_destruction")
	assert_eq(bs.is_symbiosis(), true, "Simbiose quando ambos ≥ 50")
	assert_eq(bs.get_current_mode(), "SYMBIOSIS", "Modo deve ser Simbiose")


func test_symbiosis_not_reached():
	var bs = BalanceSystem.new()
	bs.perform_ether_action("heal")  # 10
	bs.perform_fury_action("execute")  # 15
	assert_eq(bs.is_symbiosis(), false, "Simbiose exige ambos ≥ 50")


func test_ether_bonuses():
	var bs = BalanceSystem.new()
	bs.set_mode(BalanceSystem.Mode.ETHER)
	var bonuses = bs.get_active_bonuses()
	assert_eq(bonuses.hp_regen_percent, 5, "Éter: +5% HP regen")
	assert_eq(bonuses.area_defense_percent, 15, "Éter: +15% defesa área")


func test_fury_bonuses():
	var bs = BalanceSystem.new()
	bs.set_mode(BalanceSystem.Mode.FURY)
	var bonuses = bs.get_active_bonuses()
	assert_eq(bonuses.armor_penetration_percent, 25, "Fúria: -25% armadura")
	assert_eq(bonuses.critical_damage_percent, 40, "Fúria: +40% crítico")


func test_symbiosis_bonuses_combined():
	var bs = BalanceSystem.new()
	bs.set_mode(BalanceSystem.Mode.ETHER)
	bs.perform_ether_action("liberate_monster")
	bs.perform_ether_action("liberate_monster")
	bs.perform_ether_action("liberate_monster")
	bs.perform_ether_action("liberate_monster")
	bs.perform_ether_action("liberate_monster")
	bs.perform_fury_action("mass_destruction")
	bs.perform_fury_action("mass_destruction")
	bs.perform_fury_action("mass_destruction")
	bs.perform_fury_action("mass_destruction")
	bs.perform_fury_action("mass_destruction")
	var bonuses = bs.get_active_bonuses()
	assert_eq(bonuses.has("hp_regen_percent"), true, "Simbiose deve ter bônus Éter")
	assert_eq(bonuses.has("armor_penetration_percent"), true, "Simbiose deve ter bônus Fúria")


func test_neutral_bonuses_empty():
	var bs = BalanceSystem.new()
	var bonuses = bs.get_active_bonuses()
	assert_eq(bonuses.size(), 0, "Neutro não deve ter bônus")


func test_reset():
	var bs = BalanceSystem.new()
	bs.perform_ether_action("heal")
	bs.perform_fury_action("execute")
	bs.reset()
	assert_eq(bs.get_ether(), 0, "Reset deve zerar Éter")
	assert_eq(bs.get_fury(), 0, "Reset deve zerar Fúria")
	assert_eq(bs.get_current_mode(), "NEUTRAL", "Reset deve voltar ao neutro")


func test_signal_ether_changed():
	var bs = BalanceSystem.new()
	watch_signals(bs)
	bs.perform_ether_action("heal")
	assert_signal_emitted(bs, "ether_changed", "Sinal Éter deve disparar")


func test_signal_fury_changed():
	var bs = BalanceSystem.new()
	watch_signals(bs)
	bs.perform_fury_action("execute")
	assert_signal_emitted(bs, "fury_changed", "Sinal Fúria deve disparar")
