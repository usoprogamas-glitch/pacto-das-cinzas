class_name EquipmentDatabase
extends RefCounted

static var equipment: Dictionary = {
 # === ARMAS ===
 "item_espada_simples": {
  "id": "item_espada_simples",
  "name": "Espada Simples",
  "type": "weapon",
  "rarity": "common",
  "stats": {"atk": 5, "def": 0, "hp": 0, "mp": 0},
  "element": "none",
  "special_effect": "",
  "description": "Espada básica de pedra"
 },
 "item_machado_goblin": {
  "id": "item_machado_goblin",
  "name": "Machado Goblin",
  "type": "weapon",
  "rarity": "common",
  "stats": {"atk": 8, "def": 0, "hp": 0, "mp": 0},
  "element": "none",
  "special_effect": "crush: 10% chance de atordoar",
  "description": "Machado tosco feito por goblins"
 },
 "item_adaga_sombria": {
  "id": "item_adaga_sombria",
  "name": "Adaga Sombria",
  "type": "weapon",
  "rarity": "uncommon",
  "stats": {"atk": 12, "def": 0, "hp": 0, "mp": 5},
  "element": "shadow",
  "special_effect": "backstab: +50% dano costas",
  "description": "Adaga com toque de escuridão"
 },
 "item_cajado_elemental": {
  "id": "item_cajado_elemental",
  "name": "Cajado Elemental",
  "type": "weapon",
  "rarity": "rare",
  "stats": {"atk": 3, "def": 0, "hp": 0, "mp": 20},
  "element": "fire",
  "special_effect": "spell_power: +25% dano mágico",
  "description": "Cajado que amplifica magia"
 },
 "item_lamina_carmesim": {
  "id": "item_lamina_carmesim",
  "name": "Lâmina Carmesim",
  "type": "weapon",
  "rarity": "legendary",
  "stats": {"atk": 25, "def": 0, "hp": 0, "mp": 10},
  "element": "fire",
  "special_effect": "burning: inimigos pegam fogo",
  "description": "Espada lendária forjada em fogo"
 },

 # === ARMADURAS ===
 "item_couro_simples": {
  "id": "item_couro_simples",
  "name": "Armadura de Couro",
  "type": "armor",
  "rarity": "common",
  "stats": {"atk": 0, "def": 3, "hp": 10, "mp": 0},
  "element": "none",
  "special_effect": "",
  "description": "Armadura leve de couro"
 },
 "item_cota_mailha": {
  "id": "item_cota_mailha",
  "name": "Cota de Malha",
  "type": "armor",
  "rarity": "uncommon",
  "stats": {"atk": 0, "def": 8, "hp": 20, "mp": 0},
  "element": "none",
  "special_effect": "block: 15% chance bloquear",
  "description": "Armadura de malha resistente"
 },
 "item_peito_sombras": {
  "id": "item_peito_sombras",
  "name": "Peitoral das Sombras",
  "type": "armor",
  "rarity": "rare",
  "stats": {"atk": 0, "def": 12, "hp": 30, "mp": 10},
  "element": "shadow",
  "special_effect": "evasion: +10% esquiva",
  "description": "Armadura que absorve escuridão"
 },

 # === ACESSÓRIOS ===
 "item_anel_ferro": {
  "id": "item_anel_ferro",
  "name": "Anel de Ferro",
  "type": "accessory",
  "rarity": "common",
  "stats": {"atk": 2, "def": 1, "hp": 0, "mp": 0},
  "element": "none",
  "special_effect": "",
  "description": "Anel simples que fortalece"
 },
 "item_amuleto_vida": {
  "id": "item_amuleto_vida",
  "name": "Amuleto da Vida",
  "type": "accessory",
  "rarity": "uncommon",
  "stats": {"atk": 0, "def": 0, "hp": 50, "mp": 0},
  "element": "light",
  "special_effect": "regen: +5% HP por turno",
  "description": "Amuleto que restaura HP"
 },

 # === CONSUMÍVEIS ===
 "item_pocao_cura": {
  "id": "item_pocao_cura",
  "name": "Poção de Cura",
  "type": "consumable",
  "rarity": "common",
  "stats": {},
  "element": "none",
  "special_effect": "heal: restaura 30% HP",
  "description": "Restaura 30% HP"
 },
 "item_pocao_mana": {
  "id": "item_pocao_mana",
  "name": "Poção de Maná",
  "type": "consumable",
  "rarity": "common",
  "stats": {},
  "element": "none",
  "special_effect": "mana: restaura 30% MP",
  "description": "Restaura 30% MP"
 },
 "item_elxir_forca": {
  "id": "item_elxir_forca",
  "name": "Elixir da Força",
  "type": "consumable",
  "rarity": "uncommon",
  "stats": {},
  "element": "none",
  "special_effect": "buff_atk: +10 ATK por 3 turnos",
  "description": "+10 ATK por 3 turnos"
 }
}

static func get_equipment(item_id: String) -> Dictionary:
 if equipment.has(item_id):
  return equipment[item_id]
 return {}

static func get_equipment_by_type(type: String) -> Array:
 var result = []
 for item_id in equipment:
  if equipment[item_id].type == type:
   result.append(equipment[item_id])
 return result

static func get_equipment_by_rarity(rarity: String) -> Array:
 var result = []
 for item_id in equipment:
  if equipment[item_id].rarity == rarity:
   result.append(equipment[item_id])
 return result

static func apply_equipment(unit: Unit, item_id: String) -> void:
 var item = get_equipment(item_id)
 if item.is_empty():
  return

 for stat in item.stats:
  match stat:
   "atk": unit.data.attack += item.stats[stat]
   "def": unit.data.defense += item.stats[stat]
   "hp":
    unit.data.max_hp += item.stats[stat]
    unit.current_hp += item.stats[stat]
   "mp":
    unit.data.max_mp += item.stats[stat]
    unit.current_mp += item.stats[stat]

static func remove_equipment(unit: Unit, item_id: String) -> void:
 var item = get_equipment(item_id)
 if item.is_empty():
  return

 for stat in item.stats:
  match stat:
   "atk": unit.data.attack -= item.stats[stat]
   "def": unit.data.defense -= item.stats[stat]
   "hp":
    unit.data.max_hp -= item.stats[stat]
    unit.current_hp = mini(unit.current_hp, unit.data.max_hp)
   "mp":
    unit.data.max_mp -= item.stats[stat]
    unit.current_mp = mini(unit.current_mp, unit.data.max_mp)

static func use_consumable(unit: Unit, item_id: String) -> Dictionary:
 var item = get_equipment(item_id)
 if item.is_empty() or item.type != "consumable":
  return {"success": false}

 var effect = item.special_effect.split(":")[0]
 match effect:
  "heal":
   var heal = int(unit.data.max_hp * 0.3)
   unit.heal(heal)
   return {"success": true, "effect": "heal", "value": heal}
  "mana":
   var mana = int(unit.data.max_mp * 0.3)
   unit.current_mp = mini(unit.data.max_mp, unit.current_mp + mana)
   return {"success": true, "effect": "mana", "value": mana}
  "buff_atk":
   unit.data.attack += 10
   return {"success": true, "effect": "buff_atk", "value": 10, "duration": 3}

 return {"success": false}
