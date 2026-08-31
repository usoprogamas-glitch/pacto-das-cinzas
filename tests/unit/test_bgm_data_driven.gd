extends "res://addons/gut/test.gd"
## Testes GUT: BGM data-driven (P0-4 da auditoria)
## Bugs: play_music() nunca setava stream (tocava silêncio) e ninguém a chamava —
## o campo "music" do MapDatabase era dado morto.

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node

func before_each():
	bs = BattleSceneScript.new()
	bs.setup_systems()
	BattleManager.player_units.clear()
	BattleManager.enemy_units.clear()

func after_each():
	BattleManager.player_units.clear()
	BattleManager.enemy_units.clear()
	if is_instance_valid(bs):
		bs.free()
	SoundManager.music_player.stop()
	SoundManager.music_player.stream = null

# === play_music toca de verdade ===

func test_play_music_exploration_sets_stream_and_plays():
	SoundManager.play_music("exploration")
	assert_not_null(SoundManager.music_player.stream, "stream definido (antes era null)")
	assert_true(SoundManager.music_player.playing, "BGM tocando")

func test_play_music_battle_sets_stream_and_plays():
	SoundManager.play_music("battle")
	assert_not_null(SoundManager.music_player.stream)
	assert_true(SoundManager.music_player.playing)

func test_play_music_loops_forever():
	SoundManager.play_music("exploration")
	var stream: AudioStreamWAV = SoundManager.music_player.stream
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "loop infinito")
	assert_eq(stream.loop_begin, 0)

func test_same_track_does_not_restart():
	SoundManager.play_music("exploration")
	var pos_after_first = SoundManager.music_player.get_playback_position()
	SoundManager.play_music("exploration")
	# Mesma faixa: stream não é reiniciado (posição segue de onde estava)
	assert_true(SoundManager.music_player.get_playback_position() >= pos_after_first,
		"mesma faixa não reinicia")

func test_unknown_track_is_noop():
	SoundManager.play_music("jazz_fusion_9000")
	assert_false(SoundManager.music_player.playing, "faixa desconhecida → silêncio, sem crash")

func test_tracks_are_cached():
	var first = SoundManager._get_or_create_music("exploration")
	var second = SoundManager._get_or_create_music("exploration")
	assert_eq(first, second, "mesmo stream reutilizado (sem regenerar a cada chamada)")

# === setup_battle lê o campo "music" do mapa ===

func test_setup_battle_starts_map_bgm():
	GameManager.game_data["current_map"] = 3  # Castelo Solaris: "battle"
	bs.setup_battle()
	assert_eq(SoundManager.music_player.stream, SoundManager._get_or_create_music("battle"),
		"BGM da batalha = faixa do mapa")
	GameManager.game_data["current_map"] = 0  # Fronteira Cinzenta: "exploration"
	bs.setup_battle()
	assert_eq(SoundManager.music_player.stream, SoundManager._get_or_create_music("exploration"),
		"BGM do mapa 0 = exploração")

func test_every_map_has_known_music_track():
	# Contrato data-driven: todo mapa aponta para uma faixa que existe.
	for map_id in MapDatabase.maps.keys():
		var track: String = MapDatabase.maps[map_id].get("music", "")
		assert_true(track in ["exploration", "battle"],
			"mapa %d: track '%s' conhecida" % [map_id, track])
