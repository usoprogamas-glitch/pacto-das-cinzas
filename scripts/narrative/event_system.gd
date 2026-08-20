class_name EventSystem
extends Node

signal event_started(event_id: String)
signal event_completed(event_id: String)
signal chapter_started(act: int, chapter: int)

var current_event: String = ""
var completed_events: Array[String] = []
var event_queue: Array[String] = []

var events: Dictionary = {
 # === ATO I: SUSSURROS NA ESCURIDÃO ===
 "evt_despertar": {
  "act": 1,
  "chapter": 1,
  "title": "O Despertar",
  "description": "O protagonista acorda na Fronteira Cinzenta, sem memórias.",
  "type": "cutscene",
  "dialogues": ["kaelen_intro"],
  "rewards": {"memory": "mem_silhueta_antiga"},
  "next_events": ["evt_sobrevivencia"]
 },
 "evt_sobrevivencia": {
  "act": 1,
  "chapter": 1,
  "title": "Sobrevivência",
  "description": "Aprender a caçar e sobreviver na fronteira.",
  "type": "tutorial",
  "dialogues": ["kaelen_sobrevivencia"],
  "objectives": ["Caçar 3 criaturas", "Coletar 5 Soul Éter"],
  "rewards": {"gold": 50, "soul_ether": 30},
  "next_events": ["evt_salvar_goblins"]
 },
 "evt_salvar_goblins": {
  "act": 1,
  "chapter": 2,
  "title": "Os Descartados",
  "description": "Salvar Goblins de um grupo de mercenários.",
  "type": "battle",
  "enemies": ["mercenario", "mercenario", "mercenario"],
  "allies": [],
  "dialogues": ["kaelen_goblins"],
  "rewards": {"faith_kroug": 10, "soul_ether": 50},
  "next_events": ["evt_primeiro_nome"]
 },
 "evt_primeiro_nome": {
  "act": 1,
  "chapter": 2,
  "title": "O Primeiro Nome",
  "description": "Dar um nome ao Goblin salvo, iniciando o Pacto.",
  "type": "cutscene",
  "dialogues": ["kroug_resgate"],
  "rewards": {"apostle": "kroug", "faith_kroug": 20},
  "next_events": ["evt_montar_base"]
 },
 "evt_montar_base": {
  "act": 1,
  "chapter": 3,
  "title": "A Base",
  "description": "Montar a primeira base na Fronteira Cinzenta.",
  "type": "building",
  "buildings": ["acampamento_base", "toca_goblin"],
  "dialogues": ["kaelen_base"],
  "rewards": {"gold": 100},
  "next_events": ["evt_ataque_mercenarios"]
 },
 "evt_ataque_mercenarios": {
  "act": 1,
  "chapter": 4,
  "title": "O Primeiro Assalto",
  "description": "Mercenários de Bronze atacam a base recém-construída.",
  "type": "battle",
  "enemies": ["mercenario", "mercenario", "mercenario", "cacador"],
  "allies": ["kroug"],
  "dialogues": ["kaelen_first_battle"],
  "rewards": {"fragment": 1, "gold": 200, "soul_ether": 100},
  "boss": false,
  "next_events": ["evt_kaelen_revelacao"]
 },
 "evt_kaelen_revelacao": {
  "act": 1,
  "chapter": 5,
  "title": "O Primeiro Fragmento",
  "description": "Após a batalha, o protagonista recupera um fragmento de memória.",
  "type": "cutscene",
  "dialogues": ["kaelen_revelacao"],
  "rewards": {"memory": "mem_voz_kaelen", "form": "Nobre Abissal"},
  "next_events": ["evt_fim_ato1"]
 },
 "evt_fim_ato1": {
  "act": 1,
  "chapter": 5,
  "title": "Fim do Ato I",
  "description": "A Nação de Cinzas nasce.",
  "type": "transition",
  "next_act": 2
 },

 # === ATO II: O TRONO DE BARRO E SANGUE ===
 "evt_crescimento_vila": {
  "act": 2,
  "chapter": 1,
  "title": "Crescimento",
  "description": "A vila cresce e novas raças se unem.",
  "type": "building",
  "buildings": ["muralha_pedra", "fornalha_vulcanica"],
  "rewards": {"gold": 300},
  "next_events": ["evt_resgatar_lira"]
 },
 "evt_resgatar_lira": {
  "act": 2,
  "chapter": 2,
  "title": "A Muda Mágica",
  "description": "Salvar uma Ent Primordial de caçadores humanos.",
  "type": "battle",
  "enemies": ["cacador", "cacador", "mercenario"],
  "allies": ["kroug"],
  "dialogues": ["lira_resgate"],
  "rewards": {"apostle": "lira", "faith_lira": 20},
  "next_events": ["evt_templo_cinzas"]
 },
 "evt_templo_cinzas": {
  "act": 2,
  "chapter": 3,
  "title": "O Templo",
  "description": "Construir o Templo das Cinzas para aumentar a Fé máxima.",
  "type": "building",
  "buildings": ["templo_cinzas"],
  "rewards": {"faith_cap": 50},
  "next_events": ["evt_invasao_inquisidores"]
 },
 "evt_invasao_inquisidores": {
  "act": 2,
  "chapter": 4,
  "title": "Inquisidores de Aço",
  "description": "Inquisidores descobrem a anomalia e invadem com feras domadas.",
  "type": "battle",
  "enemies": ["inquisidor", "inquisidor", "troll", "lobo_sombrio"],
  "allies": ["kroug", "lira"],
  "rewards": {"fragment": 1, "gold": 500},
  "boss": false,
  "next_events": ["evt_encontrar_thalkor"]
 },
 "evt_encontrar_thalkor": {
  "act": 2,
  "chapter": 5,
  "title": "Anjo Caído",
  "description": "Um anjo corrompido cai do céu após duvidar dos falsos deuses.",
  "type": "cutscene",
  "dialogues": ["thalkor_queda"],
  "rewards": {"apostle": "thalkor", "faith_thalkor": 20},
  "next_events": ["evt_diplomatas_humanos"]
 },
 "evt_diplomatas_humanos": {
  "act": 2,
  "chapter": 6,
  "title": "Diplomatas Sombras",
  "description": "Humanos de reinos oprimidos visitam a cidade furtivamente.",
  "type": "cutscene",
  "dialogues": ["diplomatas"],
  "rewards": {"unlock_trade": true},
  "next_events": ["evt_fim_ato2"]
 },
 "evt_fim_ato2": {
  "act": 2,
  "chapter": 6,
  "title": "Fim do Ato II",
  "description": "A Nação de Cinzas é reconhecida.",
  "type": "transition",
  "next_act": 3
 },

 # === ATO III: A CRUZADA DE FOGO ===
 "evt_cruzada_aurius": {
  "act": 3,
  "chapter": 1,
  "title": "A Cruzada",
  "description": "Aurius envia Paladinos e Santos Cardeais para purgar a Fronteira.",
  "type": "cutscene",
  "dialogues": ["aurius_cruzada"],
  "rewards": {},
  "next_events": ["evt_batalha_paladinos"]
 },
 "evt_batalha_paladinos": {
  "act": 3,
  "chapter": 2,
  "title": "Batalha dos Paladinos",
  "description": "Enfrentar os Paladinos da Alvorada.",
  "type": "battle",
  "enemies": ["paladino", "paladino", "inquisidor", "inquisidor"],
  "allies": ["kroug", "lira", "thalkor"],
  "rewards": {"fragment": 1, "gold": 800},
  "boss": false,
  "next_events": ["evt_batalha_cardeais"]
 },
 "evt_batalha_cardeais": {
  "act": 3,
  "chapter": 3,
  "title": "Os Santos Cardeais",
  "description": "Enfrentar dois dos cinco Santos Cardeais.",
  "type": "battle",
  "enemies": ["santo_cardeal", "santo_cardeal"],
  "allies": ["kroug", "lira", "thalkor"],
  "rewards": {"fragment": 2, "gold": 1500},
  "boss": true,
  "next_events": ["evt_cidade_danificada"]
 },
 "evt_cidade_danificada": {
  "act": 3,
  "chapter": 4,
  "title": "Cinzas e Luto",
  "description": "A cidade é gravemente danificada. Muitos caíram.",
  "type": "cutscene",
  "dialogues": ["cidade_danificada"],
  "rewards": {"memory": "mem_amor_nacao"},
  "next_events": ["evt_marcha_solaria"]
 },
 "evt_marcha_solaria": {
  "act": 3,
  "chapter": 5,
  "title": "A Marcha",
  "description": "A Nação de Cinzas marcha contra Solaria.",
  "type": "cutscene",
  "dialogues": ["marcha"],
  "rewards": {},
  "next_events": ["evt_fim_ato3"]
 },
 "evt_fim_ato3": {
  "act": 3,
  "chapter": 5,
  "title": "Fim do Ato III",
  "description": "O exército parte para a guerra final.",
  "type": "transition",
  "next_act": 4
 },

 # === ATO IV: A GUERRA DOS DEUSES ===
 "evt_invasao_solaria": {
  "act": 4,
  "chapter": 1,
  "title": "Invasão",
  "description": "O exército atinge as muralhas de mármore de Solaria.",
   "type": "battle",
  "enemies": ["paladino", "paladino", "paladino", "inquisidor", "inquisidor", "inquisidor"],
  "allies": ["kroug", "lira", "thalkor", "goblin_army"],
  "rewards": {"fragment": 1},
  "next_events": ["evt_portas_sanctum"]
 },
 "evt_portas_sanctum": {
  "act": 4,
  "chapter": 2,
  "title": "As Portas de Ouro",
  "description": "O protagonista rompe as portas do Sanctum de Ouro.",
  "type": "cutscene",
  "dialogues": ["portas_sanctum"],
  "rewards": {},
  "next_events": ["evt_confronto_final"]
 },
 "evt_confronto_final": {
  "act": 4,
  "chapter": 3,
  "title": "O Confronto Final",
  "description": "Enfrentar Aurius, o Falso Deus da Luz.",
  "type": "battle",
  "enemies": ["aurius"],
  "allies": [],
  "dialogues": ["aurius_confronto"],
  "rewards": {"fragment": 2},
  "boss": true,
  "next_events": ["evt_aceitar_kaelen"]
 },
 "evt_aceitar_kaelen": {
  "act": 4,
  "chapter": 4,
  "title": "A Aceitação",
  "description": "Aceitar Kaelen completamente, atingindo a Forma Verdadeira.",
  "type": "cutscene",
  "dialogues": ["kaelen_verdade"],
  "rewards": {"form": "Avatar Primordial", "memory": "mem_verdade_kaelen"},
  "next_events": ["evt_pacto_cinzas"]
 },
 "evt_pacto_cinzas": {
  "act": 4,
  "chapter": 5,
  "title": "O Pacto das Cinzas",
  "description": "Oferecer o Pacto aos sobreviventes. A paz eterna.",
  "type": "ending",
  "dialogues": ["pacto_final"],
  "rewards": {"memory": "mem_paz_divina"},
  "next_events": []
 }
}

