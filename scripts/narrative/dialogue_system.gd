class_name DialogueSystem
extends Node

signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal choice_made(choice_id: String, option_index: int)
signal kaelen_advice(message: String)

var current_npc: String = ""
var dialogue_state: Dictionary = {}
var knowledge_base: Dictionary = {}

var dialogues: Dictionary = {
 # === KAELEN - A Voz do Mundo ===
 "kaelen_intro": {
  "npc": "kaelen",
  "lines": [
   {"speaker": "Kaelen", "text": "..."},
   {"speaker": "Kaelen", "text": "Acorde. Não há tempo para contemplação."},
   {"speaker": "Kaelen", "text": "Eu sou Kaelen. Uma centelha do que você costumava ser."},
   {"speaker": "Kaelen", "text": "Seu corpo é frágil. Sua memória, fragmentada. Mas sua essência... ela ainda arde."},
   {"speaker": "Kaelen", "text": "Escute-me com atenção: você é o Deus Primordial do Éter e das Feras. E está em perigo."},
   {"speaker": "Kaelen", "text": "Os usurpadores querem sua aniquilação. Mas eu posso ajudá-lo a se reconstruir."},
   {"speaker": "Kaelen", "text": "Primeiro, sobreviva. Depois, domine. Por fim, reconquiste."}
  ],
  "conditions": {"act": 1, "memory": "none"}
 },

 "kaelen_goblins": {
  "npc": "kaelen",
  "lines": [
   {"speaker": "Kaelen", "text": "Essas criaturas... Goblins da Lama. As mais fracas de todas as raças."},
   {"speaker": "Kaelen", "text": "Mas sua fraqueza é sua virtude. Ninguém os leva a sério."},
   {"speaker": "Kaelen", "text": "Salve um. Dê-lhe um nome. E verá a lealdade que os deuses jamais receberam."},
   {"speaker": "Kaelen", "text": "A fé alimenta mais que armas. Ela alimenta a evolução."}
  ],
  "conditions": {"act": 1, "event": "evt_salvar_goblins"}
 },

 "kaelen_first_battle": {
  "npc": "kaelen",
  "lines": [
   {"speaker": "Kaelen", "text": "Mercenários. Caçadores de monstros por lucro."},
   {"speaker": "Kaelen", "text": "Eles não sabem o que você realmente é. E é assim que deve permanecer."},
   {"speaker": "Kaelen", "text": "Lute. Mas não use seu poder divino. Ainda não."},
   {"speaker": "Kaelen", "text": "Se os falsos deuses perceberem sua presença, enviarão exércitos inteiros."}
  ],
  "conditions": {"act": 1, "event": "evt_ataque_mercenarios"}
 },

 # === KROUG - O Escudo ===
 "kroug_resgate": {
  "npc": "kroug",
  "lines": [
   {"speaker": "???", "text": "*Goblin ferido tenta se arrastar para longe*"},
   {"speaker": "Protagonista", "text": "Espere. Não vou te machucar."},
   {"speaker": "???", "text": "P-por que me salvou? Humanos sempre matam..."},
   {"speaker": "Protagonista", "text": "Porque também fui descartado. Como você."},
   {"speaker": "Kaelen", "text": "Dê-lhe um nome. Algo que o torne único."},
   {"speaker": "Protagonista", "text": "Seu nome será Kroug. O Escudo que protegerá os nossos."},
   {"speaker": "Kroug", "text": "Kroug... Eu gosto. Kroug será leal ao Senhor!"}
  ],
  "conditions": {"act": 1, "event": "evt_primeiro_nome"}
 },

 # === LIRA - A Sacerdotisa ===
 "lira_resgate": {
  "npc": "lira",
  "lines": [
   {"speaker": "Caçador", "text": "Esta muda é rara! Vai render uma fortuna!"},
   {"speaker": "Protagonista", "text": "Soltre-a. Agora."},
   {"speaker": "Caçador", "text": "Ou o quê? Um impzinho vai me ameaçar?"},
   {"speaker": "*Luta*"},
   {"speaker": "Lira", "text": "*A muda brilha suavemente*"},
   {"speaker": "Kaelen", "text": "Uma Ent Primordial. Raríssima. Ela pode controlar a vida orgânica."},
   {"speaker": "Protagonista", "text": "Você está segura agora. Meu nome é... na verdade, ainda não tenho um."},
   {"speaker": "Lira", "text": "*A muda emite uma luz verde, como um agradecimento*"},
   {"speaker": "Kaelen", "text": "Ela não pode falar ainda. Mas sua gratidão é genuína."}
  ],
  "conditions": {"act": 1, "event": "evt_salvar_lira"}
 },

 # === THAL'KOR - A Lâmina Cega ===
 "thalkor_queda": {
  "npc": "thalkor",
  "lines": [
   {"speaker": "Thal'kor", "text": "*Anjo ferido cai do céu*"},
   {"speaker": "Thal'kor", "text": "Por... por que duvidei? Os deuses me castigaram..."},
   {"speaker": "Protagonista", "text": "Eles não são deuses. São usurpadores."},
   {"speaker": "Thal'kor", "text": "Você... ousa dizer isso?"},
   {"speaker": "Protagonista", "text": "Eu era um deles. Antes de me traírem."},
   {"speaker": "Thal'kor", "text": "Seus olhos... eles ardem com uma luz antiga. Você não é apenas um mortal."},
   {"speaker": "Protagonista", "text": "Não. E você não é apenas um anjo caído. Você é um aliado."},
   {"speaker": "Thal'kor", "text": "Um aliado... Há quanto tempo não ouço essa palavra."},
   {"speaker": "Protagonista", "text": "Seu nome antigo não importa. Daqui para frente, você é Thal'kor. A Lâmina Cega que verá a verdade."}
  ],
  "conditions": {"act": 2, "event": "evt_encontrar_thalkor"}
 },

 # === AURIUS - O Falso Deus (Confronto Final) ===
 "aurius_confronto": {
  "npc": "aurius",
  "lines": [
   {"speaker": "Aurius", "text": "Então finalmente chegaste, aberração."},
   {"speaker": "Aurius", "text": "Você acha que é o Deus Original? Não passa de uma centelha corrupta."},
   {"speaker": "Aurius", "text": "Aquela voz na sua cabeça - Kaelen - ela não é sua aliada."},
   {"speaker": "Aurius", "text": "É a personificação da dor e do isolamento do deus que você finge ser."},
   {"speaker": "Aurius", "text": "Cada memória que recupera é mais um pedaço de loucura."},
   {"speaker": "Aurius", "text": "Enquanto eu... eu sou a verdadeira luz. Eu salvei a humanidade da escuridão."},
   {"speaker": "Aurius", "text": "Entregue-se. E deixe que eu devore sua alma para manter a paz eterna."}
  ],
  "conditions": {"act": 4, "event": "evt_confronto_final"}
 },

 "kaelen_verdade": {
  "npc": "kaelen",
  "lines": [
   {"speaker": "Kaelen", "text": "..."},
   {"speaker": "Kaelen", "text": "Ele não está entirely errado."},
   {"speaker": "Kaelen", "text": "Eu sou a dor do Deus Original. O trauma de sua traição."},
   {"speaker": "Kaelen", "text": "Mas também sou sua racionalidade. Sua capacidade de não enlouquecer."},
   {"speaker": "Kaelen", "text": "Se me aceitar completamente... você se tornará completo."},
   {"speaker": "Kaelen", "text": "A dor e a razão. O monstro e o deus. Tudo em um."},
   {"speaker": "Kaelen", "text": "Ou pode me rejeitar. E ser apenas metade de algo grandioso."},
   {"speaker": "Protagonista", "text": "Eu te aceito. Tudo o que você é. Tudo o que fomos."},
   {"speaker": "Kaelen", "text": "...Então vamos. Juntos. Pela última vez."}
  ],
  "conditions": {"act": 4, "event": "evt_aceitar_kaelen"}
 }
}

