class_name Unit
extends Node2D

signal hp_changed(new_hp: int)
signal mp_changed(new_mp: int)
signal selected()
signal deselected()

@export var data: UnitData

var grid_position: Vector2i = Vector2i.ZERO
var has_acted: bool = false
var has_moved: bool = false
var current_hp: int = 100
var current_mp: int = 50

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var selection_indicator: ColorRect = $SelectionIndicator
@onready var animator: Node = $Animator if has_node("Animator") else null

func _ready() -> void:
 if data:
  current_hp = data.max_hp
  current_mp = data.max_mp
  if sprite:
   sprite.modulate = data.color
  update_hp_bar()

func _process(_delta: float) -> void:
 if selection_indicator and BattleManager:
  selection_indicator.visible = (self == BattleManager.selected_unit)

func select() -> void:
 selected.emit()

func deselect() -> void:
 deselected.emit()

func reset_turn() -> void:
 has_acted = false
 has_moved = false

func is_alive() -> bool:
 ## Contrato do TurnOrderManager (velocity-based turn order)
 return current_hp > 0

func get_speed() -> int:
 ## Contrato do TurnOrderManager (velocity-based turn order)
 return data.speed if data else 0

func is_player_side() -> bool:
 ## Contrato do TurnOrderManager (velocity-based turn order)
 return data.is_player if data else false

func take_damage(amount: int) -> void:
 if not data:
  return
 var actual_damage = maxi(1, amount - data.defense)
 current_hp = maxi(0, current_hp - actual_damage)
 hp_changed.emit(current_hp)
 update_hp_bar()
 if current_hp <= 0:
  await die()

func heal(amount: int) -> void:
 if not data:
  return
 current_hp = mini(data.max_hp, current_hp + amount)
 hp_changed.emit(current_hp)
 update_hp_bar()

func calculate_damage(target: Unit) -> int:
 if not data or not target.data:
  return 0
 var base_damage = data.attack + data.magic
 var variation = randf_range(0.85, 1.15)
 return int(base_damage * variation)

func die() -> void:
 var tween = create_tween()
 tween.tween_property(self, "modulate:a", 0.0, 0.5)
 await tween.finished
 queue_free()

func update_hp_bar() -> void:
 if hp_bar and data:
  hp_bar.max_value = data.max_hp
  hp_bar.value = current_hp

func get_grid_center() -> Vector2:
 return position + Vector2(16, 16)

func move_to(new_grid_pos: Vector2i, pixel_pos: Vector2) -> void:
 grid_position = new_grid_pos
 var tween = create_tween()
 tween.tween_property(self, "position", pixel_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
 await tween.finished
