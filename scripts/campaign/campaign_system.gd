class_name CampaignSystem
extends RefCounted

# Stage order == map visitation order. Acts II–IV are THIN entries that reuse maps 1–4
# to prove the "new act unlocks new map/enemies" fan-out; content fills later.
const ACT_STAGES: Dictionary = {
 1: [
  {"name": "Socorro aos Goblins", "map_id": 0, "boss": false},
  {"name": "O Chefe Orc", "map_id": 0, "boss": true, "final": true}
 ],
 2: [{"name": "Floresta Sombria", "map_id": 1, "boss": false},
     {"name": "Vale dos Despojos", "map_id": 2, "boss": true, "final": true}],
 3: [{"name": "Castelo Solaris", "map_id": 3, "boss": false},
     {"name": "Cerne da Igreja", "map_id": 4, "boss": true, "final": true}],
 4: [{"name": "Caminho de Aurius", "map_id": 4, "boss": true, "final": true}]
}

var current_act: int = 1
var current_stage: int = 0

func _init() -> void:
 reset()

func reset() -> void:
 current_act = 1
 current_stage = 0

func get_current_stage() -> Dictionary:
 var list: Array = ACT_STAGES.get(current_act, [])
 return list[current_stage] if current_stage < list.size() else {}

func is_act_boss_stage() -> bool:
 return get_current_stage().get("boss", false)

func advance_stage() -> void:
 var list: Array = ACT_STAGES.get(current_act, [])
 if current_stage < list.size() - 1:
  current_stage += 1

func complete_act() -> void:
 if current_act < 4:
  current_act += 1
 current_stage = 0

func is_stage_playable(map_id: int) -> bool:
 # A map is playable if:
 # - it belongs to a completed act (act < current_act), OR
 # - it belongs to the current act AND is the current stage's map.
 var map_act = act_for_map(map_id)
 if map_act < current_act:
  return true
 if map_act == current_act:
  var stage = get_current_stage()
  return stage.get("map_id", -1) == map_id
 return false

# Ato dono do mapa (1ª aparição em ACT_STAGES). Fonte única de verdade para
# map_select exibir o badge de ato sem duplicar a tabela hardcoded.
func act_for_map(map_id: int) -> int:
 for act in ACT_STAGES.keys():
  for stage in ACT_STAGES[act]:
   if stage.map_id == map_id:
    return act
 return 1

func serialize() -> Dictionary:
 return {"current_act": current_act, "current_stage": current_stage}

func deserialize(data: Dictionary) -> void:
 current_act = data.get("current_act", 1)
 current_stage = data.get("current_stage", 0)
