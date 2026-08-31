class_name IntroStory
extends Control

signal intro_completed(choices: Dictionary)

# Tempo (s) que cada slide de narração fica em tela antes do auto-advance.
# Antes: tween sem intervalo disparava no frame seguinte → 13 slides em ~0.2s,
# história imperceptível (jogo caía direto na escolha).
const AUTO_ADVANCE_SECONDS := 3.5

var background: ColorRect
var text_label: Label
var choice_container: HBoxContainer
var kaelen_portrait: TextureRect
var page_counter: Label
var controls_hint: Label

var current_step: int = 0
var story_text: Array[Dictionary] = []
var player_choices: Dictionary = {}
var _advance_tween: Tween

func _ready() -> void:
 _build_ui_if_missing()
 background = get_node("Background") as ColorRect
 text_label = get_node("VBoxContainer/TextLabel") as Label
 choice_container = get_node("VBoxContainer/ChoiceContainer") as HBoxContainer
 kaelen_portrait = get_node("VBoxContainer/KaelenPortrait") as TextureRect
 page_counter = get_node("VBoxContainer/PageCounter") as Label
 controls_hint = get_node("VBoxContainer/ControlsHint") as Label
 # Auto-conectar ao GameManager: a main scene NÃO declara conexões e o connect
 # costumava ficar numa instância duplicada do próprio GameManager — o sinal da
 # tela visível caía no vazio e o jogo nunca iniciava (tela preta após a escolha).
 if GameManager:
  GameManager.connect_intro_story(self)
 setup_story()
 show_current_step()

func _build_ui_if_missing() -> void:
 # Quando instanciado via código (sem .tscn), cria os nós de UI esperados
 if not has_node("Background"):
  var bg = ColorRect.new()
  bg.name = "Background"
  bg.color = Color(0.05, 0.04, 0.08)
  bg.set_anchors_preset(Control.PRESET_FULL_RECT)
  add_child(bg)

 if not has_node("VBoxContainer"):
  var vbox = VBoxContainer.new()
  vbox.name = "VBoxContainer"
  vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
  vbox.add_theme_constant_override("separation", 20)
  add_child(vbox)

  var portrait = TextureRect.new()
  portrait.name = "KaelenPortrait"
  portrait.custom_minimum_size = Vector2(0, 200)
  portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  vbox.add_child(portrait)

  var label = Label.new()
  label.name = "TextLabel"
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.size_flags_vertical = Control.SIZE_EXPAND_FILL
  vbox.add_child(label)

  var choices = HBoxContainer.new()
  choices.name = "ChoiceContainer"
  choices.alignment = BoxContainer.ALIGNMENT_CENTER
  choices.add_theme_constant_override("separation", 30)
  vbox.add_child(choices)

  var counter = Label.new()
  counter.name = "PageCounter"
  counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  counter.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1))
  vbox.add_child(counter)

  var hint = Label.new()
  hint.name = "ControlsHint"
  hint.text = "A: avançar  |  Start/ESC: pular"
  hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1))
  hint.add_theme_font_size_override("font_size", 14)
  vbox.add_child(hint)

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
   "text": "Kaelen avalia o quadro em um instante: \"Sua mana é ínfima — quinze pontos, nada mais. Gaste. Um aliado vale mais do que prudência para quem não tem nada.\"",
   "speaker": "kaelen",
   "portrait": "kaelen"
  },
  {
   "text": "Você canaliza até a última fagulha e toca a mão estendida. A essência do goblin se refaz: ele cresce, o couro vira couraída pálida, os olhos ardem em âmbar — Hobgoblin. \"Kroug,\" você diz. O primeiro Pacto de Alma em milênios está forjado.",
   "speaker": "narrator",
   "portrait": null
  },
  {
   "text": "O Éter aguarda.",
   "speaker": "narrator",
   "portrait": null
  }
 ]

func show_current_step() -> void:
 _kill_advance_tween()

 if current_step >= story_text.size():
  complete_intro()
  return

 var step = story_text[current_step]

 text_label.text = step.text
 text_label.visible = true

 if page_counter:
  page_counter.text = "%d/%d" % [current_step + 1, story_text.size()]
 
 # Atualizar retrato
 if step.portrait == "kaelen":
  kaelen_portrait.texture = load("res://assets/portraits/kaelen.png") if FileAccess.file_exists("res://assets/portraits/kaelen.png") else null
  kaelen_portrait.visible = true
 else:
  kaelen_portrait.visible = false
 
 # Intro é história: sem slides de escolha, o container nunca aparece.
 choice_container.visible = false
 # Narrativa: aguarda o player apertar A (intro_next).
 _kill_advance_tween()

func _kill_advance_tween() -> void:
 if _advance_tween:
  _advance_tween.kill()
  _advance_tween = null

func _advance_step() -> void:
 if current_step >= story_text.size():
  complete_intro()
  return
 current_step += 1
 show_current_step()

func _build_final_choices() -> Dictionary:
 # Pacto de Alma canônico (GDD 2.1): a intro NARRA o 1º pacto, então Kroug
 # nasce sempre. O handler do GameManager consome "first_pact" (-15 mana,
 # naming + fé + spawn na batalha). Pular a intro também segue o cânone.
 player_choices["first_pact_choice"] = {"consequence": "first_pact"}
 return player_choices

func complete_intro() -> void:
 intro_completed.emit(_build_final_choices())
 visible = false
 # Fluxo linear de enredo (molde SoS): a intro desagua na EXPLORAÇÃO do
 # estágio atual da campanha (Ato I — "Socorro aos Goblins").
 # Fora da árvore (testes GUT) não há cena viva para trocar.
 if is_inside_tree():
  GameManager.sync_current_map_from_campaign()
  SceneManager.go_to_explore()

func skip_intro() -> void:
 player_choices["skipped"] = true
 complete_intro()

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("intro_next"):
  _advance_step()
 # Start/ESC: pula a intro inteira
 elif event.is_action_pressed("intro_skip"):
  skip_intro()