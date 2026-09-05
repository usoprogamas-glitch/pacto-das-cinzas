class_name KaelenSystem
extends RefCounted

## Interface Cognitiva de Kaelen (GDD v2 §3.4)
##
## HUD preditivo em combate que analisa entidades e fornece:
## - Vetor Biológico: Fraquezas elementais, fadiga, blindagem
## - Vetor Psicológico: Moral, propensão à fuga, devoção
## - Vetor Tático: Cooldowns, alcance, sugestões de lock
##
## Kaelen é a voz analítica do protagonista, calculando fraquezas
## e trajectories com precisão matemática.

signal target_analyzed(target_name: String, data: Dictionary)
signal suggestion_generated(suggestion: Dictionary)

## --- Vetores de Análise (GDD §3.4) ---

## Tipos de dano e suas relações de fraqueza
const DAMAGE_TYPES: Array = ["Corte", "Perfuração", "Contusão", "Éter", "Fogo", "Veneno", "Sagrado"]

## Tabela de fraquezas por tipo de inimigo (GDD §4)
## { tipo_inimigo: { tipo_dano: bonus_percent } }
const WEAKNESS_TABLE: Dictionary = {
 "Goblin": {"Corte": 25, "Fogo": 40},
 "Orc": {"Perfuração": 30, "Éter": 20},
 "Harpias": {"Fogo": 50, "Sagrado": 35},
 "Lobo": {"Fogo": 45, "Contusão": 25},
 "Paladino": {"Éter": 40, "Veneno": 30},
 "Inquisidor": {"Corte": 35, "Veneno": 25},
 "Golem": {"Perfuração": 40, "Éter": 30},
 "Dríade Selvagem": {"Fogo": 55, "Corte": 20},
 "Cardeal": {"Éter": 60, "Sagrado": -30},  ## Cardeais resistem a Sagrado
 "Aurius": {"Éter": 80},  ## Fraqueza final do boss
}

## Níveis de moral (GDD §3.4 - Vetor Psicológico)
enum MoraleLevel { ALTA, MEDIA, BAIXA, QUEBRADA }

## Níveis de fadiga (GDD §3.4 - Vetor Biológico)
enum FatigueLevel { DESCANSADO, LEVE, MODERADA, CRITICA }


## Analisa um alvo inimigo e retorna os três vetores.
## target_data = { "name": String, "type": String, "hp": int, "max_hp": int,
##                  "armor": int, "morale": int, "attack_range": int,
##                  "locks": Array, "spell_counter": int }
func analyze_target(target_data: Dictionary) -> Dictionary:
 var result := {
  "biological": _analyze_biological(target_data),
  "psychological": _analyze_psychological(target_data),
  "tactical": _analyze_tactical(target_data),
  "suggestions": _generate_suggestions(target_data),
 }
 target_analyzed.emit(target_data.get("name", ""), result)
 return result


## Vetor Biológico: fraquezas, fadiga, armadura
func _analyze_biological(data: Dictionary) -> Dictionary:
 var weaknesses: Array = []
 var enemy_type: String = data.get("type", "")
 var matched_type := match_weakness_type(enemy_type)
 if matched_type != "":
  for dmg_type in WEAKNESS_TABLE[matched_type]:
   var bonus: int = WEAKNESS_TABLE[matched_type][dmg_type]
   if bonus > 0:
    weaknesses.append({"type": dmg_type, "bonus_percent": bonus})

 var hp_ratio: float = float(data.get("hp", 1)) / float(data.get("max_hp", 1))
 var fatigue: FatigueLevel
 if hp_ratio > 0.75:
  fatigue = FatigueLevel.DESCANSADO
 elif hp_ratio > 0.5:
  fatigue = FatigueLevel.LEVE
 elif hp_ratio > 0.25:
  fatigue = FatigueLevel.MODERADA
 else:
  fatigue = FatigueLevel.CRITICA

 return {
  "weaknesses": weaknesses,
  "fatigue": fatigue,
  "armor": data.get("armor", 0),
 }


## Vetor Psicológico: moral, fuga, devoção
func _analyze_psychological(data: Dictionary) -> Dictionary:
 var morale_val: int = data.get("morale", 50)
 var morale: MoraleLevel
 if morale_val >= 75:
  morale = MoraleLevel.ALTA
 elif morale_val >= 50:
  morale = MoraleLevel.MEDIA
 elif morale_val >= 25:
  morale = MoraleLevel.BAIXA
 else:
  morale = MoraleLevel.QUEBRADA

 var flee_chance: float = 0.0
 if morale == MoraleLevel.QUEBRADA:
  flee_chance = 0.6
 elif morale == MoraleLevel.BAIXA:
  flee_chance = 0.3
 elif morale == MoraleLevel.MEDIA:
  flee_chance = 0.1

 return {
  "morale": morale,
  "morale_value": morale_val,
  "flee_chance": flee_chance,
  "devotion_to_aurius": morale_val,  ## Simplificação: moral = devoção
 }


