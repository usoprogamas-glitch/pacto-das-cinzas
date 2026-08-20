class_name UnitSprite
extends Node2D

@export var unit_color: Color = Color.WHITE
@export var unit_size: int = 28

var body: ColorRect
var eyes: ColorRect
var weapon: ColorRect
var shadow: ColorRect

func _ready() -> void:
 create_visuals()

func create_visuals() -> void:
 shadow = ColorRect.new()
 shadow.color = Color(0, 0, 0, 0.3)
 shadow.position = Vector2(-unit_size/2 + 2, unit_size/2 - 4)
 shadow.size = Vector2(unit_size - 4, 6)
 add_child(shadow)

 body = ColorRect.new()
 body.color = unit_color
 body.position = Vector2(-unit_size/2, -unit_size/2)
 body.size = Vector2(unit_size, unit_size)
 add_child(body)

 var eye_size = 4
 eyes = ColorRect.new()
 eyes.color = Color.WHITE
 eyes.position = Vector2(-eye_size, -eye_size/2)
 eyes.size = Vector2(eye_size * 2, eye_size)
 add_child(eyes)

 weapon = ColorRect.new()
 weapon.color = unit_color.darkened(0.3)
 weapon.position = Vector2(unit_size/2 - 2, -unit_size/4)
 weapon.size = Vector2(4, unit_size/2)
 add_child(weapon)

func set_color(color: Color) -> void:
 unit_color = color
 if body:
  body.color = color
 if weapon:
  weapon.color = color.darkened(0.3)

func play_hit_animation() -> void:
 var tween = create_tween()
 tween.tween_property(self, "position:x", position.x + 5, 0.05)
 tween.tween_property(self, "position:x", position.x - 5, 0.05)
 tween.tween_property(self, "position:x", position.x, 0.05)

func play_death_animation() -> void:
 var tween = create_tween()
 tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
 tween.parallel().tween_property(self, "modulate", Color.RED, 0.1)
 tween.tween_property(self, "scale", Vector2(0, 0), 0.3)
 tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
 await tween.finished
 queue_free()

func play_spawn_animation() -> void:
 scale = Vector2(0, 0)
 modulate.a = 0.0
 var tween = create_tween()
 tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
 tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

func set_selected(selected: bool) -> void:
 if selected:
  modulate = Color(1.2, 1.2, 1.2)
 else:
  modulate = Color.WHITE

func get_attack_position() -> Vector2:
 return global_position + Vector2(unit_size/2 + 10, 0)
