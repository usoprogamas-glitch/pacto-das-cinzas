extends GutTest

## Balance #16: stats do Kael/Kroug na arena derivam do level do
## ProgressionSystem + elixires permanentes. Baseline level 1 = números
## históricos (80/12/8/11/50), compatível com todos os testes anteriores.

const ArenaScene := preload("res://scripts/arena_battle.gd")


func _make_scene(game_data: Dictionary = {}, level: int = 1) -> Node2D:
 var scene: Node2D = ArenaScene.new()
 scene.combat_frozen = true
 if GameManager:
  # Estado limpo: o autoload persiste entre testes (elixires/xp vazariam).
  GameManager.game_data["elixir_bonuses"] = {}
  GameManager.game_data.merge(game_data, true)
  if GameManager.progression_system:
   GameManager.progression_system.total_experience = 0
   if level > 1:
    GameManager.progression_system.add_experience(3000)
 scene._setup_from_campaign()
 return scene


func _teardown(scene: Node2D) -> void:
 if GameManager and GameManager.progression_system:
  GameManager.progression_system.total_experience = 0
  GameManager.game_data["elixir_bonuses"] = {}
 scene.queue_free()


func test_level_1_keeps_historical_baseline() -> void:
 var s := _make_scene()
 var kael: Unit = s.combatants[0]
 assert_eq(kael.data.max_hp, 80, "hp baseline")
 assert_eq(kael.data.attack, 12, "atk baseline")
 assert_eq(kael.data.defense, 8, "def baseline")
 assert_eq(kael.data.max_mp, 50, "mp baseline")
 _teardown(s)


func test_higher_level_scales_stats() -> void:
 var s := _make_scene({}, 6)
 var kael: Unit = s.combatants[0]
 assert_eq(kael.data.max_hp, 80 + 14 * 5, "hp +14/lv")
 assert_eq(kael.data.attack, 12 + 2 * 5, "atk +2/lv")
 assert_eq(kael.data.defense, 8 + 5, "def +1/lv")
 assert_eq(kael.data.max_mp, 50 + 5 * 5, "mp +5/lv")
 _teardown(s)


func test_kroug_scales_at_sixty_percent() -> void:
 var s := _make_scene({"starting_ally": "kroug"}, 6)
 var kroug: Unit = s.combatants[1]
 assert_eq(kroug.data.max_hp, 120 + 8 * 5, "kroug hp +8/lv")
 assert_eq(kroug.data.attack, 10 + 7, "kroug atk +1.5/lv")
 assert_eq(kroug.data.defense, 15, "kroug def fixo")
 _teardown(s)


func test_elixir_bonuses_apply_to_arena() -> void:
 var s := _make_scene({"elixir_bonuses": {"max_hp": 20, "max_ether": 10, "attack_percent": 50}})
 var kael: Unit = s.combatants[0]
 assert_eq(kael.data.max_hp, 80 + 20, "elixir max_hp soma")
 assert_eq(kael.data.max_mp, 50 + 10, "elixir max_ether soma")
 assert_eq(kael.data.attack, 18, "attack_percent multiplica o base (12 x 1.5)")
 _teardown(s)


func test_no_game_manager_falls_back_to_baseline() -> void:
 # Sem level-up (progression zerada): level 1, stats históricos.
 var s := _make_scene({}, 1)
 assert_eq(s.combatants[0].data.max_hp, 80)
 _teardown(s)
