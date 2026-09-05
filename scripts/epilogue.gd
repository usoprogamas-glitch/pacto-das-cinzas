extends Control

signal menu_requested()

# Epílogo — O Pacto das Cinzas (GDD v2 §1.5): fim da campanha após Aurius Fase 3.
# Texto canônico: revelação de Kaelen, execução de Aurius, Tratado do Éter e da Carne.

const EPILOGUE_TEXT: String = """Aurius é despojado de suas asas solares e executado no topo da torre mais alta de Solaria.

Os feixes de luz artificial que cegavam a mente da humanidade se dissipam, revelando a farsa milenar dos falsos milagres da Igreja.

Diante do trono vazio, a verdade sobre Kaelen por fim se revela: não era uma voz divina, mas a personificação do trauma e da fúria do Deus Primordial traído — uma máquina de vingança forjada no milissegundo da traição.

E em vez de rejeitá-la, o protagonista a abraça: a dor e a fúria fazem parte da totalidade da existência. Divindade e sombra fundidas em perfeita simbiose.

Sobre as cinzas de Solaria, é redigido o Tratado do Éter e da Carne. Homens e monstros passam a coabitar sob um novo contrato civilizatório.

O antigo criador abdica do trono cósmico para viver entre os mortais, na Nação das Cinzas — garantindo que nenhum deus jamais volte a reinar acima do equilíbrio natural."""

const CREDITS_TEXT: String = """O Pacto das Cinzas

Um jogo de tactics e construção de reino

Inspirado em Triangle Strategy, Fire Emblem,
Monster Train e Cult of the Lamb

Feito em Godot 4"""

@onready var epilogue_label: Label = $VBoxContainer/EpilogueLabel
@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var menu_button: Button = $VBoxContainer/MenuButton

func _ready() -> void:
 epilogue_label.text = EPILOGUE_TEXT
 credits_label.text = CREDITS_TEXT
 menu_button.pressed.connect(_on_menu)

func _on_menu() -> void:
 menu_requested.emit()
 if SceneManager:
  SceneManager.change_scene("main_menu")
