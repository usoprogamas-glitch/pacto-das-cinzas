class_name TimedHitSystem
extends Node

signal timed_hit_result(grade: String, bonus: float)
signal timing_started(window_duration: float)
signal timing_ended()

var is_active: bool = false
var timing_window: float = 0.0
var elapsed_time: float = 0.0
var attack_power: float = 1.0

func start_timing(window: float = 0.3) -> void:
 is_active = true
 timing_window = window
 elapsed_time = 0.0
 timing_started.emit(window)

func _process(delta: float) -> void:
 if not is_active:
  return

 elapsed_time += delta

 if Input.is_action_just_pressed("select"):
  check_timing()

func check_timing() -> void:
 if not is_active:
  return

 var result = SeaOfStarsStyle.calculate_timed_hit_bonus(elapsed_time)
 attack_power = result.bonus
 is_active = false

 timed_hit_result.emit(result.grade, result.bonus)
 timing_ended.emit()

func cancel() -> void:
 is_active = false
 attack_power = 0.5
 timing_ended.emit()

func get_attack_multiplier() -> float:
 return attack_power

func reset() -> void:
 is_active = false
 elapsed_time = 0.0
 attack_power = 1.0
