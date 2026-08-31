extends "res://addons/gut/test.gd"
## Menu de Opções (settings.tscn). Regression: o botão "Opções" do main_menu
## apontava para scenes/menu/settings.tscn que NÃO existia → change_scene_to_file
## com path inexistente = crash. Agora existe e abre.

var _packed: PackedScene = load("res://scenes/settings.tscn")
var _inst: Node


func after_each() -> void:
	if _inst:
		_inst.free()
		_inst = null


func _open() -> Node:
	# fora da árvore → _ready não roda (sem tocar AudioServer/DisplayServer no teste)
	_inst = _packed.instantiate()
	return _inst


func test_scene_loads():
	assert_not_null(_packed, "settings.tscn deve existir (botão Opções aponta pra ele)")


func test_scene_has_expected_nodes():
	var node = _open()
	assert_not_null(node.get_node("VBoxContainer/VolumeBox/VolumeSlider"), "slider de volume")
	assert_not_null(node.get_node("VBoxContainer/VolumeBox/VolumeValue"), "label do valor")
	assert_not_null(node.get_node("VBoxContainer/FullscreenCheck"), "check de tela cheia")
	assert_not_null(node.get_node("VBoxContainer/BackButton"), "botão voltar")


func test_settings_script_attached_and_maps_back():
	var node = _open()
	assert_not_null(node.get_script(), "script de settings deve estar anexado")

	# _on_back usa SceneManager.go_to_main_menu — valida que o path main_menu existe
	var sm_prefab = load("res://scripts/scene_manager.gd").new()
	assert_has(sm_prefab.scenes, "main_menu", "SceneManager deve mapear main_menu")
	assert_has(sm_prefab.scenes, "settings", "SceneManager deve mapear settings (apontado pelo menu)")
	assert_true(ResourceLoader.exists(sm_prefab.scenes.settings), "path de settings deve existir no disco")