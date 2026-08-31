extends "res://addons/gut/test.gd"
## Testes GUT: troca de sprite na evolução de forma (P0-3 da auditoria)
## Bug: form_changed aplicava stats mas NUNCA trocava o sprite — Kael ficava
## Imp Menor o jogo inteiro apesar dos 4 pngs de forma existirem.

const BattleSceneScript := preload("res://scripts/battle_scene.gd")

var bs: Node

class FakeGrid:
	extends RefCounted
	func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
		return Vector2(grid_pos.x * 32, grid_pos.y * 32)

func before_each():
	bs = BattleSceneScript.new()
	bs.setup_systems()
	bs.set("grid", FakeGrid.new())
	bs.set("unit_container", Node2D.new())
	BattleManager.player_units.clear()
	BattleManager.enemy_units.clear()

func after_each():
	BattleManager.player_units.clear()
	BattleManager.enemy_units.clear()
	var container = bs.get("unit_container")
	if is_instance_valid(container):
		container.free()
	if is_instance_valid(bs):
		bs.free()

func _spawn_kael() -> Unit:
	return bs.spawn_player_unit(Vector2i(2, 6), "Kael", Color(0.2, 0.8, 0.3), "Imp Menor", 80, 12, 8, 3, 1)

func _kael_sprite(unit: Unit) -> Sprite2D:
	return bs._find_unit_sprite(unit)

func test_form_change_swaps_kael_sprite():
	var kael = _spawn_kael()
	var tex_before = _kael_sprite(kael).texture
	bs._on_protagonist_form_changed("Imp Menor", "Nobre Abissal")
	var sprite: Sprite2D = _kael_sprite(kael)
	assert_not_null(sprite.texture)
	assert_ne(sprite.texture, tex_before, "textura trocou para a forma nova")

func test_swapped_sprite_stays_normalized_to_tile():
	var kael = _spawn_kael()
	bs._on_protagonist_form_changed("Imp Menor", "Nobre Abissal")
	var sprite: Sprite2D = _kael_sprite(kael)
	var effective: float = sprite.texture.get_width() * sprite.scale.x
	assert_almost_eq(effective, BattleGrid.TILE_SIZE, 0.01, "forma nova também em 32px")

func test_each_form_has_own_texture():
	var kael = _spawn_kael()
	var seen := {}
	for form in ["Imp Menor", "Nobre Abissal", "Arquidemônio", "Avatar Primordial"]:
		bs._on_protagonist_form_changed("Imp Menor", form)
		seen[form] = _kael_sprite(kael).texture
	assert_ne(seen["Imp Menor"], seen["Nobre Abissal"])
	assert_ne(seen["Nobre Abissal"], seen["Avatar Primordial"])
	assert_ne(seen["Arquidemônio"], seen["Avatar Primordial"])

func test_swap_reuses_same_sprite_node():
	# Animator guarda referência do NÓ — swap troca textura, não o nó.
	var kael = _spawn_kael()
	var node_before: Sprite2D = _kael_sprite(kael)
	bs._on_protagonist_form_changed("Imp Menor", "Nobre Abissal")
	assert_eq(_kael_sprite(kael), node_before, "nó preservado (analyzer não perde ref)")

func test_swap_with_missing_png_keeps_current_texture():
	var kael = _spawn_kael()
	var tex_before = _kael_sprite(kael).texture
	bs._swap_protagonist_sprite(kael, "Forma Sem Png")
	assert_eq(_kael_sprite(kael).texture, tex_before, "png ausente → textura mantida")

func test_non_kael_units_keep_sprite():
	var kael = _spawn_kael()
	var kroug = bs.spawn_player_unit(Vector2i(1, 7), "Kroug", Color(0.8, 0.3, 0.1), "Goblin da Lama", 120, 10, 15, 2, 1)
	var kroug_tex = _kael_sprite(kroug).texture
	bs._on_protagonist_form_changed("Imp Menor", "Nobre Abissal")
	assert_eq(_kael_sprite(kroug).texture, kroug_tex, "só o Kael evolui")
