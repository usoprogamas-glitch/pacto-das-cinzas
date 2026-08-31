extends Control

# Cutscene de abertura de ato (ROADMAP #2): exibida entre um ato concluído e o
# próximo, quando o jogador clica "Continuar" na tela de vitória do chefe de ato.
# Conteúdo canônico dos Atos II-IV (GDD v2 §1.3-1.5). O Ato I não tem cutscene —
# sua abertura é a intro_story. Sem página para o ato atual → segue direto para
# o map_select (não bloqueia o fluxo).

const ACT_PAGES: Dictionary = {
 2: [
  "A queda do chefe orc corre a Fronteira Cinzenta. Criaturas esquecidas — mutantes, feras e exilados — começam a migrar para perto de você. Onde havia um imp solitário, agora há os primórdios de uma nação.",
  "Mas a Igreja da Luz Solar percebeu a chama. Na noite mais escura, os Inquisidores de Aço marcham contra o seu povo. Você não tem mais apenas uma vida a proteger: tem um povo inteiro.",
  "Entre as migramentes, duas almas respondem ao seu chamado: Lira, a Muda Mágica que cura, e Garm, o Lobo Caolho que fareja inimigos. O Despertar começou."
 ],
 3: [
  "A Bula Papal atravessa Aethelgard: a Cruzada Santa de Aurius convoca a humanidade contra a Nação das Cinzas. Regimentos de Paladinos da Alvorada e quatro dos Cinco Santos Cardeais marcham com milhares de homens.",
  "Anões dos Picos de Cinza, Elfos Caídos e tricheiras das profundezas escolhem lados. Aethelgard inteira arde em Guerra Fria — e cada liberto é um aliado a mais para o cerco que se aproxima.",
  "Nos Desfiladeiros de Ferro, a lendária Linha Dourada aguarda. Quebre-a, e o caminho para Solaria estará aberto. Thal'kor, o Corvo Bestial, fará o resto."
 ],
 4: [
  "Solaria, a Cidade Eterna: mármore branco, cúpulas de ouro, jardins suspensos sobre as nuvens — sustentada pela oração de milhões. As Escadarias do Céu levam ao Palácio Celestial de Aurius.",
  "Ao pisar no último degrau, o fragmento final de sua alma divina retorna. A memória está completa. O Avatar Primordial desperta — e com ele, a verdade sobre Kaelen aguarda junto ao trono.",
  "A marcha final começa. Não há mais nada entre você e o Falso Deus."
 ]
}

const ACT_TITLES: Dictionary = {
 2: "ATO II — O DESPERTAR",
 3: "ATO III — GUERRA FRIA",
 4: "ATO IV — QUEDA DE SOLARIA"
}

var act_label: Label
var text_label: Label
var page_counter: Label
var controls_hint: Label

var current_page: int = 0

func _ready() -> void:
 _build_ui_if_missing()
 act_label = get_node("VBoxContainer/ActLabel") as Label
 text_label = get_node("VBoxContainer/TextLabel") as Label
 page_counter = get_node("VBoxContainer/PageCounter") as Label
 controls_hint = get_node("VBoxContainer/ControlsHint") as Label
 _show_current_page()

func _build_ui_if_missing() -> void:
 # Mesmo idiom da intro_story: instanciação via código (testes headless) cria
 # os nós de UI esperados pelo script.
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

  var title = Label.new()
  title.name = "ActLabel"
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(title)

  var label = Label.new()
  label.name = "TextLabel"
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.size_flags_vertical = Control.SIZE_EXPAND_FILL
  vbox.add_child(label)

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

func _pages_for_current_act() -> Array:
 var act: int = 0
 if GameManager and GameManager.campaign_system:
  act = GameManager.campaign_system.current_act
 return ACT_PAGES.get(act, [])

func _show_current_page() -> void:
 var pages: Array = _pages_for_current_act()
 if pages.is_empty() or current_page >= pages.size():
  _finish()
  return

 text_label.text = pages[current_page]
 if page_counter:
  page_counter.text = "%d/%d" % [current_page + 1, pages.size()]
 if act_label:
  var act: int = GameManager.campaign_system.current_act
  act_label.text = ACT_TITLES.get(act, "ATO %d" % act)

func _advance_page() -> void:
 current_page += 1
 _show_current_page()

func _finish() -> void:
 # Consome o flag da campanha e segue o loop linear (molde SoS: exploração).
 if GameManager and GameManager.campaign_system:
  GameManager.campaign_system.mark_act_intro_seen()
  if GameManager.has_method("save_game"):
   GameManager.save_game()
 if SceneManager:
  GameManager.sync_current_map_from_campaign()
  SceneManager.change_scene("explore")

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("intro_next"):
  _advance_page()
 elif event.is_action_pressed("intro_skip"):
  _finish()
