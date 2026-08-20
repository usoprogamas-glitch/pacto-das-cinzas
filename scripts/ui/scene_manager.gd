extends Node

signal scene_change_requested(scene_name: String)

enum SceneType { MAIN_MENU, BATTLE, VILLAGE, MAP_SELECT, SETTINGS }

var current_scene: String = "main_menu"
var scenes: Dictionary = {
 "main_menu": "res://scenes/menu/main_menu.tscn",
 "battle": "res://scenes/battle/battle_scene.tscn",
 "village": "res://scenes/village/village_scene.tscn",
 "map_select": "res://scenes/menu/map_select.tscn",
 "settings": "res://scenes/menu/settings.tscn"
}

func _ready() -> void:
 pass

func change_scene(scene_name: String) -> void:
 if scenes.has(scene_name):
  current_scene = scene_name
  scene_change_requested.emit(scene_name)
  get_tree().change_scene_to_file(scenes[scene_name])

func go_to_main_menu() -> void:
 change_scene("main_menu")

func go_to_battle(map_id: int = 0) -> void:
 change_scene("battle")

func go_to_village() -> void:
 change_scene("village")

func go_to_map_select() -> void:
 change_scene("map_select")

func go_to_settings() -> void:
 change_scene("settings")
