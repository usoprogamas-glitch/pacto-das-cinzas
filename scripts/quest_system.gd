class_name QuestSystem
extends RefCounted

## Missões data-driven (SoS): estado por quest, log para o HUD (tecla J),
## notificação quando uma quest nova é registrada.

signal quest_added(quest_id: String, title: String)
signal quest_updated(quest_id: String, progress_text: String)
signal quest_completed(quest_id: String, title: String)

## Definições: objetivo em linguagem de jogador + recompensa.
const QUESTS: Dictionary = {
 "fronteira_liberdade": {
  "title": "Libertar a Fronteira Cinzenta",
  "objective": "Derrote os mercenários do Capitão Cenu e limpe a Fronteira.",
  "giver_map": 0,
  "reward_gold": 15,
 },
 "ignis_caido": {
  "title": "A Queda de Ignis",
  "objective": "Enfrente o Cardeal Ignis no Vale dos Despojos.",
  "giver_map": 5,
  "reward_gold": 40,
 },
 "provisoes_sobrevivente": {
  "title": "Provisões do Sobrevivente",
  "objective": "Ouça o sobrevivente até o fim — ele recompensa quem escuta.",
  "giver_map": 5,
  "reward_gold": 0,
 }
}

var _active: Dictionary = {}  # quest_id -> {"title", "objective", "done": bool}


## Registra/ativa uma quest (idempotente). Retorna true se era nova.
func add(quest_id: String) -> bool:
 if not QUESTS.has(quest_id) or _active.has(quest_id):
  return false
 var q: Dictionary = QUESTS[quest_id]
 _active[quest_id] = {"title": q["title"], "objective": q["objective"], "done": false}
 quest_added.emit(quest_id, String(q["title"]))
 return true


## Marca como concluída (idempotente). True se era a primeira conclusão.
func complete(quest_id: String) -> bool:
 if not _active.has(quest_id) or bool(_active[quest_id]["done"]):
  return false
 _active[quest_id]["done"] = true
 quest_completed.emit(quest_id, String(QUESTS[quest_id]["title"]))
 return true


func is_active(quest_id: String) -> bool:
 return _active.has(quest_id)


func is_completed(quest_id: String) -> bool:
 return _active.has(quest_id) and bool(_active[quest_id]["done"])


## Snapshot para o HUD do quest log.
func get_log() -> Array:
 var log := []
 for id: String in _active:
  var q: Dictionary = _active[id]
  log.append({"id": id, "title": q["title"], "objective": q["objective"], "done": q["done"]})
 return log


func get_reward_gold(quest_id: String) -> int:
 return int(QUESTS.get(quest_id, {}).get("reward_gold", 0))
