extends "res://addons/gut/test.gd"

## Testes GUT para LightPuzzleSystem (Puzzles de Luz e Eclipse, GDD v2 §6.3)


func test_start_puzzle():
	var lps = LightPuzzleSystem.new()
	var result = lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	assert_eq(result, true, "Puzzle iniciado com sucesso")


func test_invalid_puzzle_type():
	var lps = LightPuzzleSystem.new()
	var result = lps.start_puzzle("p1", "invalid_type", Vector2i(0, 0), Vector2i(5, 0))
	assert_eq(result, false, "Tipo inválido retorna false")


func test_add_mirror():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0))
	assert_eq(lps.get_mirror_count(), 1, "1 espelho adicionado")


func test_rotate_mirror():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 0)
	var new_angle = lps.rotate_mirror("m1", 1)
	assert_eq(new_angle, 1, "Ângulo = 1 (45°)")


func test_rotate_mirror_invalid():
	var lps = LightPuzzleSystem.new()
	var result = lps.rotate_mirror("nonexistent", 1)
	assert_eq(result, -1, "Espelho inexistente retorna -1")


func test_mirror_aligned_correctly():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 0)
	## Espelho em (2,0), alvo em (5,0) = Leste = 90° = step 2
	lps.rotate_mirror("m1", 2)
	var mirror = lps.get_mirror("m1")
	assert_eq(mirror.aligned, true, "Espelho alinhado para Leste")


func test_mirror_not_aligned():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 0)
	## Espelho em (2,0), alvo em (5,0) = Leste, mas girou para Norte
	lps.rotate_mirror("m1", 0)
	var mirror = lps.get_mirror("m1")
	assert_eq(mirror.aligned, false, "Espelho não alinhado")


func test_clock_advance():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "eclipse_timing", Vector2i(0, 0), Vector2i(5, 0))
	var time = lps.advance_clock()
	assert_eq(time, 1, "Tempo = 1 após avanço")


func test_clock_wraps_around():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "eclipse_timing", Vector2i(0, 0), Vector2i(5, 0))
	for i in range(12):
		lps.advance_clock()
	var time = lps.get_clock_time()
	assert_eq(time, 0, "Relógio volta para 0 após 12 avanços")


func test_eclipse_at_time_3():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "eclipse_timing", Vector2i(0, 0), Vector2i(5, 0))
	lps.set_clock_time(3)
	assert_eq(lps.is_eclipse_active(), true, "Eclipse às 3h")


func test_eclipse_at_time_9():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "eclipse_timing", Vector2i(0, 0), Vector2i(5, 0))
	lps.set_clock_time(9)
	assert_eq(lps.is_eclipse_active(), true, "Eclipse às 9h")


func test_no_eclipse_other_times():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "eclipse_timing", Vector2i(0, 0), Vector2i(5, 0))
	lps.set_clock_time(5)
	assert_eq(lps.is_eclipse_active(), false, "Sem eclipse às 5h")


func test_puzzle_not_solved_initially():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 2)  ## Alinhado
	assert_eq(lps.check_solved(), false, "1 espelho não resolve (precisa de 2)")


func test_puzzle_solved_two_mirrors():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 2)  ## Alinhado
	lps.add_mirror("m2", Vector2i(4, 0), 2)  ## Alinhado
	assert_eq(lps.check_solved(), true, "2 espelhos alinhados = resolvido")


func test_complete_puzzle_signal():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 2)
	lps.add_mirror("m2", Vector2i(4, 0), 2)
	watch_signals(lps)
	lps.complete_puzzle({"key": "ancient_scroll"})
	assert_signal_emitted(lps, "puzzle_solved", "Sinal deve disparar")


func test_solved_puzzles_history():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 2)
	lps.add_mirror("m2", Vector2i(4, 0), 2)
	lps.complete_puzzle()
	var solved = lps.get_solved_puzzles()
	assert_eq(solved.size(), 1, "1 puzzle resolvido")
	assert_eq(solved[0], "p1", "ID = p1")


func test_mirror_aligned_signal():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "mirror_alignment", Vector2i(0, 0), Vector2i(5, 0))
	lps.add_mirror("m1", Vector2i(2, 0), 0)
	watch_signals(lps)
	lps.rotate_mirror("m1", 1)
	assert_signal_emitted(lps, "mirror_aligned", "Sinal deve disparar")


func test_eclipse_activated_signal():
	var lps = LightPuzzleSystem.new()
	lps.start_puzzle("p1", "eclipse_timing", Vector2i(0, 0), Vector2i(5, 0))
	watch_signals(lps)
	lps.set_clock_time(3)
	assert_signal_emitted(lps, "eclipse_activated", "Sinal deve disparar")
