class_name SceneManagerClass
extends Node

signal scene_change_requested(scene_name: String)

enum SceneType { INTRO, MAIN_MENU, BATTLE, VILLAGE, MAP_SELECT, SETTINGS, EPILOGUE }

var current_scene: String = "intro"
var scenes: Dictionary = {
 "intro": "res://scenes/intro_story.tscn",
 "main_menu": "res://scenes/main_menu.tscn",
 "battle": "res://scenes/battle_scene.tscn",
 "explore": "res://scenes/explore_scene.tscn",
 "settings": "res://scenes/settings.tscn",
 "epilogue": "res://scenes/epilogue.tscn",
 "act_cutscene": "res://scenes/act_cutscene.tscn"
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
 change_scene("explore")

func go_to_explore() -> void:
 change_scene("explore")

func go_to_settings() -> void:
 change_scene("settings")

func go_to_epilogue() -> void:
 change_scene("epilogue")
