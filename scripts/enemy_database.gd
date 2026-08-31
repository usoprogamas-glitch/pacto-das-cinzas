class_name EnemyDatabase
extends RefCounted

static var enemies: Dictionary = {
 "mercenario": {
  "name": "Mercenário",
  "class": "Guerreiro",
  "hp": 60,
  "atk": 14,
  "def": 10,
  "mag": 0,
  "spd": 8,
  "mov": 3,
  "rng": 1,
  "color": Color(0.7, 0.2, 0.2),
  "soul_ether": 15,
  "ai_type": "aggressive",
  "description": "Humano brutal que ataca por lucro"
 },
 "cacador": {
  "name": "Caçador",
  "class": "Arqueiro",
  "hp": 45,
  "atk": 16,
  "def": 5,
  "mag": 0,
  "spd": 12,
  "mov": 3,
  "rng": 3,
  "color": Color(0.6, 0.3, 0.3),
  "soul_ether": 12,
  "ai_type": "ranged",
  "description": "Ataca de longa distância"
 },
 "inquisidor": {
  "name": "Inquisidor",
  "class": "Mago",
  "hp": 80,
  "atk": 8,
  "def": 12,
  "mag": 25,
  "spd": 7,
  "mov": 2,
  "rng": 3,
  "color": Color(0.2, 0.3, 0.7),
  "soul_ether": 30,
  "ai_type": "caster",
  "spell": "shadow_bolt",
  "description": "Mago fanático com correntes rúnicas"
 },
 "paladino": {
  "name": "Paladino",
  "class": "Paladino",
  "hp": 150,
  "atk": 35,
  "def": 30,
  "mag": 15,
  "spd": 6,
  "mov": 2,
  "rng": 1,
  "color": Color(0.9, 0.8, 0.2),
  "soul_ether": 80,
  "ai_type": "tank",
  "description": "Elite de Solaria, fanático lavado cerebral"
 },
 "troll": {
  "name": "Troll",
  "class": "Bruto",
  "hp": 200,
  "atk": 20,
  "def": 25,
  "mag": 0,
  "spd": 4,
  "mov": 2,
  "rng": 1,
  "color": Color(0.3, 0.5, 0.2),
  "soul_ether": 25,
  "ai_type": "brute",
  "description": "Criatura massiva e resistente"
 },
 "lobo_sombrio": {
  "name": "Lobo Sombrio",
  "class": "Fera",
  "hp": 35,
  "atk": 12,
  "def": 5,
  "mag": 0,
  "spd": 15,
  "mov": 4,
  "rng": 1,
  "color": Color(0.3, 0.3, 0.4),
  "soul_ether": 8,
  "ai_type": "flanker",
  "description": "Rápido e ataca pelos flancos"
 },
 "aranha_gigante": {
  "name": "Aranha Gigante",
  "class": "Fera",
  "hp": 40,
  "atk": 10,
  "def": 3,
  "mag": 5,
  "spd": 10,
  "mov": 3,
  "rng": 2,
  "color": Color(0.2, 0.2, 0.2),
  "soul_ether": 10,
  "ai_type": "swarmer",
  "description": "Envenena e prende presas"
 },
 "esqueleto": {
  "name": "Esqueleto",
  "class": "Morto-Vivo",
  "hp": 50,
  "atk": 12,
  "def": 8,
  "mag": 10,
  "spd": 6,
  "mov": 2,
  "rng": 1,
  "color": Color(0.8, 0.8, 0.7),
  "soul_ether": 8,
  "ai_type": "zombie",
  "description": "Morto-vivo reanimado pela Igreja"
 },
 "santo_cardeal": {
  "name": "Santo Cardeal",
  "class": "Boss",
  "hp": 300,
  "atk": 50,
  "def": 40,
  "mag": 60,
  "spd": 8,
  "mov": 2,
  "rng": 3,
  "color": Color(1.0, 0.9, 0.3),
  "soul_ether": 200,
  "ai_type": "boss",
  "description": "Avatar de um deus usurpador"
 },
 "goblin_lama": {
  "name": "Goblin da Lama",
  "class": "Guerreiro",
  "hp": 60,
  "atk": 10,
  "def": 8,
  "mag": 0,
  "spd": 8,
  "mov": 2,
  "rng": 1,
  "color": Color(0.4, 0.45, 0.3),
  "soul_ether": 12,
  "ai_type": "aggressive",
  "soul_type": "goblin_lama",
  "description": "Goblin fraco da fronteira, presa facil para o Pacto"
 },
 "orc_chefe": {
  "name": "Chefe Orc",
  "class": "Bruto",
  "hp": 140,
  "atk": 18,
  "def": 16,
  "mag": 0,
  "spd": 6,
  "mov": 2,
  "rng": 1,
  "color": Color(0.45, 0.3, 0.1),
  "soul_ether": 40,
  "ai_type": "brute",
  "description": "Lider dos orcs que escraviza goblins - chefe do Ato I"
 },

 # ===== OS CINCO SANTOS CARDEAIS (GDD §5) =====

 "cardeal_ignis": {
  "name": "Ignis",
  "class": "Boss",
  "hp": 500,
  "atk": 35,
  "def": 30,
  "mag": 60,
  "spd": 8,
  "mov": 2,
  "rng": 3,
  "color": Color(1.0, 0.3, 0.1),
  "soul_ether": 200,
  "ai_type": "boss",
  "description": "Santo Cardeal do Fogo - Lava Branca"
 },

 "cardeal_zephyr": {
  "name": "Zephyr",
  "class": "Boss",
  "hp": 450,
  "atk": 40,
  "def": 20,
  "mag": 50,
  "spd": 12,
  "mov": 3,
  "rng": 4,
  "color": Color(0.3, 0.7, 1.0),
  "soul_ether": 200,
  "ai_type": "boss",
  "description": "Santo Cardeal do Vento - Tempestades de Vento"
 },

 "cardeal_aqua": {
  "name": "Aqua",
  "class": "Boss",
  "hp": 480,
  "atk": 32,
  "def": 25,
  "mag": 55,
  "spd": 7,
  "mov": 2,
  "rng": 3,
  "color": Color(0.2, 0.6, 1.0),
  "soul_ether": 200,
  "ai_type": "boss",
  "description": "Santo Cardeal da Água - Água Benta Corrosiva"
 },

 "cardeal_terra": {
  "name": "Terra",
  "class": "Boss",
  "hp": 600,
  "atk": 28,
  "def": 50,
  "mag": 40,
  "spd": 5,
  "mov": 1,
  "rng": 2,
  "color": Color(0.5, 0.4, 0.3),
  "soul_ether": 200,
  "ai_type": "boss",
  "description": "Santo Cardeal da Terra - Muralhas de Mármore"
 },

 "cardeal_umbra": {
  "name": "Umbra",
  "class": "Boss",
  "hp": 420,
  "atk": 38,
  "def": 22,
  "mag": 65,
  "spd": 10,
  "mov": 3,
  "rng": 3,
  "color": Color(0.3, 0.1, 0.5),
  "soul_ether": 200,
  "ai_type": "boss",
  "description": "Santo Cardeal das Trevas - Ilusões de Luz Negra"
 },

 # ===== AURIUS — O FALSO DEUS (3 FASES, GDD §5) =====

 "aurius_fase1": {
  "name": "Aurius — Falso Demiurgo",
  "class": "Boss",
  "hp": 800,
  "atk": 45,
  "def": 40,
  "mag": 80,
  "spd": 6,
  "mov": 2,
  "rng": 4,
  "color": Color(1.0, 0.95, 0.3),
  "soul_ether": 500,
  "ai_type": "boss",
  "description": "Aurius Fase 1: Falso Demiurgo no Trono Monumental"
 },

 "aurius_fase2": {
  "name": "Aurius — Serafim Tirano",
  "class": "Boss",
  "hp": 600,
  "atk": 55,
  "def": 30,
  "mag": 75,
  "spd": 10,
  "mov": 3,
  "rng": 4,
  "color": Color(1.0, 0.8, 0.2),
  "soul_ether": 500,
  "ai_type": "boss",
  "description": "Aurius Fase 2: Serafim Tirano com Asas Solares"
 },

 "aurius_fase3": {
  "name": "Aurius — Luz Desesperada",
  "class": "Boss",
  "hp": 500,
  "atk": 60,
  "def": 15,
  "mag": 90,
  "spd": 12,
  "mov": 3,
  "rng": 5,
  "color": Color(1.0, 1.0, 0.5),
  "soul_ether": 500,
  "ai_type": "boss",
  "description": "Aurius Fase 3: Luz Desesperada - Núcleo Instável"
 }
}

static func get_enemy(type: String) -> Dictionary:
 if enemies.has(type):
  return enemies[type]
 return {}

static func get_random_enemy_type() -> String:
 var types = enemies.keys()
 types.erase("santo_cardeal")
 return types[randi() % types.size()]

static func create_enemy_data(type: String) -> UnitData:
 var enemy = get_enemy(type)
 if enemy.is_empty():
  return null

 var data = UnitData.new()
 data.unit_name = enemy.name
 data.is_player = false
 data.unit_class = enemy.class
 data.max_hp = enemy.hp
 data.current_hp = enemy.hp
 data.attack = enemy.atk
 data.defense = enemy.def
 data.magic = enemy.mag
 data.max_mp = enemy.get("mag", 0)
 data.current_mp = enemy.get("mag", 0)
 data.spell = enemy.get("spell", "fire_bolt")
 data.speed = enemy.spd
 data.move_range = enemy.mov
 data.attack_range = enemy.rng
 data.color = enemy.color
 data.soul_ether_value = enemy.soul_ether
 data.soul_type = enemy.get("soul_type", "")
 return data
