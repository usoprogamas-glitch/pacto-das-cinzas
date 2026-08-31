class_name SceneManagerClass
extends Node

signal scene_change_requested(scene_name: String)

enum SceneType { INTRO, MAIN_MENU, BATTLE, VILLAGE, MAP_SELECT, SETTINGS, EPILOGUE }

var current_scene: String = "intro"
var scenes: Dictionary = {
 "intro": "res://scenes/ui/intro_story.tscn",
 "main_menu": "res://scenes/menu/main_menu.tscn",
 "battle": "res://scenes/battle/battle_scene.tscn",
 "village": "res://scenes/village/village_scene.tscn",
 "map_select": "res://scenes/menu/map_select.tscn",
 "settings": "res://scenes/menu/settings.tscn",
 "epilogue": "res://scenes/ui/epilogue.tscn",
 "act_cutscene": "res://scenes/ui/act_cutscene.tscn"
 }

func _ready() -> void:
 pass

func change_scene(scene_name: String) -> void:
 if scenes.has(scene_name):
  current_scene = scene_name
  scene_change_requested.emit(scene_name)
  get_tree().change_scene_to_file(scenes[scene_name])

func go_to_intro() -> void:
 change_scene("intro")

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

func go_to_epilogue() -> void:
 change_scene("epilogue")
