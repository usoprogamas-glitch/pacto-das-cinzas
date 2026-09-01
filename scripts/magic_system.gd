class_name MagicSystem
extends Node

signal spell_cast(caster: Unit, spell: Dictionary, targets: Array)
signal element_applied(target: Unit, element: String, duration: int)

enum Element { NONE, FIRE, WATER, EARTH, AIR, SHADOW, LIGHT }

var elements: Dictionary = {
 Element.FIRE: {
  "name": "Fogo",
  "color": "#FF4500",
  "strength": Element.EARTH,
  "weakness": Element.WATER,
  "status_effect": "Burning",
  "status_damage": 5
 },
 Element.WATER: {
  "name": "Água",
  "color": "#1E90FF",
  "strength": Element.FIRE,
  "weakness": Element.EARTH,
  "status_effect": "Wet",
  "status_damage": 0
 },
 Element.EARTH: {
  "name": "Terra",
  "color": "#8B4513",
  "strength": Element.AIR,
  "weakness": Element.FIRE,
  "status_effect": "Rooted",
  "status_damage": 0
 },
 Element.AIR: {
  "name": "Ar",
  "color": "#87CEEB",
  "strength": Element.WATER,
  "weakness": Element.EARTH,
  "status_effect": "Exposed",
  "status_damage": 0
 },
 Element.SHADOW: {
  "name": "Sombra",
  "color": "#4B0082",
  "strength": Element.LIGHT,
  "weakness": Element.LIGHT,
  "status_effect": "Cursed",
  "status_damage": 3
 },
 Element.LIGHT: {
  "name": "Luz",
  "color": "#FFD700",
  "strength": Element.SHADOW,
  "weakness": Element.SHADOW,
  "status_effect": "Purified",
  "status_damage": 0
 }
}

var spells: Dictionary = {
 "fire_bolt": {
  "name": "Projétil de Fogo",
  "element": Element.FIRE,
  "mp_cost": 10,
  "power": 25,
  "range": 3,
  "aoe": false,
  "locks": [{"type": "Corte", "hits": 2}],
  "cast_turns": 2,
  "description": "Dispara uma bola de fogo"
 },
 "fire_blast": {
  "name": "Explosão de Fogo",
  "element": Element.FIRE,
  "mp_cost": 25,
  "power": 40,
  "range": 2,
  "aoe": true,
  "aoe_size": 2,
  "locks": [{"type": "Contusão", "hits": 3}],
  "cast_turns": 3,
  "description": "Explosão em área"
 },
 "water_splash": {
  "name": "Splash d'Água",
  "element": Element.WATER,
  "mp_cost": 8,
  "power": 20,
  "range": 3,
  "aoe": false,
  "description": "Jato de água"
 },
 "heal_wave": {
  "name": "Onda Curativa",
  "element": Element.WATER,
  "mp_cost": 15,
  "power": 30,
  "range": 2,
  "aoe": true,
  "heal": true,
  "description": "Cura aliados em área"
 },
 "stone_spike": {
  "name": "Espinho de Pedra",
  "element": Element.EARTH,
  "mp_cost": 12,
  "power": 30,
  "range": 2,
  "aoe": false,
  "description": "Espinho de pedra sobe do chão"
 },
 "earth_wall": {
  "name": "Muralha de Terra",
  "element": Element.EARTH,
  "mp_cost": 20,
  "power": 0,
  "range": 1,
  "aoe": true,
  "defense_buff": 20,
  "duration": 3,
  "description": "Cria barreira defensiva"
 },
 "wind_slash": {
  "name": "Lâmina de Vento",
  "element": Element.AIR,
  "mp_cost": 10,
  "power": 22,
  "range": 4,
  "aoe": false,
  "description": "Corte de vento afiado"
 },
 "gust_push": {
  "name": "Rajada Empurradora",
  "element": Element.AIR,
  "mp_cost": 15,
  "power": 15,
  "range": 2,
  "aoe": true,
  "push": 2,
  "description": "Empurra inimigos"
 },
 "shadow_bolt": {
  "name": "Projétil Sombrio",
  "element": Element.SHADOW,
  "mp_cost": 12,
  "power": 28,
  "range": 3,
  "aoe": false,
  "locks": [{"type": "Perfuração", "hits": 2}],
  "cast_turns": 2,
  "description": "Bola de energia sombria"
 },
 "darkness_cloud": {
  "name": "Nuvem de Escuridão",
  "element": Element.SHADOW,
  "mp_cost": 20,
  "power": 15,
  "range": 2,
  "aoe": true,
  "aoe_size": 3,
  "blind": true,
  "description": "Reduz precisão dos inimigos"
 },
 "holy_smite": {
  "name": "Golpe Sagrado",
  "element": Element.LIGHT,
  "mp_cost": 18,
  "power": 35,
  "range": 2,
  "aoe": false,
  "extra_damage_undead": 1.5,
  "locks": [{"type": "Éter", "hits": 3}],
  "cast_turns": 3,
  "description": "Dano extra contra mortos-vivos"
 },
 "purify": {
  "name": "Purificar",
  "element": Element.LIGHT,
  "mp_cost": 10,
  "power": 0,
  "range": 3,
  "aoe": false,
  "cleanse": true,
  "description": "Remove debuffs"
 }
}

