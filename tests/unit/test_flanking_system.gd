extends "res://addons/gut/test.gd"

## Testes GUT para FlankingSystem (Flanqueamento +25%, GDD v2 §3)


# --- Detecção de flanqueamento ---

func test_is_flanking_from_behind():
	var fs = FlankingSystem.new()
	# Target moveu para baixo (0,1) → costas = cima (0,-1)
	# Attacker está em cima do target
	assert_true(fs.is_flanking(Vector2i(5, 4), Vector2i(5, 5), Vector2i(0, 1)),
		"Atacante pelas costas deve ser flanking")


func test_is_not_flanking_from_front():
	var fs = FlankingSystem.new()
	# Target moveu para baixo (0,1) → frente = baixo
	# Attacker está em baixo do target
	assert_false(fs.is_flanking(Vector2i(5, 6), Vector2i(5, 5), Vector2i(0, 1)),
		"Atacante pela frente não é flanking")


func test_is_not_flanking_from_side():
	var fs = FlankingSystem.new()
	# Target moveu para baixo (0,1) → lado = esquerda/direita
	assert_false(fs.is_flanking(Vector2i(4, 5), Vector2i(5, 5), Vector2i(0, 1)),
		"Atacante pelo lado não é flanking")


func test_no_flanking_when_no_movement():
	var fs = FlankingSystem.new()
	# Target nunca moveu (0,0)
	assert_false(fs.is_flanking(Vector2i(5, 4), Vector2i(5, 5), Vector2i.ZERO),
		"Sem movimento prévio = sem flanqueamento")


func test_flanking_from_right():
	var fs = FlankingSystem.new()
	# Target moveu para esquerda (-1,0) → costas = direita (1,0)
	assert_true(fs.is_flanking(Vector2i(6, 5), Vector2i(5, 5), Vector2i(-1, 0)),
		"Flanqueamento pela direita quando target moveu à esquerda")


func test_flanking_from_left():
	var fs = FlankingSystem.new()
	# Target moveu para direita (1,0) → costas = esquerda (-1,0)
	assert_true(fs.is_flanking(Vector2i(4, 5), Vector2i(5, 5), Vector2i(1, 0)),
		"Flanqueamento pela esquerda quando target moveu à direita")


# --- Multiplicador ---

func test_multiplier_with_flanking():
	var fs = FlankingSystem.new()
	assert_eq(fs.get_flanking_multiplier(true), 1.25, "Flanking = 1.25x")


func test_multiplier_without_flanking():
	var fs = FlankingSystem.new()
	assert_eq(fs.get_flanking_multiplier(false), 1.0, "Sem flanking = 1.0x")


# --- Null safety ---

func test_check_flanking_null_attacker():
	var fs = FlankingSystem.new()
	assert_false(fs.check_flanking(null, Vector2i(5, 5)), "Null attacker = false")


func test_check_flanking_null_target():
	var fs = FlankingSystem.new()
	assert_false(fs.check_flanking(Vector2i(5, 4), null), "Null target = false")
