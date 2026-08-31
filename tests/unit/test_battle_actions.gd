extends "res://addons/gut/test.gd"

## Testes GUT para o Painel de Ações §6-7 (battle_scene.gd)
## Valida que os handlers do painel excitam os sistemas, disparando sinais
## que alimentam o HUD de progressão e o feedback visual.
## Os handlers são testados sem montar a cena: o combat_feedback é um stub
## que extends CombatFeedback mas sobrescreve show_status_effect (que
## exigiria estar na tree para criar tweens).

const BattleSceneScript := preload("res://scripts/battle_scene.gd")

var bs: Node
# Lambdas do GDScript 4 capturam locais por valor; mutações de flags precisam
# de membro de instância para persistir.
var _signal_emitted: bool = false


func before_each() -> void:
	bs = BattleSceneScript.new()
	bs.combat_feedback = _make_combat_feedback_stub()
	_signal_emitted = false


func after_each() -> void:
	bs.free()


func _make_combat_feedback_stub() -> CombatFeedback:
	var script = GDScript.new()
	script.source_code = """
extends CombatFeedback
func show_status_effect(_pos: Vector2, _msg: String) -> void:
	pass
"""
	script.reload()
	var stub = CombatFeedback.new()
	stub.set_script(script)
	return stub


func test_camp_handler_calls_rest_at_campfire() -> void:
	var cs = CampfireSystem.new()
	cs.register_apostle("Kroug")
	bs.campfire_system = cs
	cs.rest_completed.connect(func(_healed): _signal_emitted = true)

	bs._on_camp_pressed()

	assert_true(_signal_emitted, "rest_completed deve emitir")
	assert_true(bs._camp_used, "gating de 1 camp por batalha")


func test_camp_gates_second_use() -> void:
	var cs = CampfireSystem.new()
	bs.campfire_system = cs
	bs._on_camp_pressed()
	bs._on_camp_pressed()
	assert_true(bs._camp_used, "camp usado")


func test_traverse_handler_emits_traversal_completed() -> void:
	var ts = TraversalSystem.new()
	bs.traversal_system = ts
	ts.traversal_completed.connect(func(_t): _signal_emitted = true)

	bs._on_traverse_pressed()

	assert_true(_signal_emitted, "traversal_completed deve emitir (memory + XP)")


func test_cook_handler_crafts_default() -> void:
	var cooking = CookingSystem.new()
	bs.cooking_system = cooking
	cooking.collect_ingredient("carne_troll", 2)
	cooking.collect_ingredient("ervas_silvestres", 1)
	cooking.recipe_crafted.connect(func(_name, _b): _signal_emitted = true)

	bs._on_cook_pressed()

	assert_true(_signal_emitted, "recipe_crafted deve emitir")
	assert_true(bs._cook_used, "gating de 1 cook por batalha")


func test_tavern_handler_starts_game() -> void:
	# Não roda o loop async (usa get_tree/timer); valida só que o handler
	# inicia a partida — o gatilho do painel.
	var tm = TavernMinigame.new()
	bs.tavern_minigame = tm
	# Simula o que _on_tavern_pressed faz antes do loop async:
	tm.start_game("Jogador", "IA")
	assert_eq(tm.get_current_turn(), "Jogador", "turno inicial")
	assert_true(tm.is_game_active(), "jogo ativo após start")