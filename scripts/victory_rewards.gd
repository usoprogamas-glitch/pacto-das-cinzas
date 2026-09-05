class_name VictoryRewards
extends Resource

@export var soul_ether: int = 0
@export var gold: int = 0
@export var xp: int = 0
@export var captured_souls: Array[Dictionary] = []
@export var unlocks: Array[String] = []

func _init(
 p_soul_ether: int = 0,
 p_gold: int = 0,
 p_xp: int = 0,
 p_captured_souls: Array = [],
 p_unlocks: Array = []
) -> void:
 soul_ether = p_soul_ether
 gold = p_gold
 xp = p_xp
 for soul in p_captured_souls:
  captured_souls.append(soul)
 for unlock in p_unlocks:
  unlocks.append(String(unlock))