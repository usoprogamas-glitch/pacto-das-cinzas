extends "res://addons/gut/test.gd"

## Caixa de diálogo réplica SoS: placa de nome âmbar acima da caixa +
## palavras-chave coloridas (lore âmbar, recursos ciano) no RichTextLabel.

const ExploreScript := preload("res://scripts/explore_scene.gd")

var _explore: Node


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	if _explore and is_instance_valid(_explore):
		_explore.free()
	_explore = null


func test_highlight_colors_lore_and_resources():
	var out: String = _explore_highlight("Kael pactua com Kroug e ganha 10 ouro de éter.")
	assert_true(out.contains("[color=#f0a838]Kael[/color]"), "lore em âmbar")
	assert_true(out.contains("[color=#f0a838]Kroug[/color]"), "companheiro em âmbar")
	assert_true(out.contains("[color=#7ec8e3]ouro[/color]"), "recurso em ciano")
	assert_true(out.contains("[color=#7ec8e3]éter[/color]"), "éter em ciano")


func test_highlight_escapes_brackets():
	var out: String = _explore_highlight("receita [teste]")
	assert_true(out.contains("[lb]teste[rb]"), "colchetes escapados para [lb]/[rb]")


func test_highlight_is_noop_for_plain_text():
	var out: String = _explore_highlight("Vento frio na planície.")
	assert_eq(out, "Vento frio na planície.", "texto sem keywords intacto")


func _explore_highlight(text: String) -> String:
	_explore = ExploreScript.new()
	add_child_autofree(_explore)
	return _explore._highlight_keywords(text)


func test_dialogue_box_has_name_plate_and_rich_text():
	_explore = add_child_autofree(ExploreScript.new())
	_explore._npc_current_id = "brugaves_fronteira"
	_explore.dialogue.start("brugaves_fronteira", false)
	_explore._npc_portrait = String(load("res://scripts/dialogue_system.gd").DIALOGUES.get("brugaves_fronteira", {}).get("portrait", ""))
	_explore._open_dialogue_box()
	assert_not_null(_explore._dialogue_name_plate, "placa de nome existe")
	assert_not_null(_explore._dialogue_label, "label rico existe")
	assert_true(_explore._dialogue_label.bbcode_enabled, "bbcode habilitado")
	assert_true(_explore._dialogue_label.text.length() > 0, "1ª página visível na abertura")
	assert_true(_explore._dialogue_label.text.contains("[color="), "página colorizada")
	_explore._close_dialogue_box()
	assert_null(_explore._dialogue_name_plate, "placa liberada ao fechar")
