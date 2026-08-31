class_name CampfireSystem
extends RefCounted

## Sistema de Acampamento da Party — Campfire (GDD v2 §7.1)
##
## Pontos de descanso onde o grupo restaura HP e Mana.
## Árvores de diálogo que aprofundam vínculos com apóstolos.

signal rest_completed(healed_units: Array)
signal dialogue_started(apostle_name: String, dialogue_id: String)
signal bond_level_changed(apostle_name: String, new_level: int)

## --- Configuração do campfire ---
const CAMPFIRE_CONFIG: Dictionary = {
 "hp_regen_percent": 50,  ## Restaura 50% do HP perdido
 "mp_regen_percent": 100,  ## Restaura 100% do MP
 "bond_points_per_rest": 5,  ## Pontos de vínculo por descanso
 "max_bond_level": 10,  ## Nível máximo de vínculo
 "dialogues_per_rest": 1,  ## Diálogos disponíveis por descanso
}

## --- Diálogos por apóstolo e nível de vínculo ---
const APOSTLE_DIALOGUES: Dictionary = {
 "Kroug": {
  1: [
   {"id": "kroug_1_1", "title": "Primeiro contato", "text": "Kroug observa as chamas em silêncio..."},
   {"id": "kroug_1_2", "title": "Lembranças da lama", "text": "Kroug conta sobre os pântanos..."},
  ],
  3: [
   {"id": "kroug_3_1", "title": "O peso do nome", "text": "Kroug fala sobre significado de ter um nome..."},
  ],
  5: [
   {"id": "kroug_5_1", "title": "Juramento de ferro", "text": "Kroug jura proteger o Querubim..."},
  ],
 },
 "Lira": {
  1: [
   {"id": "lira_1_1", "title": "Sussurros da floresta", "text": "Lira sussurra canções antigas..."},
  ],
  3: [
   {"id": "lira_3_1", "title": "O jardim interior", "text": "Lira descreve o mundo que vê..."},
  ],
 },
 "Thal'kor": {
  1: [
   {"id": "thal_1_1", "title": "Olhar de corvo", "text": "Thal'kor observa das sombras..."},
  ],
  3: [
   {"id": "thal_3_1", "title": "Asas quebradas", "text": "Thal'kor fala sobre voo e liberdade..."},
  ],
 },
}

## --- Estado do sistema ---
var _current_campfire_id: String = ""
var _apostle_bonds: Dictionary = {}  ## {apostle_name: {level: int, points: int}}
var _rests_count: int = 0
var _used_dialogues: Array[String] = []


## --- Inicialização ---

## Registrar apóstolo para sistema de vínculos.
func register_apostle(apostle_name: String) -> void:
 if not _apostle_bonds.has(apostle_name):
  _apostle_bonds[apostle_name] = {"level": 1, "points": 0}


## --- Acampar ---

## Acampar no local (restaurar HP/MP, ganhar vínculos).
func rest_at_campfire(campfire_id: String, party: Array) -> Dictionary:
 _current_campfire_id = campfire_id
 _rests_count += 1

 var healed = []
 for unit in party:
  if unit.has_method("heal") and unit.has_method("get_speed"):
   var max_hp = unit.data.max_hp if unit.data else 100
   var max_mp = unit.data.max_mp if unit.data else 50
   var current_hp = unit.current_hp if "current_hp" in unit else 0
   var current_mp = unit.current_mp if "current_mp" in unit else 0

   ## Calcular restauração
   var hp_to_restore = int((max_hp - current_hp) * CAMPFIRE_CONFIG.hp_regen_percent / 100.0)
   var mp_to_restore = max_mp - current_mp  ## MP恢复100%

   if hp_to_restore > 0:
    unit.heal(hp_to_restore)
   if mp_to_restore > 0 and "current_mp" in unit:
    unit.current_mp = max_mp

   healed.append(unit.name)

 ## Ganhar pontos de vínculo para todos os apóstolos
 for apostle_name in _apostle_bonds:
  _add_bond_points(apostle_name, CAMPFIRE_CONFIG.bond_points_per_rest)

 _used_dialogues.clear()
 rest_completed.emit(healed)

 return {"healed": healed, "bond_points_gained": CAMPFIRE_CONFIG.bond_points_per_rest}


## --- Diálogos ---

## Obter diálogos disponíveis para um apóstolo.
func get_available_dialogues(apostle_name: String) -> Array:
 if not _apostle_bonds.has(apostle_name):
  return []

 var bond = _apostle_bonds[apostle_name]
 var dialogues = []

 ## Coletar diálogos de todos os níveis ≤ nível atual do vínculo
 for level in APOSTLE_DIALOGUES.get(apostle_name, {}):
  if level <= bond.level:
   for dialogue in APOSTLE_DIALOGUES[apostle_name][level]:
    if not dialogue.id in _used_dialogues:
     dialogues.append(dialogue)

 return dialogues


## Iniciar diálogo com apóstolo.
func start_dialogue(apostle_name: String, dialogue_id: String) -> Dictionary:
 var dialogues = get_available_dialogues(apostle_name)
 for dialogue in dialogues:
  if dialogue.id == dialogue_id:
   _used_dialogues.append(dialogue_id)
   dialogue_started.emit(apostle_name, dialogue_id)
   return dialogue
 return {}


## --- Sistema de vínculo ---

func _add_bond_points(apostle_name: String, points: int) -> void:
 if not _apostle_bonds.has(apostle_name):
  return

 var bond = _apostle_bonds[apostle_name]
 bond.points += points

 ## Verificar level up
 var points_needed = bond.level * 20  ## 20, 40, 60, ...
 if bond.points >= points_needed and bond.level < CAMPFIRE_CONFIG.max_bond_level:
  bond.level += 1
  bond_level_changed.emit(apostle_name, bond.level)


## --- Getters ---

func get_bond(apostle_name: String) -> Dictionary:
 return _apostle_bonds.get(apostle_name, {"level": 0, "points": 0})

func get_bond_level(apostle_name: String) -> int:
 return _apostle_bonds.get(apostle_name, {}).get("level", 0)

func get_all_bonds() -> Dictionary:
 return _apostle_bonds

func get_rests_count() -> int:
 return _rests_count

func get_config() -> Dictionary:
 return CAMPFIRE_CONFIG
