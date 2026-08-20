class_name SceneTransition
extends CanvasLayer

signal transition_started()
signal transition_midpoint()
signal transition_completed()

var is_transitioning: bool = false

func _ready() -> void:
 layer = 200

func fade_to_scene(scene_path: String, duration: float = 0.5) -> void:
 if is_transitioning:
  return

 is_transitioning = true
 transition_started.emit()

 # Fade to black
 await fade_to_black(duration / 2)
 transition_midpoint.emit()

 # Mudar cena
 get_tree().change_scene_to_file(scene_path)

 # Fade from black
 await fade_from_black(duration / 2)

 is_transitioning = false
 transition_completed.emit()

func fade_to_black(duration: float = 0.5) -> void:
 var fade = ColorRect.new()
 fade.color = Color.BLACK
 fade.anchors_preset = 15
 fade.anchor_right = 1.0
 fade.anchor_bottom = 1.0
 fade.grow_horizontal = 2
 fade.grow_vertical = 2
 fade.z_index = 999
 fade.modulate.a = 0.0

 add_child(fade)

 var tween = create_tween()
 tween.tween_property(fade, "modulate:a", 1.0, duration)
 await tween.finished

func fade_from_black(duration: float = 0.5) -> void:
 var fade = ColorRect.new()
 fade.color = Color.BLACK
 fade.anchors_preset = 15
 fade.anchor_right = 1.0
 fade.anchor_bottom = 1.0
 fade.grow_horizontal = 2
 fade.grow_vertical = 2
 fade.z_index = 999
 fade.modulate.a = 1.0

 add_child(fade)

 var tween = create_tween()
 tween.tween_property(fade, "modulate:a", 0.0, duration)
 tween.tween_callback(fade.queue_free)

func iris_transition(scene_path: String, center: Vector2 = Vector2(640, 360), duration: float = 0.8) -> void:
 if is_transitioning:
  return

 is_transitioning = true
 transition_started.emit()

 # Criar máscara circular
 var mask = ColorRect.new()
 mask.color = Color.BLACK
 mask.anchors_preset = 15
 mask.anchor_right = 1.0
 mask.anchor_bottom = 1.0
 mask.grow_horizontal = 2
 mask.grow_vertical = 2
 mask.z_index = 999
 mask.modulate.a = 0.0

 add_child(mask)

 # Animação de iris
 var tween = create_tween()
 tween.tween_property(mask, "modulate:a", 1.0, duration / 2)
 await tween.finished

 transition_midpoint.emit()
 get_tree().change_scene_to_file(scene_path)

 # Iris out
 var mask2 = ColorRect.new()
 mask2.color = Color.BLACK
 mask2.anchors_preset = 15
 mask2.anchor_right = 1.0
 mask2.anchor_bottom = 1.0
 mask2.grow_horizontal = 2
 mask2.grow_vertical = 2
 mask2.z_index = 999
 mask2.modulate.a = 1.0

 add_child(mask2)

 var tween2 = create_tween()
 tween2.tween_property(mask2, "modulate:a", 0.0, duration / 2)
 tween2.tween_callback(mask2.queue_free)

 is_transitioning = false
 transition_completed.emit()

func slide_transition(scene_path: String, direction: String = "left", duration: float = 0.5) -> void:
 if is_transitioning:
  return

 is_transitioning = true
 transition_started.emit()

 # Slide out
 var slide_out = ColorRect.new()
 slide_out.color = Color.BLACK
 slide_out.anchors_preset = 15
 slide_out.anchor_right = 1.0
 slide_out.anchor_bottom = 1.0
 slide_out.grow_horizontal = 2
 slide_out.grow_vertical = 2
 slide_out.z_index = 999

 add_child(slide_out)

 var tween = create_tween()
 match direction:
  "left":
   slide_out.position.x = 1280
   tween.tween_property(slide_out, "position:x", 0, duration / 2)
  "right":
   slide_out.position.x = -1280
   tween.tween_property(slide_out, "position:x", 0, duration / 2)
  "up":
   slide_out.position.y = 720
   tween.tween_property(slide_out, "position:y", 0, duration / 2)
  "down":
   slide_out.position.y = -720
   tween.tween_property(slide_out, "position:y", 0, duration / 2)

 await tween.finished
 transition_midpoint.emit()
 get_tree().change_scene_to_file(scene_path)

 # Slide in
 var slide_in = ColorRect.new()
 slide_in.color = Color.BLACK
 slide_in.anchors_preset = 15
 slide_in.anchor_right = 1.0
 slide_in.anchor_bottom = 1.0
 slide_in.grow_horizontal = 2
 slide_in.grow_vertical = 2
 slide_in.z_index = 999

 add_child(slide_in)

 var tween2 = create_tween()
 match direction:
  "left":
   tween2.tween_property(slide_in, "position:x", -1280, duration / 2)
  "right":
   tween2.tween_property(slide_in, "position:x", 1280, duration / 2)
  "up":
   tween2.tween_property(slide_in, "position:y", -720, duration / 2)
  "down":
   tween2.tween_property(slide_in, "position:y", 720, duration / 2)

 tween2.tween_callback(slide_in.queue_free)

 is_transitioning = false
 transition_completed.emit()