func start_dialogue(dialogue_id: String) -> void:
 if not dialogues.has(dialogue_id):
  return

 var dialogue = dialogues[dialogue_id]

 # Verificar condições
 if not check_conditions(dialogue.conditions):
  return

 current_npc = dialogue.npc
 dialogue_started.emit(current_npc)

 # Processar falas
 for line in dialogue.lines:
  await process_line(line)

 dialogue_ended.emit(current_npc)

func check_conditions(conditions: Dictionary) -> bool:
 if conditions.has("act"):
  var narrative = get_node("/root/NarrativeSystem")
  if narrative and narrative.current_act != conditions.act:
   return false

 if conditions.has("event"):
  var narrative = get_node("/root/NarrativeSystem")
  if narrative and not dialogue_state.has(conditions.event):
   return false

 if conditions.has("memory"):
  var narrative = get_node("/root/NarrativeSystem")
  if narrative and conditions.memory != "none" and conditions.memory not in narrative.memories_recovered:
   return false

 return true

func process_line(line: Dictionary) -> void:
 var speaker = line.speaker
 var text = line.text

 if speaker == "Kaelen":
  kaelen_advice.emit(text)
 elif speaker == "Protagonista":
  # Diálogo interno do protagonista
  pass
 else:
  # Fala de NPC
  pass

 await get_tree().create_timer(0.5).timeout

func register_event(event_id: String) -> void:
 dialogue_state[event_id] = true

func register_memory(memory_id: String) -> void:
 dialogue_state["mem_" + memory_id] = true

func get_dialogue(dialogue_id: String) -> Dictionary:
 return dialogues.get(dialogue_id, {})

func get_available_dialogues() -> Array:
 var available = []
 for id in dialogues:
  if check_conditions(dialogues[id].conditions):
   available.append(id)
 return available
