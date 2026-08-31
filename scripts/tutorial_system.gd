class_name TutorialSystem
extends Node

signal tutorial_step_completed(step: String)
signal tutorial_completed()
signal tutorial_message(message: String, position: Vector2)

var current_step: int = 0
var tutorial_active: bool = false
var completed_steps: Array[String] = []

var tutorial_steps: Array[Dictionary] = [
 {
  "id": "welcome",
  "title": "Bem-vindo, Imp!",
  "message": "Você acordou na Fronteira Cinzenta. Kaelen, a voz em sua mente, guiará seus primeiros passos.",
  "position": "center",
  "condition": "none",
  "action": "click_to_continue"
 },
 {
  "id": "select_unit",
  "title": "Selecionar Unidade",
  "message": "Clique em uma unidade verde (aliada) para selecioná-la.",
  "position": "bottom",
  "condition": "click_player_unit",
  "action": "highlight_player_units"
 },
 {
  "id": "move_unit",
  "title": "Mover Unidade",
  "message": "Clique em um tile azul para mover a unidade selecionada.",
  "position": "bottom",
  "condition": "move_unit",
  "action": "show_movement_range"
 },
 {
  "id": "attack_unit",
  "title": "Atacar Inimigo",
  "message": "Clique em um inimigo (vermelho) para atacá-lo.",
  "position": "bottom",
  "condition": "attack_enemy",
  "action": "show_attack_range"
 },
 {
  "id": "wait_action",
  "title": "Esperar Turno",
  "message": "Clique em 'Esperar' para finalizar o turno da unidade.",
  "position": "bottom",
  "condition": "wait_action",
  "action": "show_wait_button"
 },
 {
  "id": "end_turn",
  "title": "Finalizar Turno",
  "message": "Quando todas as unidades agirem, o turno inimigo começará automaticamente.",
  "position": "center",
  "condition": "end_player_turn",
  "action": "none"
 },
 {
  "id": "kaelen_intro",
  "title": "Kaelen Fala",
  "message": "Uma voz ressoa em sua mente: 'Eu sou Kaelen. Uma centelha do que você costumava ser.'",
  "position": "top",
  "condition": "none",
  "action": "show_kaelen_dialogue"
 },
 {
  "id": "victory",
  "title": "Vitória!",
  "message": "Parabéns! Você sobreviveu à primeira batalha. Soul Éter coletado pode ser usado para nomear almas.",
  "position": "center",
  "condition": "battle_won",
  "action": "show_rewards"
 }
]

func start_tutorial() -> void:
 tutorial_active = true
 current_step = 0
 show_current_step()

func show_current_step() -> void:
 if current_step >= tutorial_steps.size():
  complete_tutorial()
  return

 var step = tutorial_steps[current_step]
 tutorial_message.emit(step.message, get_step_position(step.position))

 match step.action:
  "highlight_player_units":
   highlight_units(true)
  "show_movement_range":
   pass
  "show_attack_range":
   pass
  "show_wait_button":
   pass
  "show_kaelen_dialogue":
   pass
  "show_rewards":
   pass

func complete_step(step_id: String) -> void:
 if step_id not in completed_steps:
  completed_steps.append(step_id)
  tutorial_step_completed.emit(step_id)

 if current_step < tutorial_steps.size():
  var step = tutorial_steps[current_step]
  if step.id == step_id:
   current_step += 1
   show_current_step()

func complete_tutorial() -> void:
 tutorial_active = false
 completed_steps.clear()
 tutorial_completed.emit()

func get_step_position(position: String) -> Vector2:
 match position:
  "center": return Vector2(640, 360)
  "top": return Vector2(640, 100)
  "bottom": return Vector2(640, 620)
  "left": return Vector2(200, 360)
  "right": return Vector2(1080, 360)
 return Vector2(640, 360)

func highlight_units(show: bool) -> void:
 pass

func is_tutorial_active() -> bool:
 return tutorial_active

func skip_tutorial() -> void:
 complete_tutorial()

func reset_tutorial() -> void:
 current_step = 0
 completed_steps.clear()
 tutorial_active = false
