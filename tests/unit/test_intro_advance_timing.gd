extends "res://addons/gut/test.gd"
## Regressão: o auto-advance da narração rodava no FRAME SEGUINTE (tween sem
## intervalo) → os 13 slides passavam em ~0.2s e o jogo caía direto na tela de
## escolha. Agora cada slide de narração espera AUTO_ADVANCE_SECONDS.

func test_auto_advance_waits_before_advancing():
	var story = load("res://scripts/ui/intro_story.gd").new()
	add_child_autofree(story)  # _ready → setup_story + show_current_step (1 tween)

	await wait_seconds(0.4)    # bem antes de AUTO_ADVANCE_SECONDS (3.5)
	assert_eq(story.current_step, 0, "slide de narração ainda em tela após 0.4s")

	await wait_seconds(3.3)    # 0.4 + 3.3 = 3.7 > 3.5 (margem)
	assert_eq(story.current_step, 1, "avançou para o slide 1 só depois do intervalo")