class_name MaterialDatabase
extends RefCounted

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

static var materials: Dictionary = {
 # === COMUM ===
 "osso_velho": {
  "id": "osso_velho",
  "name": "Osso Velho",
  "rarity": Rarity.COMMON,
  "description": "Osso quebrado de criatura fraca",
  "drop_source": ["esqueleto", "lobo_sombrio"],
  "drop_chance": 0.5,
  "icon_color": "#CCCCCC"
 },
 "pele_grudenta": {
  "id": "pele_grudenta",
  "name": "Pele Grudenta",
  "rarity": Rarity.COMMON,
  "description": "Pele pegajosa de aranha",
  "drop_source": ["aranha_gigante"],
  "drop_chance": 0.6,
  "icon_color": "#4A4A4A"
 },
  "lama_escura": {
   "id": "lama_escura",
  "name": "Lama Escura",
  "rarity": Rarity.COMMON,
  "description": "Lama coletada de pântanos",
  "drop_source": ["troll", "goblin"],
  "drop_chance": 0.4,
  "icon_color": "#3A2A1A"
 },
 "fragmento_pedra": {
  "id": "fragmento_pedra",
  "name": "Fragmento de Pedra",
  "rarity": Rarity.COMMON,
  "description": "Pedra comum encontrada em ruínas",
  "drop_source": ["troll", "mercenario"],
  "drop_chance": 0.5,
  "icon_color": "#6A6A6A"
 },
 "fibra_resistente": {
  "id": "fibra_resistente",
  "name": "Fibra Resistente",
  "rarity": Rarity.COMMON,
  "description": "Fibra vegetal forte",
  "drop_source": ["lobo_sombrio", "aranha_gigante"],
  "drop_chance": 0.4,
  "icon_color": "#5A7A5A"
 },

 # === INCOMUM ===
 "presa_sombria": {
  "id": "presa_sombria",
  "name": "Presa Sombria",
  "rarity": Rarity.UNCOMMON,
  "description": "Presa carregada de energia sombria",
  "drop_source": ["lobo_sombrio"],
  "drop_chance": 0.3,
  "icon_color": "#4B0082"
 },
 "couro_reforcado": {
  "id": "couro_reforcado",
  "name": "Couro Reforçado",
  "rarity": Rarity.UNCOMMON,
  "description": "Couro tratado para armaduras",
  "drop_source": ["mercenario", "cacador"],
  "drop_chance": 0.25,
  "icon_color": "#8B4513"
 },
 "cristal_maná": {
  "id": "cristal_mana",
  "name": "Cristal de Maná",
  "rarity": Rarity.UNCOMMON,
  "description": "Cristal que armazena energia mágica",
  "drop_source": ["inquisidor"],
  "drop_chance": 0.2,
  "icon_color": "#9370DB"
 },
 "garras_afiadas": {
  "id": "garras_afiadas",
  "name": "Garras Afiadas",
  "rarity": Rarity.UNCOMMON,
  "description": "Garras cortantes de fera",
  "drop_source": ["aranha_gigante", "lobo_sombrio"],
  "drop_chance": 0.25,
  "icon_color": "#8B0000"
 },
 "amuleto_fendido": {
  "id": "amuleto_fendido",
  "name": "Amuleto Fendido",
  "rarity": Rarity.UNCOMMON,
  "description": "Amuleto sagrado quebrado",
  "drop_source": ["paladino"],
  "drop_chance": 0.15,
  "icon_color": "#FFD700"
 },

 # === RARO ===
 "essencia_elemental": {
  "id": "essencia_elemental",
  "name": "Essência Elemental",
  "rarity": Rarity.RARE,
  "description": "Essência pura de um elemento",
  "drop_source": ["inquisidor", "paladino"],
  "drop_chance": 0.1,
  "icon_color": "#FF4500"
 },
  "lamina_corrompida": {
   "id": "lamina_corrompida",
  "name": "Lâmina Corrompida",
  "rarity": Rarity.RARE,
  "description": "Espada infectada por magia sombria",
  "drop_source": ["paladino"],
  "drop_chance": 0.08,
  "icon_color": "#8B008B"
 },
 "medalhao_divino": {
  "id": "medalhao_divino",
  "name": "Medalhão Divino",
  "rarity": Rarity.RARE,
  "description": "Relíquia de um deus caído",
  "drop_source": ["santo_cardeal"],
  "drop_chance": 0.05,
  "icon_color": "#FFFFAA"
 },

 # === ÉPICO ===
 "coracao_vulcanico": {
  "id": "coracao_vulcanico",
  "name": "Coração Vulcânico",
  "rarity": Rarity.EPIC,
  "description": "Núcleo de magma solidificado",
  "drop_source": ["troll"],
  "drop_chance": 0.05,
  "icon_color": "#FF6600"
 },
 "olho_celestial": {
  "id": "olho_celestial",
  "name": "Olho Celestial",
  "rarity": Rarity.EPIC,
  "description": "Olho de anjo corrompido",
  "drop_source": ["santo_cardeal"],
  "drop_chance": 0.03,
  "icon_color": "#00E5FF"
 },

 # === LENDÁRIO ===
 "fragmento_deus": {
  "id": "fragmento_deus",
  "name": "Fragmento do Deus",
  "rarity": Rarity.LEGENDARY,
  "description": "Pedaço da essência divina perdida",
  "drop_source": ["boss_final"],
  "drop_chance": 1.0,
  "icon_color": "#FFFFFF"
 }
}

static func get_material(material_id: String) -> Dictionary:
 if materials.has(material_id):
  return materials[material_id]
 return {}

static func get_materials_by_rarity(rarity: Rarity) -> Array:
 var result = []
 for mat_id in materials:
  if materials[mat_id].rarity == rarity:
   result.append(materials[mat_id])
 return result

static func get_drop_table(enemy_type: String) -> Array:
 var drops = []
 for mat_id in materials:
  var mat = materials[mat_id]
  if enemy_type in mat.drop_source:
   drops.append({
    "material": mat,
    "chance": mat.drop_chance
   })
 return drops

static func roll_drop(enemy_type: String) -> Array:
 var drops = []
 var table = get_drop_table(enemy_type)

 for entry in table:
  if randf() <= entry.chance:
   drops.append(entry.material.id)

 return drops

static func get_rarity_name(rarity: Rarity) -> String:
 match rarity:
  Rarity.COMMON: return "Comum"
  Rarity.UNCOMMON: return "Incomum"
  Rarity.RARE: return "Raro"
  Rarity.EPIC: return "Épico"
  Rarity.LEGENDARY: return "Lendário"
 return "Desconhecido"

static func get_rarity_color(rarity: Rarity) -> Color:
 match rarity:
  Rarity.COMMON: return Color("#CCCCCC")
  Rarity.UNCOMMON: return Color("#1EFF00")
  Rarity.RARE: return Color("#0070FF")
  Rarity.EPIC: return Color("#A335EE")
  Rarity.LEGENDARY: return Color("#FF8000")
 return Color.WHITE
