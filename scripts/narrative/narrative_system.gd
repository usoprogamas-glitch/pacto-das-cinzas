class_name NarrativeSystem
extends Node

## Sistema narrativo sincronizado com o GDD v2 "O Deus Despedaçado"
## (docs/GDD_Completo_v2.md — fonte da verdade de lore).

signal act_started(act_number: int, act_name: String)
signal event_triggered(event_id: String)
signal protagonist_evolved(new_form: String)
signal memory_recovered(memory_id: String)
signal kaelen_spoke(message: String)

## Fases do protagonista (canon GDD v2, seção 2):
## Querubim Fraturado -> Serafim das Cinzas -> Trono Cósmico/Arquidemônio -> Avatar Primordial
enum ProtagonistForm { QUERUBIM_FRATURADO, SERAFIM_DAS_CINZAS, TRONO_COSMICO, AVATAR_PRIMORDIAL }

var current_act: int = 1
var current_form: ProtagonistForm = ProtagonistForm.QUERUBIM_FRATURADO
var memories_recovered: Array[String] = []
var fragments_collected: int = 0

var acts: Dictionary = {
 1: {
  "name": "A Fronteira Cinzenta",
  "description": "O Querubim Fraturado desperta nos ermos. Salva os Goblins da Lama e nomeia Kroug.",
  "events": ["evt_despertar", "evt_salvar_goblins", "evt_primeiro_nome", "evt_ataque_mercenarios"],
  "form_unlocked": ProtagonistForm.QUERUBIM_FRATURADO,
  "memories": ["mem_silhueta_antiga", "mem_voz_kaelen"]
 },
 2: {
  "name": "O Despertar da Chama Sombria",
  "description": "O acampamento vira fortaleza. Inquisidores de Aço atacam à noite; Lira é resgatada.",
  "events": ["evt_crescimento_vila", "evt_invasao_inquisidores", "evt_resgate_lira", "evt_nacao_das_cinzas"],
  "form_unlocked": ProtagonistForm.SERAFIM_DAS_CINZAS,
  "memories": ["mem_correntes_solares", "mem_batalha_antiga"]
 },
 3: {
  "name": "A Guerra Fria dos Renegados",
  "description": "Aliança com Anões e Elfos Caídos. A Bula Papal declara a Guerra Santa.",
  "events": ["evt_clas_anoes", "vt_elfos_caidos", "evt_bula_papal", "evt_cerco_desfiladeiros"],
  "form_unlocked": ProtagonistForm.TRONO_COSMICO,
  "memories": ["mem_traicao_completa", "mem_amor_nacao"]
 },
 4: {
  "name": "A Queda de Solaria",
  "description": "Marcha final. Verdade sobre Kaelen. Execução de Aurius. O Pacto das Cinzas.",
  "events": ["evt_invasao_solaria", "evt_confronto_final", "evt_aceitar_kaelen", "evt_pacto_cinzas"],
  "form_unlocked": ProtagonistForm.AVATAR_PRIMORDIAL,
  "memories": ["mem_verdade_kaelen", "mem_paz_divina"]
 }
}

var characters: Dictionary = {
 "protagonista": {
  "name": "Sem Nome (Querubim Fraturado)",
  "true_name": "O Deus Primordial do Éter e das Feras",
  "form": "Querubim Fraturado (Imp Angelical)",
  "description": "Beleza divina caçada como aberração. Mármore rachado com veias de éter cobalto",
  "arc": "De fagulha esquecida a Avatar Primordial"
 },
 "kaelen": {
  "name": "Kaelen",
  "title": "A Voz da Fratura",
  "description": "Sistema analítico que calcula trajetórias e fraquezas com precisão matemática",
  "secret": "Personificação do trauma e da fúria do Deus Primordial no instante da traição — máquina de vingança, não módulo benevolente",
  "mission": "Guiar a 'aberração angelical' na sobrevivência — e na vingança"
 },
 "kroug": {
  "name": "Kroug",
  "title": "O Escudo das Cinzas",
  "description": "Primeiro monstro salvo e nomeado. Trata o Criador como 'Pai das Chamas'",
  "evolution": "Goblin da Lama → Hobgoblin de Ferro → Rei Ogro de Fogo",
  "personality": "Lealdade absoluta; vocabulário rústico e marcial",
  "synergy": "+15% Defesa base para o Protagonista em campo"
 },
 "lira": {
  "name": "Lira",
  "title": "A Sacerdotisa da Floresta",
  "description": "Dríade ancestral resgatada. Refere-se ao Éter como 'O Orvalho da Vida'",
  "evolution": "Muda Mágica → Dríade Sombria → Rainha Ent Primordial",
  "role": "Suporte supremo de regeneração",
  "synergy": "Regeneração passiva de 2% HP/seg para o Protagonista"
 },
 "thalkor": {
  "name": "Thal'kor",
  "title": "A Lâmina Cega",
  "description": "Assassino aéreo cínico com terminologia celeste deturpada",
  "evolution": "Corvo Bestial → Harpia Noturna → Serafim Negro",
  "personality": "Igualdade estratégica; código moral oculto",
  "synergy": "+20% Velocidade de Ataque para o Protagonista"
 },
 "garm": {
  "name": "Garm",
  "title": "O Devorador de Horizontes",
  "description": "Lobo caolho resgatado dos inquisidores. Montaria empática do protagonista",
  "evolution": "Lobo Caolho → Cão do Inferno Sombrio → Fenrir Menor",
  "personality": "Empático, instintivo, devorado por horizontes distantes",
  "synergy": "Montaria veloz: travessia e caça de infantaria"
 }
}

var antagonists: Dictionary = {
 "aurius": {
  "name": "Aurius",
  "title": "O Falso Deus da Luz Solar",
  "description": "Ex-deus menor da aurora que traiu e estilhaçou o Criador no Grande Eclipse",
  "secret": "Reescreveu a cosmologia na Grande Censura; proclamou-se Único Arquiteto da Criação",
  "final_boss": true
 },
 "santos_cardeais": {
  "name": "Santos Cardeais",
  "description": "Cinco humanos com avatares dos deuses usurpadores: Ignis, Zephyr, Aqua, Terra, Umbra",
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
  return ProtagonistForm.TRONO_COSMICO
 elif fragments_collected >= 3:
  return ProtagonistForm.SERAFIM_DAS_CINZAS
 return ProtagonistForm.QUERUBIM_FRATURADO

func get_form_name(form: ProtagonistForm) -> String:
 match form:
  ProtagonistForm.QUERUBIM_FRATURADO: return "Querubim Fraturado"
  ProtagonistForm.SERAFIM_DAS_CINZAS: return "Serafim das Cinzas"
  ProtagonistForm.TRONO_COSMICO: return "Trono Cósmico / Arquidemônio"
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
