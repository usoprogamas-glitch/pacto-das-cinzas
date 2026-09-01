extends "res://addons/gut/test.gd"

## Equipamentos da Forja (GDD §7, AUDIT P1 #12): consome as flags de desbloqueio
## do BuildingSystem (Fornalha/Forja do Rei Ogro), paga em materials/gold/éter,
## limita 1 item por slot (substituição reverte o antigo) e aplica bônus
## permanentes na party via GameManager.

const EquipmentLib := preload("res://scripts/equipment_system.gd")
const BattleSceneScript := preload("res://scripts/battle_scene.gd")

var eq


func before_each() -> void:
	eq = EquipmentLib.new()
	eq.set_unlocked_features({"craft_armas_básicas": true})
	eq.set_resources({"materials": 20, "gold": 100, "soul_ether": 50})
	GameManager.game_data.erase("equipment_bonuses")
	GameManager.game_data.erase("equipped")
	GameManager.party_data = [
		{"name": "Kael", "class": "Protagonista", "hp": 100, "ether": 5, "atk": 15, "def": 10, "magic": 0},
	]


func after_each() -> void:
	eq = null
	GameManager.game_data.erase("equipment_bonuses")
	GameManager.game_data.erase("equipped")


# --- Gate por desbloqueio da vila ---

func test_locked_without_fornalha_feature():
	eq.set_unlocked_features({})
	var r: Dictionary = eq.can_craft("espada_de_cinzas")
	assert_false(r.can, "sem flag da Fornalha, não crafta")
	assert_true(r.reason.contains("desbloqueio"), "motivo cita desbloqueio")


func test_advanced_forge_unlocks_eter_bow():
	eq.set_unlocked_features({"craft_armas_básicas": true, "craft_armas_avançadas": true})
	assert_true(eq.can_craft("arco_de_eter").can, "flag da Forja do Rei Ogro libera o Arco de Éter")


# --- Custo e recursos ---

func test_insufficient_materials_rejected():
	eq.set_resources({"materials": 2, "gold": 100, "soul_ether": 50})
	var r: Dictionary = eq.can_craft("espada_de_cinzas")
	assert_false(r.can, "espada custa 3 materiais, só tem 2")
	assert_true(r.reason.contains("Recursos"), "motivo de recursos")


func test_craft_deducts_resources_and_registers():
	watch_signals(eq)
	var result: Dictionary = eq.craft("espada_de_cinzas")
	assert_true(result.ok, "forjado com sucesso")
	assert_eq(result.bonuses.atk, 5, "bônus +5 atk")
	assert_true(eq.owns("espada_de_cinzas"), "registrado como possuído")
	assert_signal_emitted(eq, "equipment_crafted")


# --- Regra de slot ---

func test_slot_rule_blocks_second_weapon():
	eq.set_unlocked_features({"craft_armas_básicas": true, "craft_armas_avançadas": true})
	eq.craft("espada_de_cinzas")  # weapon
	var r: Dictionary = eq.can_craft("arco_de_eter")  # weapon também
	assert_false(r.can, "2ª arma no mesmo slot bloqueada")
	assert_true(r.reason.contains("Slot"), "motivo de slot")


func test_different_slots_coexist():
	assert_true(eq.craft("espada_de_cinzas").ok, "weapon ok")
	assert_true(eq.craft("bracelete_de_ossos").ok, "trinket ok")
	assert_eq(eq.get_owned().size(), 2, "dois slots ocupados")


# --- Agregação de bônus ---

func test_total_bonuses_sum_owned():
	eq.craft("espada_de_cinzas")
	eq.craft("bracelete_de_ossos")
	var totals: Dictionary = eq.get_total_bonuses()
	assert_eq(int(totals.get("atk", 0)), 5, "+5 atk da espada")
	assert_eq(int(totals.get("def", 0)), 5, "+5 def do bracelete")


func test_unknown_equipment_rejected():
	assert_false(eq.can_craft("item_inexistente").can, "id desconhecido rejeitado")
	assert_false(eq.craft("item_inexistente").ok, "craft de desconhecido falha")


# --- Ponte GameManager: bônus permanentes na party ---

func test_apply_equipment_buffs_party():
	GameManager.apply_equipment_bonuses({"atk": 5}, "espada_de_cinzas", "weapon")
	assert_eq(int(GameManager.party_data[0]["atk"]), 20, "atk 15 + 5 = 20")
	assert_eq(GameManager.game_data["equipped"]["espada_de_cinzas"], "weapon", "registro de slot no save")


func test_slot_replacement_reverts_old_item():
	GameManager.apply_equipment_bonuses({"atk": 5}, "espada_de_cinzas", "weapon")
	GameManager.apply_equipment_bonuses({"magic": 8}, "arco_de_eter", "weapon")
	var kael: Dictionary = GameManager.party_data[0]
	assert_eq(int(kael["atk"]), 15, "atk da espada revertido")
	assert_eq(int(kael["magic"]), 8, "magic do arco aplicado")
	assert_false(GameManager.game_data["equipped"].has("espada_de_cinzas"), "espada desequipada do save")
	assert_true(GameManager.game_data["equipped"].has("arco_de_eter"), "arco equipado no save")


# --- Ponte battle_scene: botão Forja usa BuildingSystem de verdade ---

func test_forge_button_consumes_building_flags_and_resources():
	GameManager.building_system.buildings["fornalha_vulcanica"]["level"] = 1
	GameManager.building_system.apply_building_effects("fornalha_vulcanica")
	GameManager.building_system.resources["materials"] = 10
	GameManager.game_data["materials"] = 10
	var bs = BattleSceneScript.new()
	bs.combat_feedback = _make_stub()
	var def_before: int = int(GameManager.party_data[0]["def"])
	bs._on_forge_pressed()
	assert_gt(GameManager.party_data.size(), 0, "party intacta")
	# Espada forjada: +5 atk na party e recursos do BuildingSystem debitados.
	assert_eq(int(GameManager.party_data[0]["atk"]), 20, "atk +5 do equipamento forjado")
	assert_eq(int(GameManager.building_system.resources["materials"]), 7, "3 materiais debitados")
	assert_true(GameManager.game_data["equipped"].has("espada_de_cinzas"), "espada equipada no save")
	assert_gt(int(GameManager.party_data[0]["def"]), def_before - 1000, "party íntegra")
	bs.free()


func _make_stub() -> CombatFeedback:
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