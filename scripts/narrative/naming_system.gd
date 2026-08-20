class_name NamingSystem
extends Node

signal soul_named(soul_id: String, name: String)
signal soul_evolved(soul_id: String, old_form: String, new_form: String)
signal pact_formed(soul_id: String, pact_power: int)
signal protagonist_progress(named_count: int)
signal fragment_recovered(fragment_id: String)

var named_souls: Dictionary = {}
var total_named: int = 0
var fragments_collected: int = 0

var soul_templates: Dictionary = {
 # === GOBLINS ===
 "goblin_lama": {
  "base_name": "Goblin da Lama",
  "type": "goblin",
  "base_stats": {"hp": 40, "attack": 8, "defense": 5, "speed": 10},
  "evolutions": [
   {"name": "Hobgoblin de Ferro", "level": 5, "stats": {"hp": 80, "attack": 15, "defense": 12}},
   {"name": "Ogro de Guerra", "level": 15, "stats": {"hp": 180, "attack": 30, "defense": 25}},
   {"name": "Rei Ogro de Fogo", "level": 30, "stats": {"hp": 350, "attack": 50, "defense": 40}}
  ],
  "pact_ability": "grito_guerra",
  "description": "Goblin fraco que evolui para colosso leal"
 },
 "goblin_fogo": {
  "base_name": "Goblin de Fogo",
  "type": "goblin",
  "base_stats": {"hp": 35, "attack": 12, "defense": 3, "speed": 12},
  "evolutions": [
   {"name": "Mago Goblin", "level": 5, "stats": {"hp": 60, "attack": 25, "defense": 5}},
   {"name": "Feiticeiro Ardente", "level": 15, "stats": {"hp": 100, "attack": 45, "defense": 8}},
   {"name": "Lorde do Fogo", "level": 30, "stats": {"hp": 180, "attack": 70, "defense": 12}}
  ],
  "pact_ability": "explosao_ignea",
  "description": "Goblin que domina o fogo"
 },

 # === LOBOS ===
 "lobo_sombrio": {
  "base_name": "Lobo Sombrio",
  "type": "besta",
  "base_stats": {"hp": 50, "attack": 12, "defense": 6, "speed": 18},
  "evolutions": [
   {"name": "Lobo Alfa", "level": 5, "stats": {"hp": 90, "attack": 22, "defense": 10}},
   {"name": "Lobo Etéreo", "level": 15, "stats": {"hp": 150, "attack": 38, "defense": 15}},
   {"name": "Lobo Primordial", "level": 30, "stats": {"hp": 280, "attack": 60, "defense": 25}}
  ],
  "pact_ability": "uivo_medo",
  "description": "Predador veloz que caça em bando"
 },
 "lobo_fogo": {
  "base_name": "Lobo de Fogo",
  "type": "besta",
  "base_stats": {"hp": 45, "attack": 15, "defense": 4, "speed": 16},
  "evolutions": [
   {"name": "Lobo Ígneo", "level": 5, "stats": {"hp": 80, "attack": 28, "defense": 8}},
   {"name": "Lobo Vulcânico", "level": 15, "stats": {"hp": 140, "attack": 48, "defense": 12}},
   {"name": "Lobo do Apocalipse", "level": 30, "stats": {"hp": 250, "attack": 75, "defense": 20}}
  ],
  "pact_ability": "mordida_pirrica",
  "description": "Lobo corrupto pelo fogo"
 },

 # === ARANHAS ===
 "aranha_gigante": {
  "base_name": "Aranha Gigante",
  "type": "besta",
  "base_stats": {"hp": 45, "attack": 10, "defense": 4, "speed": 14},
  "evolutions": [
   {"name": "Aranha Tecelã", "level": 5, "stats": {"hp": 75, "attack": 18, "defense": 8}},
   {"name": "Aranha Venenosa", "level": 15, "stats": {"hp": 130, "attack": 32, "defense": 12}},
   {"name": "Rainha Aranha", "level": 30, "stats": {"hp": 240, "attack": 55, "defense": 20}}
  ],
  "pact_ability": "teia_venenosa",
  "description": "Fera que prende com teias"
 },

 # === ESQUELETOS ===
 "esqueleto": {
  "base_name": "Esqueleto",
  "type": "morto_vivo",
  "base_stats": {"hp": 55, "attack": 10, "defense": 8, "speed": 8},
  "evolutions": [
   {"name": "Esqueleto Armado", "level": 5, "stats": {"hp": 90, "attack": 18, "defense": 15}},
   {"name": "Cavaleiro Esqueleto", "level": 15, "stats": {"hp": 160, "attack": 32, "defense": 28}},
   {"name": "Lorde Necromante", "level": 30, "stats": {"hp": 300, "attack": 50, "defense": 40}}
  ],
  "pact_ability": "exercito_mortos",
  "description": "Morto-vivo que comanda outros"
 },

 # === ENT ===
 "muda_magica": {
  "base_name": "Muda Mágica",
  "type": "planta",
  "base_stats": {"hp": 30, "attack": 5, "defense": 10, "speed": 6},
  "evolutions": [
   {"name": "Dryade Jovem", "level": 5, "stats": {"hp": 60, "attack": 10, "defense": 18}},
   {"name": "Ent Primordial", "level": 15, "stats": {"hp": 120, "attack": 18, "defense": 35}},
   {"name": "Rainha dos Bosques", "level": 30, "stats": {"hp": 250, "attack": 30, "defense": 55}}
  ],
  "pact_ability": "cura_natural",
  "description": "Espírito da natureza que cura e protege"
 },

 # === ANJO CAÍDO ===
 "anjo_caido": {
  "base_name": "Anjo Caído",
  "type": "serafim",
  "base_stats": {"hp": 60, "attack": 20, "defense": 8, "speed": 16},
  "evolutions": [
   {"name": "Seraphim Ferido", "level": 5, "stats": {"hp": 100, "attack": 35, "defense": 12}},
   {"name": "Cavaleiro Negro", "level": 15, "stats": {"hp": 180, "attack": 55, "defense": 20}},
   {"name": "Serafim das Sombras", "level": 30, "stats": {"hp": 320, "attack": 80, "defense": 30}}
  ],
  "pact_ability": "julgamento_cego",
  "description": "Anjo que duvidou dos deuses"
 }
}

