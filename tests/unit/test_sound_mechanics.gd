extends "res://addons/gut/test.gd"

## SFX procedurais das mecânicas §6-7 (AUDIT áudio): 7 sons novos
## (forja, lock hit/break, puzzle, travessia, aposta win/lose) gerados
## determinísticamente e expostos via play_*.

const SoundLib = preload("res://scripts/sound_manager.gd")


func test_all_mechanic_sounds_generated():
	var sm = SoundLib.new()
	# _ready roda generate_placeholder_sounds só na árvore; chama direto.
	sm.generate_placeholder_sounds()
	for sound_name in ["forge", "lock_hit", "lock_break", "puzzle", "traversal", "bet_win", "bet_lose"]:
		assert_true(sm.sounds.has(sound_name), "sfx '%s' gerado" % sound_name)
		var stream = sm.sounds[sound_name]
		assert_not_null(stream, "stream de '%s' não nulo" % sound_name)
		assert_gt(stream.data.size(), 100, "stream de '%s' tem conteúdo" % sound_name)


func test_play_helpers_do_not_crash_off_tree():
	var sm = SoundLib.new()
	sm.generate_placeholder_sounds()
	# Sem árvore os players não existem; play_sfx deve no-op sem erro.
	for helper in ["play_forge", "play_lock_hit", "play_lock_break", "play_puzzle", "play_traversal", "play_bet_win", "play_bet_lose"]:
		assert_true(sm.has_method(helper), "helper %s existe" % helper)
		sm.call(helper)  # não deve lançar


func test_sound_streams_are_valid_wav():
	var forge: AudioStreamWAV = SoundLib.create_forge_sound()
	assert_eq(forge.mix_rate, 22050, "taxa padrão 22050")
	assert_eq(forge.format, AudioStreamWAV.FORMAT_16_BITS, "formato 16 bits")
	assert_gt(forge.data.size(), 7000, "0.35s a 22050 Hz = ~7.7k amostras x 2 bytes")
