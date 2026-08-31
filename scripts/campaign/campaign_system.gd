class_name CampaignSystem
extends RefCounted

# Stage order == map visitation order. Content fills the GDD §1 Atos.
# Act I: map 0 (Fronteira Cinzenta) - goblin + orc_chefe
# Act II: 5 Cardeais (maps 5-9) - Ignis, Zephyr, Aqua, Terra, Umbra
# Act III: maps 3, 4 (Castelo Solaris, Vulcão do Abismo) - conteúdo existente
# Act IV: 3 fases de Aurius (maps 10-12) - Fase 1, 2, 3
const ACT_STAGES: Dictionary = {
 1: [
   {"name": "Socorro aos Goblins", "map_id": 0, "boss": false},
   {"name": "O Chefe Orc", "map_id": 0, "boss": true, "final": true}
 ],
 2: [
   {"name": "Cardeal Ignis — Lava Branca", "map_id": 5, "boss": true},
   {"name": "Cardeal Zephyr — Tempestades", "map_id": 6, "boss": true},
   {"name": "Cardeal Aqua — Água Benta", "map_id": 7, "boss": true},
   {"name": "Cardeal Terra — Muralhas", "map_id": 8, "boss": true},
   {"name": "Cardeal Umbra — Sombras", "map_id": 9, "boss": true, "final": true}
 ],
 3: [
   {"name": "Castelo Solaris", "map_id": 3, "boss": false},
   {"name": "Cerne da Igreja", "map_id": 4, "boss": true, "final": true}
 ],
 4: [
   {"name": "Aurius Fase 1 — Falso Demiurgo", "map_id": 10, "boss": true},
   {"name": "Aurius Fase 2 — Serafim Tirano", "map_id": 11, "boss": true},
   {"name": "Aurius Fase 3 — Luz Desesperada", "map_id": 12, "boss": true, "final": true}
 ]
}

# Mapas de exploração que não são estágios de campanha, mas pertencem a um ato.
# Só ficam jogáveis quando o ato dono já foi concluído (conteúdo lateral).
const SIDE_MAP_ACTS: Dictionary = {
 1: 1,  # Floresta Sombria — conteúdo lateral do Ato I
 2: 3   # Caverna Profunda — conteúdo lateral do Ato III
}

var current_act: int = 1
var current_stage: int = 0
# Fim da campanha (ROADMAP #2): true após vencer o estágio final do Ato IV
# (Aurius Fase 3). Roteia o pós-vitória para o epílogo em vez do map_select.
var game_completed: bool = false

func _init() -> void:
 reset()

func reset() -> void:
 current_act = 1
 current_stage = 0
 game_completed = false

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
 else:
  # Último ato concluído: campanha acabou (Tratado do Éter e da Carne).
  game_completed = true
 current_stage = 0

func is_game_complete() -> bool:
 return game_completed

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
  return SIDE_MAP_ACTS.get(map_id, 1)

func serialize() -> Dictionary:
 return {"current_act": current_act, "current_stage": current_stage, "game_completed": game_completed}

func deserialize(data: Dictionary) -> void:
 current_act = data.get("current_act", 1)
 current_stage = data.get("current_stage", 0)
 game_completed = data.get("game_completed", false)