## Vetor Tático: cooldowns, alcance, ameaça
func _analyze_tactical(data: Dictionary) -> Dictionary:
 var has_locks: bool = not data.get("locks", []).is_empty()
 var spell_counter: int = data.get("spell_counter", 0)
 var attack_range: int = data.get("attack_range", 1)
 var threat_level: String = "BAIXA"
 if has_locks and spell_counter <= 2:
  threat_level = "CRÍTICA"
 elif has_locks:
  threat_level = "ALTA"
 elif attack_range >= 3:
  threat_level = "MÉDIA"

 return {
  "has_locks": has_locks,
  "spell_counter": spell_counter,
  "attack_range": attack_range,
  "threat_level": threat_level,
 }


## Gera sugestões táticas para quebra de locks (GDD §3.4)
func _generate_suggestions(data: Dictionary) -> Array:
 var suggestions: Array = []
 var locks: Array = data.get("locks", [])

 for lock in locks:
  var lock_type: String = lock.get("type", "")
  var remaining: int = lock.get("remaining", 0)
  suggestions.append({
   "lock_type": lock_type,
   "hits_needed": remaining,
   "suggestion": _get_lock_suggestion(lock_type),
   "urgency": "ALTA" if data.get("spell_counter", 0) <= 2 else "MÉDIA",
  })

 if suggestions.size() > 0:
  suggestion_generated.emit({
   "target": data.get("name", ""),
   "suggestions": suggestions,
  })

 return suggestions


## Retorna a sugestão para quebrar um tipo de lock
func _get_lock_suggestion(lock_type: String) -> String:
 match lock_type:
  "Corte":
   return "Use Thal'kor (Corte) para quebrar este lock"
  "Perfuração":
   return "Use Garm (Perfuração) para quebrar este lock"
  "Contusão":
   return "Use Kroug (Contusão) para quebrar este lock"
  "Éter":
   return "Use Querubim (Éter) para quebrar este lock"
  "Fogo":
   return "Use habilidades de fogo para quebrar este lock"
  "Veneno":
   return "Use Lira (Veneno) para quebrar este lock"
  "Sagrado":
   return "Use dano sagrado para quebrar este lock"
  _:
   return "Use o tipo de dano " + lock_type + " para quebrar este lock"


## Analisa um monstro selvagem para nomeação (Holograma Preditivo)
## Retorna dados para a UI de nomeação
func analyze_wild_monster(monster_data: Dictionary) -> Dictionary:
 var monster_type: String = monster_data.get("type", "")
 var evolution_path: Array = []

 return {
  "name": monster_data.get("name", "Desconhecido"),
  "type": monster_type,
  "evolution_path": evolution_path,
  "mana_cost": monster_data.get("mana_cost", 100),
  "stat_preview": monster_data.get("base_stats", {}),
 }


## Retorna fraquezas de um tipo de inimigo (para exibição)
func get_weaknesses(enemy_type: String) -> Array:
 var matched_type := match_weakness_type(enemy_type)
 if matched_type == "":
  return []
 var weaknesses: Array = []
 for dmg_type in WEAKNESS_TABLE[matched_type]:
  var bonus: int = WEAKNESS_TABLE[matched_type][dmg_type]
  if bonus > 0:
   weaknesses.append({"type": dmg_type, "bonus_percent": bonus})
 return weaknesses

## Casa o tipo/name de um inimigo com uma chave da WEAKNESS_TABLE.
## Prioridade: 1) igualdade; 2) palavra do arquétipo contida no nome
## ("Lobo Sombrio" → "Lobo", "Santo Cardeal" → "Cardeal", "Chefe Orc" → "Orc").
## Retorna "" se não houver entrada.
func match_weakness_type(enemy_type: String) -> String:
 if WEAKNESS_TABLE.has(enemy_type):
  return enemy_type
 var lower := enemy_type.to_lower()
 for archetype in WEAKNESS_TABLE.keys():
  if lower.begins_with(archetype.to_lower()) or lower.contains(archetype.to_lower()):
   return archetype
 return ""


## Retorna o nível de moral como string legível
func get_morale_name(level: MoraleLevel) -> String:
 match level:
  MoraleLevel.ALTA: return "Alta"
  MoraleLevel.MEDIA: return "Média"
  MoraleLevel.BAIXA: return "Baixa"
  MoraleLevel.QUEBRADA: return "Quebrada"
 return "Desconhecida"


## Retorna o nível de fadiga como string legível
func get_fatigue_name(level: FatigueLevel) -> String:
 match level:
  FatigueLevel.DESCANSADO: return "Descansado"
  FatigueLevel.LEVE: return "Leve"
  FatigueLevel.MODERADA: return "Moderada"
  FatigueLevel.CRITICA: return "Crítica"
 return "Desconhecida"
