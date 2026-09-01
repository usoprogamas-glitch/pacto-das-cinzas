class_name EquipmentSystem
extends RefCounted

## Equipamentos da Forja (GDD v2 §7, AUDIT P1 #12): consome as flags de
## desbloqueio do BuildingSystem (`craft_armas_basicas` / `craft_armas_avancadas`
## vindas da Fornalha Vulcânica / Forja do Rei Ogro) e produz bônus permanentes
## por SLOT (1 item por slot — craftar outro do mesmo slot exige slot livre).
## Data-driven: nada de conteúdo hardcoded na lógica.

signal equipment_crafted(equipment_id: String, bonuses: Dictionary)

const EQUIPMENT: Dictionary = {
	"espada_de_cinzas": {
		"name": "Espada de Cinzas",
		"slot": "weapon",
		"bonuses": {"atk": 5},
		"cost": {"materials": 3},
		"unlock_feature": "craft_armas_básicas",
	},
	"bracelete_de_ossos": {
		"name": "Bracelete de Ossos",
		"slot": "trinket",
		"bonuses": {"def": 5},
		"cost": {"materials": 4},
		"unlock_feature": "craft_armas_básicas",
	},
	"arco_de_eter": {
		"name": "Arco de Éter",
		"slot": "weapon",
		"bonuses": {"magic": 8},
		"cost": {"materials": 6, "soul_ether": 30},
		"unlock_feature": "craft_armas_avançadas",
	},
	"manto_das_cinzas": {
		"name": "Manto das Cinzas Ancestrais",
		"slot": "armor",
		"bonuses": {"def": 8, "hp": 30},
		"cost": {"materials": 8, "gold": 50},
		"unlock_feature": "craft_armas_avançadas",
	},
}


## --- Estado ---
var _resources: Dictionary = {"materials": 0, "soul_ether": 0, "gold": 0}
var _unlocked: Dictionary = {}  # espelho de BuildingSystem.unlocked_features
var _owned: Array = []  # ids dos equipamentos já forjados


## --- Setup (bridge com BuildingSystem/GameManager) ---

## Espelha os desbloqueios da vila (Fornalha/Forja).
func set_unlocked_features(features: Dictionary) -> void:
	_unlocked = features.duplicate()


## Espelha os recursos da vila (materials/gold/soul_ether).
func set_resources(resources: Dictionary) -> void:
	for key in ["materials", "soul_ether", "gold"]:
		if resources.has(key):
			_resources[key] = int(resources[key])


## --- Consultas ---

func can_craft(equipment_id: String) -> Dictionary:
	var item: Dictionary = EQUIPMENT.get(equipment_id, {})
	if item.is_empty():
		return {"can": false, "reason": "Equipamento desconhecido"}
	var feature: String = item.get("unlock_feature", "")
	if feature != "" and not _unlocked.get(feature, false):
		return {"can": false, "reason": "Forja sem o desbloqueio necessário"}
	for resource: String in item["cost"]:
		if int(_resources.get(resource, 0)) < int(item["cost"][resource]):
			return {"can": false, "reason": "Recursos insuficientes"}
	for owned_id in _owned:
		if EQUIPMENT.get(owned_id, {}).get("slot", "") == item["slot"]:
			return {"can": false, "reason": "Slot já ocupado"}
	return {"can": true, "reason": ""}


## --- Ações ---

## Forja o equipamento: deduz recursos, marca como possuído e emite o sinal.
## Retorna {"ok": true, "bonuses": {...}} ou {"ok": false, "reason": motivo}.
func craft(equipment_id: String) -> Dictionary:
	var check := can_craft(equipment_id)
	if not check.can:
		return {"ok": false, "reason": check.reason}
	var item: Dictionary = EQUIPMENT[equipment_id]
	for resource: String in item["cost"]:
		_resources[resource] = int(_resources[resource]) - int(item["cost"][resource])
	_owned.append(equipment_id)
	equipment_crafted.emit(equipment_id, item["bonuses"])
	return {"ok": true, "bonuses": item["bonuses"]}


## --- Getters ---

func get_owned() -> Array:
	return _owned.duplicate()


func owns(equipment_id: String) -> bool:
	return equipment_id in _owned


func get_total_bonuses() -> Dictionary:
	var totals := {}
	for owned_id in _owned:
		var bonuses: Dictionary = EQUIPMENT.get(owned_id, {}).get("bonuses", {})
		for stat: String in bonuses:
			totals[stat] = int(totals.get(stat, 0)) + int(bonuses[stat])
	return totals


func get_equipment(equipment_id: String) -> Dictionary:
	return EQUIPMENT.get(equipment_id, {})


func get_all_equipment() -> Dictionary:
	return EQUIPMENT
