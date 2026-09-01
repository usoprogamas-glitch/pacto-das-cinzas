extends "res://addons/gut/test.gd"

## Culinária §7.2 — bônus PERMANENTES de elixires (AUDIT P1 #14): gate de
## max_uses por elixir, sinal elixir_crafted dedicado e aplicação permanente
## nos stats da party com persistência no save (GameManager.apply_elixir_bonuses).

const CookingLib := preload("res://scripts/cooking_system.gd")
const BattleSceneScript := preload("res://scripts/battle_scene.gd")

var cs


func before_each() -> void:
	cs = CookingLib.new()
	GameManager.game_data.erase("elixir_bonuses")
	GameManager.party_data = [
		{"name": "Kael", "class": "Protagonista", "hp": 100, "ether": 5, "atk": 15, "def": 10},
	]


func after_each() -> void:
	cs = null
	GameManager.game_data.erase("elixir_bonuses")


# --- Gate de max_uses ---

func test_elixir_blocked_after_max_uses():
	cs.collect_ingredient("pedra_eterea", 2)
	cs.collect_ingredient("lagrima_fada", 1)
	assert_eq(cs.get_elixir_uses_left("elixir_etereo"), 1, "1 uso restante")
	assert_true(cs.can_craft("elixir_etereo"), "craftável com ingredientes")
	cs.craft("elixir_etereo")
	assert_eq(cs.get_elixir_uses_left("elixir_etereo"), 0, "uso único consumido")
	assert_false(cs.can_craft("elixir_etereo"), "bloqueado após 1 uso")


func test_craft_returns_empty_after_max_uses_even_with_ingredients():
	cs.collect_ingredient("pedra_eterea", 4)
	cs.collect_ingredient("lagrima_fada", 2)
	assert_not_same(cs.craft("elixir_etereo"), {}, "1º craft ok")
	var second: Dictionary = cs.craft("elixir_etereo")
	assert_true(second.is_empty(), "2º craft recusado mesmo com ingredientes")


func test_furia_and_vida_allow_two_uses():
	cs.collect_ingredient("cinzas_ancestrais", 4)
	cs.collect_ingredient("raiz_profunda", 2)
	assert_eq(cs.get_elixir_uses_left("pocao_furia"), 2, "fúria: 2 usos")
	cs.collect_ingredient("lagrima_fada", 4)
	cs.collect_ingredient("fruta_eterna", 2)
	assert_eq(cs.get_elixir_uses_left("essencia_vida"), 2, "vida: 2 usos")


# --- Sinal dedicado ---

func test_elixir_crafted_signal_emitted():
	watch_signals(cs)
	cs.collect_ingredient("pedra_eterea", 2)
	cs.collect_ingredient("lagrima_fada", 1)
	cs.craft("elixir_etereo")
	assert_signal_emitted(cs, "elixir_crafted")
	assert_signal_emitted(cs, "recipe_crafted")


func test_food_does_not_emit_elixir_signal():
	watch_signals(cs)
	cs.collect_ingredient("carne_troll", 2)
	cs.collect_ingredient("ervas_silvestres", 1)
	cs.craft("guisado_goblin")
	assert_signal_not_emitted(cs, "elixir_crafted")
	assert_signal_emitted(cs, "recipe_crafted")


# --- Aplicação permanente no GameManager ---

func test_apply_elixir_bonuses_persists_and_buffs_party():
	GameManager.apply_elixir_bonuses({"max_hp": 50, "max_ether": 1})
	var member: Dictionary = GameManager.party_data[0]
	assert_eq(int(member["hp"]), 150, "HP base +50 permanente")
	assert_eq(int(member["ether"]), 6, "Éter +1 permanente")
	assert_same(GameManager.game_data["elixir_bonuses"]["max_hp"], 50, "bônus gravado no save")


func test_attack_percent_multiplies_party_atk():
	GameManager.apply_elixir_bonuses({"attack_percent": 10})
	assert_eq(int(GameManager.party_data[0]["atk"]), 17, "atk 15 +10% = 16.5 → 17 (arredondado)")
	GameManager.apply_elixir_bonuses({"attack_percent": 10})
	assert_eq(int(GameManager.party_data[0]["atk"]), 18, "2ª dose: 15 +20% = 18 (base, sem composição)")


func test_apply_empty_bonuses_is_noop():
	var hp_before: int = int(GameManager.party_data[0]["hp"])
	GameManager.apply_elixir_bonuses({})
	assert_eq(int(GameManager.party_data[0]["hp"]), hp_before, "sem bônus, sem mudança")


# --- Integração: craft de elixir aplica permanentemente via GameManager ---

func test_battle_scene_cook_applies_elixir_permanently():
	var bs = BattleSceneScript.new()
	bs.combat_feedback = CombatFeedbackStub.make_stub(self)
	bs.cooking_system = CookingLib.new()
	bs.cooking_system.recipe_crafted.connect(bs._on_recipe_crafted)
	# Ingredientes do elixir_etereo (pedra x2 + lagrima x1) direto no inventário.
	bs.cooking_system.collect_ingredient("pedra_eterea", 2)
	bs.cooking_system.collect_ingredient("lagrima_fada", 1)
	var ether_before: int = int(GameManager.party_data[0].get("ether", 0))
	bs._on_cook_pressed()
	assert_eq(int(GameManager.party_data[0]["ether"]), ether_before + 1, "elixir da cozinha aplica +1 Éter permanente")
	assert_false(GameManager.game_data.get("elixir_bonuses", {}).is_empty(), "persistência no save alimentada")
	bs.free()


## Stub do CombatFeedback (mesmo padrão do test_panel_smoke, fonte mínima).
class CombatFeedbackStub:
	static func make_stub(_listener) -> CombatFeedback:
		var script = GDScript.new()
		script.source_code = """
extends CombatFeedback
func show_status_effect(_pos: Vector2, _msg: String) -> void:
	pass
"""
		script.reload()
		return script.new()
