extends "res://addons/gut/test.gd"

## Testes GUT para TraversalSystem (Travessia Dinâmica, GDD v2 §6.1)


func test_initial_stamina():
 var ts = TraversalSystem.new()
 ts.setup(false, 100)
 assert_eq(ts.get_stamina(), 100, "Stamina inicial = 100")


func test_can_climb_without_wings():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("cliff")
 var result = ts.can_traverse("climb")
 assert_eq(result.can, true, "Pode escalar sem asas")


func test_cannot_glide_without_wings():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("air")
 var result = ts.can_traverse("glide")
 assert_eq(result.can, false, "Não pode planar sem asas")
 assert_eq(result.reason, "Precisa de asas", "Razão = Precisa de asas")


func test_can_glide_with_wings():
 var ts = TraversalSystem.new()
 ts.setup(true)
 ts.set_terrain("air")
 var result = ts.can_traverse("glide")
 assert_eq(result.can, true, "Pode planar com asas")


func test_can_swim_in_water():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("water")
 var result = ts.can_traverse("swim")
 assert_eq(result.can, true, "Pode nadar na água")


func test_cannot_climb_in_water():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("water")
 var result = ts.can_traverse("climb")
 assert_eq(result.can, false, "Não pode escalar na água")


func test_stamina_cost():
 var ts = TraversalSystem.new()
 ts.setup(false, 100)
 ts.set_terrain("cliff")
 ts.start_traversal("climb")
 assert_eq(ts.get_stamina(), 80, "Stamina = 100 - 20 (climb)")


func test_insufficient_stamina():
 var ts = TraversalSystem.new()
 ts.setup(false, 10)
 ts.set_terrain("cliff")
 var result = ts.can_traverse("climb")
 assert_eq(result.can, false, "Não pode escalar com stamina baixa")
 assert_eq(result.reason, "Stamina insuficiente", "Razão = Stamina insuficiente")


func test_stamina_regen():
 var ts = TraversalSystem.new()
 ts.setup(false, 100)
 ts.set_terrain("cliff")
 ts.start_traversal("climb")
 assert_eq(ts.get_stamina(), 80, "Stamina = 80 após climb")
 ts.end_traversal()
 ts.regen_stamina(2.0)
 assert_eq(ts.get_stamina(), 90, "Stamina = 90 após regen")


func test_stamina_capped_at_max():
 var ts = TraversalSystem.new()
 ts.setup(false, 100)
 ts.regen_stamina(100.0)
 assert_eq(ts.get_stamina(), 100, "Stamina não excede máximo")


func test_terrain_speed_multiplier():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("water")
 assert_eq(ts.get_terrain_speed_multiplier(), 0.6, "Água = 0.6x velocidade")
 ts.set_terrain("ground")
 assert_eq(ts.get_terrain_speed_multiplier(), 1.0, "Chão = 1.0x velocidade")


func test_traversal_started_signal():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("cliff")
 watch_signals(ts)
 ts.start_traversal("climb")
 assert_signal_emitted(ts, "traversal_started", "Sinal deve disparar")


func test_traversal_completed_signal():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("cliff")
 watch_signals(ts)
 ts.start_traversal("climb")
 ts.end_traversal()
 assert_signal_emitted(ts, "traversal_completed", "Sinal deve disparar")


func test_is_traversing():
 var ts = TraversalSystem.new()
 ts.setup(false)
 ts.set_terrain("cliff")
 assert_eq(ts.is_traversing(), false, "Não está traversando")
 ts.start_traversal("climb")
 assert_eq(ts.is_traversing(), true, "Está traversando")
 ts.end_traversal()
 assert_eq(ts.is_traversing(), false, "Parou de traversar")


func test_ether_harpoon_requires_wings():
 var ts = TraversalSystem.new()
 ts.setup(false)
 var result = ts.can_traverse("ether_harpoon")
 assert_eq(result.can, false, "Arpêu precisa de asas")


func test_ether_harpoon_with_wings():
 var ts = TraversalSystem.new()
 ts.setup(true)
 var result = ts.can_traverse("ether_harpoon")
 assert_eq(result.can, true, "Arpêu funciona com asas")


func test_unknown_ability():
 var ts = TraversalSystem.new()
 ts.setup(true)
 var result = ts.can_traverse("fly")
 assert_eq(result.can, false, "Habilidade desconhecida")
 assert_eq(result.reason, "Habilidade desconhecida", "Razão = desconhecida")


func test_get_ability_data():
 var ts = TraversalSystem.new()
 var data = ts.get_ability_data("climb")
 assert_eq(data.name, "Escalar", "Nome = Escalar")
 assert_eq(data.stamina_cost, 20, "Custo = 20")


func test_get_all_abilities():
 var ts = TraversalSystem.new()
 var abilities = ts.get_all_abilities()
 assert_eq(abilities.size(), 6, "6 habilidades de travessia")