func get_spell(spell_id: String) -> Dictionary:
 if spells.has(spell_id):
  return spells[spell_id]
 return {}

func get_spells_for_element(element: Element) -> Array:
 var result = []
 for spell_id in spells:
  if spells[spell_id].element == element:
   result.append({"id": spell_id, "spell": spells[spell_id]})
 return result

func get_spells_for_unit(unit: Unit) -> Array:
 # Por enquanto, todos os apóstolos têm acesso a todas as magias
 # Em implementação futura, filtrar por classe e nível
 return spells.keys()

func calculate_spell_damage(spell: Dictionary, caster: Unit, target: Unit) -> int:
 var base_power = spell.power
 var magic_bonus = caster.data.magic
 var element = spell.element

 # Bônus de elemento
 var target_element = get_unit_element(target)
 if target_element != Element.NONE:
  var element_data = elements[element]
  if element_data.strength == target_element:
   base_power = int(base_power * 1.5) # Super efetivo
  elif element_data.weakness == target_element:
   base_power = int(base_power * 0.5) # Resistente

 var damage = base_power + magic_bonus
 var variation = randf_range(0.9, 1.1)
 return int(damage * variation)

func get_element_effectiveness(attacker_element: Element, defender_element: Element) -> float:
 if attacker_element == Element.NONE or defender_element == Element.NONE:
  return 1.0

 var element_data = elements[attacker_element]
 if element_data.strength == defender_element:
  return 1.5
 elif element_data.weakness == defender_element:
  return 0.5
 return 1.0

func apply_status_effect(target: Unit, spell: Dictionary) -> void:
 var element = spell.element
 if element == Element.NONE:
  return

 var element_data = elements[element]
 var effect = {
  "name": element_data.status_effect,
  "damage": element_data.status_damage,
  "duration": 3
 }
 element_applied.emit(target, element_data.status_effect, 3)

func get_unit_element(unit: Unit) -> Element:
 # Determina elemento baseado na classe
 match unit.data.unit_class:
  "Guerreiro", "Paladino":
   return Element.LIGHT
  "Mago", "Inquisidor":
   return Element.SHADOW
  "Arqueiro":
   return Element.AIR
  "Goblin", "Ogro":
   return Element.EARTH
  "Dríade", "Sacerdotisa":
   return Element.WATER
  _:
   return Element.NONE

func cast_spell(caster: Unit, spell_id: String, targets: Array) -> Dictionary:
 var spell = get_spell(spell_id)
 if spell.is_empty():
  return {"success": false, "reason": "spell_not_found"}

 if caster.current_mp < spell.mp_cost:
  return {"success": false, "reason": "not_enough_mp"}

 caster.current_mp -= spell.mp_cost

 var results = []
 for target in targets:
  if spell.get("heal", false):
   var heal_amount = calculate_spell_damage(spell, caster, target)
   target.heal(heal_amount)
   results.append({"target": target, "heal": heal_amount})
  else:
   var damage = calculate_spell_damage(spell, caster, target)
   target.take_damage(damage)
   apply_status_effect(target, spell)
   results.append({"target": target, "damage": damage})

 spell_cast.emit(caster, spell, targets)
 return {"success": true, "results": results}