func _ready() -> void:
 pass

func start_event(event_id: String) -> void:
 if not events.has(event_id):
  return

 var event = events[event_id]
 current_event = event_id
 event_started.emit(event_id)

 # Processar evento baseado no tipo
 match event.type:
  "cutscene":
   await process_cutscene(event)
  "battle":
   await process_battle(event)
  "building":
   await process_building(event)
  "transition":
   process_transition(event)
  "ending":
   await process_ending(event)

 complete_event(event_id)

func process_cutscene(event: Dictionary) -> void:
 if event.has("dialogues"):
  var dialogue_system = get_node("/root/DialogueSystem")
  for dialogue_id in event.dialogues:
   if dialogue_system:
    await dialogue_system.start_dialogue(dialogue_id)

func process_battle(event: Dictionary) -> void:
 # Configurar batalha
 var battle_config = {
  "enemies": event.enemies,
  "allies": event.get("allies", []),
  "boss": event.get("boss", false)
 }
 # Iniciar batalha
 pass

func process_building(event: Dictionary) -> void:
 if event.has("buildings"):
  var building_system = get_node("/root/GameManager").building_system
  for building_id in event.buildings:
   if building_system:
    building_system.build(building_id)

func process_transition(event: Dictionary) -> void:
 if event.has("next_act"):
  var narrative = get_node("/root/NarrativeSystem")
  if narrative:
   narrative.start_act(event.next_act)

func process_ending(event: Dictionary) -> void:
 # Processar final do jogo
 pass

func complete_event(event_id: String) -> void:
 if event_id not in completed_events:
  completed_events.append(event_id)
 current_event = ""
 event_completed.emit(event_id)

 # Verificar próximos eventos
 var event = events[event_id]
 if event.has("next_events"):
  for next_id in event.next_events:
   event_queue.append(next_id)

func get_event(event_id: String) -> Dictionary:
 return events.get(event_id, {})

func is_event_completed(event_id: String) -> bool:
 return event_id in completed_events

func get_available_events() -> Array:
 return event_queue.duplicate()

func get_act_events(act: int) -> Array:
 var result = []
 for event_id in events:
  if events[event_id].act == act:
   result.append(event_id)
 return result
