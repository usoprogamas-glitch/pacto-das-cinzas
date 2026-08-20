class_name IntroStory
extends Control

signal intro_completed(choices: Dictionary)

@onready var background: ColorRect = $Background
@onready var text_label: Label = $VBoxContainer/TextLabel
@onready var choice_container: HBoxContainer = $VBoxContainer/ChoiceContainer
@onready var kaelen_portrait: TextureRect = $VBoxContainer/KaelenPortrait

var current_step: int = 0
var story_text: Array[Dictionary] = []
var player_choices: Dictionary = {}

func _ready() -> void:
 setup_story()
 show_current_step()

func setup_story() -> void:
 story_text = [
  {
   "text": "No alvorecer da existência, o cosmos não era regido por dogmas ou tiranias luminosas, mas pelo Éter Primordial: um fluxo contínuo de energia vital, caótica e fértil, moldado pela entidade conhecida apenas como o Deus Primordial do Éter e das Feras.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "Sob seu domínio, Aethelgard florescia em um estado de equilíbrio selvagem — a predação e o renascimento coexistiam sem crueldade moral, e a magia corria livre pelas veias da terra.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "Mas a inveja é uma praga que não poupa nem deuses. Aurius, a personificação da aurora e da ordem geométrica, desprezava a natureza fluida e imprevisível do Éter. Ele julgava que a verdadeira perfeição só poderia existir sob uma hierarquia inabalável governada pela luz absoluta.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "Durante o Grande Eclipse — o único momento a cada dez milênios em que o Éter Primordial se recolhe para se purificar —, Aurius e os demais deuses secundários desferiram um golpe devastador contra o Criador.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "O Estilhaçamento Divino: Utilizando correntes forjadas na fornalha do sol nascente, prenderam o Deus Primordial e fragmentaram sua essência imaterial em dezenas de milhares de estilhaços que caíram sobre Aethelgard como meteoros cinzentos.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "A Grande Censura Histórica: Aurius reescreveu a cosmologia de Aethelgard por meio da Igreja da Luz Solar, apagando os registros do Antigo Deus e proclamando a si mesmo como o \"Único Arquiteto da Criação\".",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "Milênios depois, a menor e última centelha divina desperta no corpo da criatura mais fraca do mundo submundano: um Imp Menor. Sem memórias, sem poder e em um corpo frágil...",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "Você acorda na Fronteira Cinzenta. Terra vulcânica estéril, pântanos de lodo tóxico, neblina impenetrável. Seu corpo é frágil — 0,80m, pele carmesim escurecida, dois pequenos chifres assimétricos, olhos amarelos brilhantes sem pupilas.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "Uma voz ressoa em sua mente. Fria, calculista, hiper-racional: \"Acorde. Não há tempo para contemplação. Eu sou Kaelen. Uma centelha do que você costumava ser. Seu corpo é frágil. Sua memória, fragmentada. Mas sua essência... ela ainda arde.\"",
   "speaker": "kaelen",
   "portrait": "kaelen"
  },
  {
   "text": "Kaelen continua: \"Os usurpadores querem sua aniquilação. Mas eu posso ajudá-lo a se reconstruir. Primeiro, sobreviva. Depois, domine. Por fim, reconquiste.\"",
   "speaker": "kaelen",
   "portrait": "kaelen"
  },
  {
   "text": "À distância, você vê uma tribo de Goblins da Lama sendo atacada por hienas bestiais. O líder moribundo estende a mão para você. Ele não tem nome. Ninguém lhe deu um.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "O que você faz?",
   "speaker": "choice",
   "portrait": null,
   "choices": [
    {"id": "save_goblin", "text": "Canalizar sua ínfima mana e salvá-lo (Gasta 15 Mana)", "consequence": "first_pact", "description": "Forja o primeiro Pacto de Alma. O goblin vira Hobgoblin. Kroug nasce."},
    {"id": "ignore", "text": "Ignorar e fugir para sobreviver", "consequence": "lone_survivor", "description": "Sobrevive sozinho. Mais difícil. Sem aliado inicial. Kaelen desaprova."},
    {"id": "observe", "text": "Observar e aprender com Kaelen antes de agir", "consequence": "cautious_start", "description": "Ganha conhecimento. Kaelen ensina mais. Começa com +10 Mana."}
   ]
  },
  {
   "text": "Sua escolha definirá o início de sua jornada. O Éter aguarda.",
   "speaker": "choice",
   "portrait": null,
   "choices": []
  }
 ]

func show_current_step() -> void:
 if current_step >= story_text.size():
  complete_intro()
  return

 var step = story_text[current_step]
 
 text_label.text = step.text
 text_label.visible = true
 
 # Atualizar retrato
 if step.portrait == "kaelen":
  kaelen_portrait.texture = load("res://assets/portraits/kaelen.png") if FileAccess.file_exists("res://assets/portraits/kaelen.png") else null
  kaelen_portrait.visible = true
 else:
  kaelen_portrait.visible = false
 
# Mostrar escolhas se houver
  if step.choices and step.choices.size() > 0:
   choice_container.visible = true
   for child in choice_container.get_children():
    child.queue_free()
   
  for choice in step.choices:
   var btn = Button.new()
   btn.text = choice.text
   btn.custom_minimum_size = Vector2(300, 60)
   btn.pressed.connect(func(): _on_choice_selected(choice))
   choice_container.add_child(btn)
 else:
  choice_container.visible = false
  # Auto-advance para texto sem escolhas
  if not step.choices or step.choices.size() == 0:
   var tween = create_tween()
   tween.tween_callback(func(): await get_tree().create_timer(3.0).timeout)
   tween.tween_callback(func(): _advance_step())

func _advance_step() -> void:
 current_step += 1
 show_current_step()

func _on_choice_selected(choice: Dictionary) -> void:
 player_choices[story_text[current_step].text] = choice
 
 # Aplicar consequência imediata
 match choice.consequence:
  "first_pact":
   player_choices["starting_ally"] = "kroug"
   player_choices["first_pact"] = true
   GameManager.game_data["mana"] = max(0, GameManager.game_data.get("mana", 120) - 15)
  "lone_survivor":
   player_choices["starting_ally"] = "none"
   player_choices["kaelen_approval"] = -10
   GameManager.game_data["mana"] = GameManager.game_data.get("mana", 120)
   player_choices["difficulty"] = "hard"
  "cautious_start":
   player_choices["starting_ally"] = "none"
   player_choices["knowledge_bonus"] = true
   GameManager.game_data["mana"] = GameManager.game_data.get("mana", 120) + 10
   player_choices["difficulty"] = "normal"
 
 _advance_step()

func complete_intro() -> void:
 intro_completed.emit(player_choices)
 visible = false

func skip_intro() -> void:
 player_choices["skipped"] = true
 complete_intro()

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
  skip_intro()