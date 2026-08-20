class_name NamingUI
extends Control

signal soul_named(soul_type: String, custom_name: String)
signal back_pressed()

@onready var soul_list: ItemList = $VBoxContainer/SoulList
@onready var soul_info: RichTextLabel = $VBoxContainer/SoulInfo
@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var name_button: Button = $VBoxContainer/NameButton
@onready var back_button: Button = $BackButton
@onready var named_count_label: Label = $TopBar/NamedCountLabel

var naming_system: NamingSystem
var selected_soul_type: String = ""

func _ready() -> void:
 naming_system = NamingSystem.new()
 populate_soul_list()
 name_button.pressed.connect(_on_name_pressed)
 back_button.pressed.connect(_on_back)
 soul_list.item_selected.connect(_on_soul_selected)

func populate_soul_list() -> void:
 soul_list.clear()
 var types = naming_system.get_available_soul_types()
 for soul_type in types:
  var template = naming_system.get_soul_template(soul_type)
  soul_list.add_item(template.base_name)

func _on_soul_selected(index: int) -> void:
 var types = naming_system.get_available_soul_types()
 selected_soul_type = types[index]
 var template = naming_system.get_soul_template(selected_soul_type)

 var info = "[center]%s[/center]\n\n" % template.base_name
 info += "Tipo: %s\n" % template.type
 info += "Descrição: %s\n\n" % template.description
 info += "[b]Stats Base:[/b]\n"
 info += "  HP: %d\n" % template.base_stats.hp
 info += "  ATK: %d\n" % template.base_stats.attack
 info += "  DEF: %d\n" % template.base_stats.defense
 info += "  SPD: %d\n\n" % template.base_stats.speed
 info += "[b]Evoluções:[/b]\n"
 for evo in template.evolutions:
  info += "  • %s (Nv.%d)\n" % [evo.name, evo.level]
 info += "\n[b]Habilidade de Pacto:[/b] %s" % template.pact_ability

 soul_info.text = info
 name_button.disabled = false

func _on_name_pressed() -> void:
 if selected_soul_type == "":
  return

 var custom_name = name_input.text.strip_edges()
 soul_named.emit(selected_soul_type, custom_name)
 name_input.clear()

func _on_back() -> void:
 back_pressed.emit()
