class_name VisualEffects
extends Node2D

# Sistema de efeitos visuais estilo Sea of Stars

var particles: Array[CPUParticles2D] = []
var active_tweens: Array[Tween] = []

func _ready() -> void:
 pass

func create_hit_spark(position: Vector2, color: Color = Color.WHITE) -> void:
 var effect = SeaOfStarsStyle.effects.hit_spark
 create_particle_burst(position, effect.particles, effect.color, effect.lifetime, effect.size)

func create_magic_cast(position: Vector2, element: String) -> void:
 var effect = SeaOfStarsStyle.effects.magic_cast
 var color = SeaOfStarsStyle.get_element_color(element)
 create_particle_burst(position, effect.particles, color, effect.lifetime, effect.size)

func create_heal_effect(position: Vector2) -> void:
 var effect = SeaOfStarsStyle.effects.heal
 create_rising_particles(position, effect.particles, effect.color, effect.lifetime, effect.size)

func create_level_up_effect(position: Vector2) -> void:
 var effect = SeaOfStarsStyle.effects.level_up
 create_burst_particles(position, effect.particles, effect.color, effect.lifetime, effect.size)

func create_particle_burst(pos: Vector2, count: int, color: Color, lifetime: float, size: int) -> void:
 var batch: Array[CPUParticles2D] = []
 for i in range(count):
  var particle = CPUParticles2D.new()
  batch.append(particle)
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = lifetime
  particle.position = pos
  particle.color = color
  particle.scale_amount_min = size * 0.5
  particle.scale_amount_max = size * 1.5

  var angle = randf() * TAU
  var speed = randf_range(50, 150)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.5

  particle.gravity = Vector2(0, 200)
  particle.damping_min = 0.9
  particle.damping_max = 0.95

  add_child(particle)
  particles.append(particle)

 await get_tree().create_timer(lifetime).timeout
 for particle in batch:
  if is_instance_valid(particle):
   particle.queue_free()

func create_rising_particles(pos: Vector2, count: int, color: Color, lifetime: float, size: int) -> void:
 var batch: Array[CPUParticles2D] = []
 for i in range(count):
  var particle = CPUParticles2D.new()
  batch.append(particle)
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = lifetime
  particle.position = pos + Vector2(randf_range(-20, 20), 0)
  particle.color = color
  particle.scale_amount_min = size * 0.5
  particle.scale_amount_max = size * 1.5

  particle.direction = Vector2(0, -1)
  particle.initial_velocity_min = 30
  particle.initial_velocity_max = 60

  particle.gravity = Vector2(0, -50)
  particle.damping_min = 0.95
  particle.damping_max = 0.98

  add_child(particle)
  particles.append(particle)

 await get_tree().create_timer(lifetime).timeout
 for particle in batch:
  if is_instance_valid(particle):
   particle.queue_free()

func create_burst_particles(pos: Vector2, count: int, color: Color, lifetime: float, size: int) -> void:
 var batch: Array[CPUParticles2D] = []
 for i in range(count):
  var particle = CPUParticles2D.new()
  batch.append(particle)
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = lifetime
  particle.position = pos
  particle.color = color
  particle.scale_amount_min = size * 0.3
  particle.scale_amount_max = size * 2.0

  var angle = (float(i) / count) * TAU
  var speed = randf_range(100, 200)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.2

  particle.gravity = Vector2(0, 100)
  particle.damping_min = 0.92
  particle.damping_max = 0.96

  add_child(particle)
  particles.append(particle)

 await get_tree().create_timer(lifetime).timeout
 for particle in batch:
  if is_instance_valid(particle):
   particle.queue_free()

func create_damage_number(position: Vector2, damage: int, is_critical: bool = false) -> void:
 var label = Label.new()
 label.text = str(damage)
 label.position = position
 label.z_index = 100

 if is_critical:
  label.add_theme_font_size_override("font_size", 24)
  label.add_theme_color_override("font_color", Color("#FFD93D"))
 else:
  label.add_theme_font_size_override("font_size", 16)
  label.add_theme_color_override("font_color", Color("#FFFFFF"))

 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 40, 0.5)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
 await tween.finished
 label.queue_free()

func create_timed_hit_indicator(position: Vector2, grade: String) -> void:
 var color = Color(SeaOfStarsStyle.timed_hit[grade.to_lower()].color)
 var text = grade

 var label = Label.new()
 label.text = text
 label.position = position + Vector2(-30, -50)
 label.z_index = 100
 label.add_theme_font_size_override("font_size", 20)
 label.add_theme_color_override("font_color", color)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 80, 0.8)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
 await tween.finished
 label.queue_free()

func flash_sprite(sprite: Sprite2D, color: Color, duration: float = 0.1) -> void:
 if not sprite:
  return
 var original_color = sprite.modulate
 sprite.modulate = color
 await get_tree().create_timer(duration).timeout
 if is_instance_valid(sprite):
  sprite.modulate = original_color

func shake_node(node: Node2D, intensity: float = 5.0, duration: float = 0.2) -> void:
 if not node:
  return
 var original_pos = node.position
 var elapsed = 0.0

 while elapsed < duration:
  var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity
  node.position = original_pos + offset
  await get_tree().create_timer(0.02).timeout
  elapsed += 0.02

 if is_instance_valid(node):
  node.position = original_pos

func cleanup() -> void:
 for particle in particles:
  if is_instance_valid(particle):
   particle.queue_free()
 particles.clear()

 for tween in active_tweens:
  if tween and tween.is_valid():
   tween.kill()
 active_tweens.clear()