func name_soul(soul_type: String, custom_name: String) -> Dictionary:
 if not soul_templates.has(soul_type):
  return {"success": false, "reason": "type_not_found"}

 var template = soul_templates[soul_type]

 var soul_id = "soul_%d" % total_named
 var soul = {
  "id": soul_id,
  "original_type": soul_type,
  "name": custom_name if custom_name != "" else template.base_name,
  "type": template.type,
  "level": 1,
  "form_index": 0,
  "stats": template.base_stats.duplicate(),
  "faith": 0,
  "pact_ability": template.pact_ability,
  "description": template.description,
  "loyalty": 100,
  "experience": 0
 }

 named_souls[soul_id] = soul
 total_named += 1

 soul_named.emit(soul_id, soul.name)
 protagonist_progress.emit(total_named)

 check_protagonist_evolution()

 return {"success": true, "soul": soul}

func check_protagonist_evolution() -> void:
 var old_form = "Imp Menor"

 if total_named >= 1000 and fragments_collected >= 12:
  old_form = "Avatar Primordial"
 elif total_named >= 100 and fragments_collected >= 7:
  old_form = "Arquidemônio"
 elif total_named >= 10 and fragments_collected >= 3:
  old_form = "Nobre Abissal"
 else:
  old_form = "Imp Menor"

 # Notificar mudança de forma
 protagonist_progress.emit(total_named)

func add_experience(soul_id: String, amount: int) -> void:
 if not named_souls.has(soul_id):
  return

 var soul = named_souls[soul_id]
 soul.experience += amount

 # Verificar level up
 var template = soul_templates[soul.original_type]
 var next_level = template.evolutions[soul.form_index].level if soul.form_index < template.evolutions.size() else 999

 if soul.level >= next_level and soul.form_index < template.evolutions.size():
  evolve_soul(soul_id)

func evolve_soul(soul_id: String) -> void:
 if not named_souls.has(soul_id):
  return

 var soul = named_souls[soul_id]
 var template = soul_templates[soul.original_type]

 if soul.form_index >= template.evolutions.size():
  return

 var old_form = soul.name
 var new_evolution = template.evolutions[soul.form_index]

 soul.name = new_evolution.name
 soul.form_index += 1
 soul.stats = new_evolution.stats.duplicate()

 soul_evolved.emit(soul_id, old_form, soul.name)

func add_faith(soul_id: String, amount: int) -> void:
 if named_souls.has(soul_id):
  named_souls[soul_id].faith += amount

func get_soul(soul_id: String) -> Dictionary:
 return named_souls.get(soul_id, {})

func get_all_souls() -> Array:
 return named_souls.values()

func get_souls_by_type(type: String) -> Array:
 var result = []
 for soul_id in named_souls:
  if named_souls[soul_id].type == type:
   result.append(named_souls[soul_id])
 return result

func get_total_named() -> int:
 return total_named

func get_named_count() -> int:
 return named_souls.size()

func form_pact(soul_id: String) -> Dictionary:
 if not named_souls.has(soul_id):
  return {"success": false}

 var soul = named_souls[soul_id]
 var pact_power = soul.level * soul.faith / 10

 pact_formed.emit(soul_id, pact_power)

 return {
  "success": true,
  "soul_name": soul.name,
  "pact_ability": soul.pact_ability,
  "pact_power": pact_power
 }

func get_soul_stats(soul_id: String) -> Dictionary:
 return named_souls.get(soul_id, {}).get("stats", {})

func get_soul_ability(soul_id: String) -> String:
 return named_souls.get(soul_id, {}).get("pact_ability", "")

func get_available_soul_types() -> Array:
 return soul_templates.keys()

func get_soul_template(soul_type: String) -> Dictionary:
 return soul_templates.get(soul_type, {})

func save_data() -> Dictionary:
 return {
  "named_souls": named_souls,
  "total_named": total_named,
  "fragments_collected": fragments_collected
 }

func load_data(data: Dictionary) -> void:
 named_souls = data.get("named_souls", {})
 total_named = data.get("total_named", 0)
 fragments_collected = data.get("fragments_collected", 0)
