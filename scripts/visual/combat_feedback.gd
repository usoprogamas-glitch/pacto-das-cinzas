class_name CombatFeedback
extends Node2D

# Sistema de feedback visual para combate
# - Números de dano flutuantes
- Flash de dano
- Partículas de impacto
- Screen shake
- Slow motion

func show_damage_number(position: Vector2, damage: int, is_critical: bool = false, is_heal: bool = false) -> void:
 var label = Label.new()
 label.position = position + Vector2(randf_range(-10, 10), -20)
 label.z_index = 100

 if is_heal:
  label.text = "+%d" % damage
  label.add_theme_color_override("font_color", Color("#76FF03"))
 elif is_critical:
  label.text = "%d!" % damage
  label.add_theme_color_override("font_color", Color("#FFD93D"))
  label.add_theme_font_size_override("font_size", 24)
 else:
  label.text = str(damage)
  label.add_theme_color_override("font_color", Color("#FF5252"))

 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)

 add_child(label)

 # Animação
 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 60, 0.8)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
 tween.tween_callback(label.queue_free)

func show_damage_number_with_grade(position: Vector2, damage: int, grade: String) -> void:
 var grade_colors = {
  "PERFECT": Color("#FFD93D"),
  "GREAT": Color("#4CAF50"),
  "GOOD": Color("#2196F3"),
  "MISS": Color("#FF5252")
 }

 var label = Label.new()
 label.position = position + Vector2(randf_range(-15, 15), -30)
 label.z_index = 100
 label.text = "%s %d" % [grade, damage]
 label.add_theme_color_override("font_color", grade_colors.get(grade, Color.WHITE))
 label.add_theme_font_size_override("font_size", 20)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 80, 1.0)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.4)
 tween.tween_callback(label.queue_free)

func flash_unit(unit: Node2D, color: Color = Color.WHITE, duration: float = 0.1) -> void:
 if not unit:
  return

 var original_modulate = unit.modulate
 unit.modulate = color

 var tween = create_tween()
 tween.tween_property(unit, "modulate", original_modulate, duration)

func shake_screen(camera: Camera2D, intensity: float = 5.0, duration: float = 0.2) -> void:
 if not camera:
  return

 var original_position = camera.position
 var elapsed = 0.0

 while elapsed < duration:
  var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity
  camera.position = original_position + offset
  await get_tree().create_timer(0.02).timeout
  elapsed += 0.02

 camera.position = original_position

func spawn_hit_particles(position: Vector2, color: Color = Color.WHITE) -> void:
 for i in range(8):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = 0.3
  particle.position = position
  particle.color = color
  particle.scale_amount_min = 2
  particle.scale_amount_max = 4

  var angle = randf() * TAU
  var speed = randf_range(50, 150)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.5

  particle.gravity = Vector2(0, 200)

  add_child(particle)

  await get_tree().create_timer(0.3).timeout
  if is_instance_valid(particle):
   particle.queue_free()

func spawn_magic_particles(position: Vector2, element: String) -> void:
 var colors = {
  "fire": Color("#FF6B35"),
  "water": Color("#00BCD4"),
  "earth": Color("#8BC34A"),
  "air": Color("#E0F7FA"),
  "shadow": Color("#9C27B0"),
  "light": Color("#FFEB3B")
 }

 var color = colors.get(element, Color.WHITE)

 for i in range(12):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = 0.5
  particle.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
  particle.color = color
  particle.scale_amount_min = 3
  particle.scale_amount_max = 6

  particle.direction = Vector2(0, -1)
  particle.initial_velocity_min = 30
  particle.initial_velocity_max = 60

  particle.gravity = Vector2(0, -50)

  add_child(particle)

  await get_tree().create_timer(0.5).timeout
  if is_instance_valid(particle):
   particle.queue_free()

func spawn_heal_particles(position: Vector2) -> void:
 for i in range(10):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = 0.8
  particle.position = position + Vector2(randf_range(-15, 15), 0)
  particle.color = Color("#76FF03")
  particle.scale_amount_min = 4
  particle.scale_amount_max = 8

  particle.direction = Vector2(0, -1)
  particle.initial_velocity_min = 20
  particle.initial_velocity_max = 40

  particle.gravity = Vector2(0, -30)

  add_child(particle)

  await get_tree().create_timer(0.8).timeout
  if is_instance_valid(particle):
   particle.queue_free()

func spawn_level_up_effect(position: Vector2) -> void:
 for i in range(20):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = 1.0
  particle.position = position
  particle.color = Color("#FFD93D")
  particle.scale_amount_min = 3
  particle.scale_amount_max = 8

  var angle = (float(i) / 20) * TAU
  var speed = randf_range(80, 150)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.2

  particle.gravity = Vector2(0, 100)

  add_child(particle)

  await get_tree().create_timer(1.0).timeout
  if is_instance_valid(particle):
   particle.queue_free()

func show_status_effect(position: Vector2, effect_name: String) -> void:
 var colors = {
  "burning": Color("#FF6B35"),
  "frozen": Color("#00BCD4"),
  "poisoned": Color("#9C27B0"),
  "stunned": Color("#FFEB3B"),
  "healing": Color("#76FF03")
 }

 var label = Label.new()
 label.position = position + Vector2(-30, -40)
 label.z_index = 100
 label.text = effect_name.to_upper()
 label.add_theme_color_override("font_color", colors.get(effect_name.to_lower(), Color.WHITE))
 label.add_theme_font_size_override("font_size", 12)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 1)
 label.add_theme_constant_override("shadow_offset_y", 1)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 60, 0.6)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
 tween.tween_callback(label.queue_free)
