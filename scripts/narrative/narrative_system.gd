class_name NarrativeSystem
extends Node

signal act_started(act_number: int, act_name: String)
signal event_triggered(event_id: String)
signal protagonist_evolved(new_form: String)
signal memory_recovered(memory_id: String)
signal kaelen_spoke(message: String)

enum ProtagonistForm { IMP_MENOR, NOBRE_ABISSAL, ARQUIDEMONIO, AVATAR_PRIMORDIAL }

var current_act: int = 1
var current_form: ProtagonistForm = ProtagonistForm.IMP_MENOR
var memories_recovered: Array[String] = []
var fragments_collected: int = 0

var acts: Dictionary = {
 1: {
  "name": "Sussurros na Escuridão",
  "description": "O protagonista desperta na Fronteira Cinzenta. Sobrevivência e primeiros aliados.",
  "events": ["evt_despertar", "evt_salvar_goblins", "evt_primeiro_nome", "evt_ataque_mercenarios"],
  "form_unlocked": ProtagonistForm.IMP_MENOR,
  "memories": ["mem_silhueta_antiga", "mem_voz_kaelen"]
 },
 2: {
  "name": "O Trono de Barro e Sangue",
  "description": "A vila cresce. Novas raças se unem. Inquisidores descobrem o reino.",
  "events": ["evt_crescimento_vila", "evt_invasao_inquisidores", "evt_diplomatas_humanos", "evt_forma_nobre"],
  "form_unlocked": ProtagonistForm.NOBRE_ABISSAL,
  "memories": ["mem_batalha_antiga", "mem_traição_deuses"]
 },
 3: {
  "name": "A Cruzada de Fogo",
  "description": "Guerra total. Aurius envia Paladinos e Cardeais. A cidade é danificada.",
  "events": ["evt_cruzada_aurius", "evt_batalha_cardeais", "evt_cidade_danificada", "evt_marcha_solaria"],
  "form_unlocked": ProtagonistForm.ARQUIDEMONIO,
  "memories": ["mem_traicao_completa", "mem_amor_nacao"]
 },
 4: {
  "name": "A Guerra dos Deuses",
  "description": "Invasão final. Confronto com Aurius. O Pacto das Cinzas.",
  "events": ["evt_invasao_solaria", "evt_confronto_final", "evt_aceitar_kaelen", "evt_pacto_cinzas"],
  "form_unlocked": ProtagonistForm.AVATAR_PRIMORDIAL,
  "memories": ["mem_verdade_kaelen", "mem_paz_divina"]
 }
}

var characters: Dictionary = {
 "protagonista": {
  "name": "Sem Nome (Imp Menor)",
  "true_name": "O Deus Primordial",
  "form": "Imp Menor",
  "description": "Silencioso, estratégico e inicialmente compassivo",
  "arc": "De imp frágil a Avatar Primordial"
 },
 "kaelen": {
  "name": "Kaelen",
  "title": "A Voz do Mundo",
  "description": "Inteligência artificial divina. Frio, calculista e protetor",
  "secret": "Último resquício da racionalidade do antigo Deus",
  "mission": "Garantir que o protagonista não enlouqueça"
 },
 "kroug": {
  "name": "Kroug",
  "title": "O Escudo",
  "description": "Primeiro monstro salvo. Braço direito militarmente",
  "evolution": "Goblin da Lama → Rei Ogro de Fogo",
  "personality": "Leal, corajoso, protetor"
 },
 "lira": {
  "name": "Lira",
  "title": "A Sacerdotisa",
  "description": "Rainha Ent Primordial. Controla vida orgânica",
  "evolution": "Muda Mágica → Dríade Poderosa",
  "role": "Curandeira e camuflagem do vilarejo"
 },
 "thalkor": {
  "name": "Thal'kor",
  "title": "A Lâmina Cega",
  "description": "Anjo corrompido. Mestre espião e líder aéreo",
  "evolution": "Anjo Caído → Serafim Negro",
  "personality": "Cínico, com código moral oculto"
 }
}

var antagonists: Dictionary = {
 "aurius": {
  "name": "Aurius",
  "title": "O Falso Deus da Luz",
  "description": "Orquestrador da traição primordial",
  "secret": "Consome almas dos devotos para manter imortalidade",
  "final_boss": true
 },
 "santos_cardeais": {
  "name": "Santos Cardeais",
  "description": "Cinco humanos com avatares dos deuses usurpadores",
  "count": 5,
  "bosses": true
 },
 "paladinos": {
  "name": "Paladinos da Alvorada",
  "description": "Elite de Solaria. Vítimas de lavagem cerebral",
  "elite": true
 },
 "inquisidores": {
  "name": "Inquisidores de Aço",
  "description": "Magos táticos com correntes rúnicas anti-magia",
  "anti_magic": true
 }
}

func _ready() -> void:
 pass

func start_act(act_number: int) -> void:
 if acts.has(act_number):
  current_act = act_number
  var act = acts[act_number]
  act_started.emit(act_number, act.name)

  for event_id in act.events:
   trigger_event(event_id)

  for memory_id in act.memories:
   recover_memory(memory_id)

func trigger_event(event_id: String) -> void:
 event_triggered.emit(event_id)

func recover_memory(memory_id: String) -> void:
 if memory_id not in memories_recovered:
  memories_recovered.append(memory_id)
  memory_recovered.emit(memory_id)

func collect_fragment() -> void:
 fragments_collected += 1
 check_evolution()

func check_evolution() -> void:
 var new_form = get_form_for_fragments()
 if new_form != current_form:
  current_form = new_form
  protagonist_evolved.emit(get_form_name(new_form))

func get_form_for_fragments() -> ProtagonistForm:
 if fragments_collected >= 12:
  return ProtagonistForm.AVATAR_PRIMORDIAL
 elif fragments_collected >= 7:
  return ProtagonistForm.ARQUIDEMONIO
 elif fragments_collected >= 3:
  return ProtagonistForm.NOBRE_ABISSAL
 return ProtagonistForm.IMP_MENOR

func get_form_name(form: ProtagonistForm) -> String:
 match form:
  ProtagonistForm.IMP_MENOR: return "Imp Menor"
  ProtagonistForm.NOBRE_ABISSAL: return "Nobre Abissal"
  ProtagonistForm.ARQUIDEMONIO: return "Arquidemônio"
  ProtagonistForm.AVATAR_PRIMORDIAL: return "Avatar Primordial"
 return "Desconhecido"

func kaelen_speak(message: String) -> void:
 kaelen_spoke.emit(message)

func get_act_info(act_number: int) -> Dictionary:
 return acts.get(act_number, {})

func get_character_info(character_id: String) -> Dictionary:
 return characters.get(character_id, {})

func get_antagonist_info(antagonist_id: String) -> Dictionary:
 return antagonists.get(antagonist_id, {})
