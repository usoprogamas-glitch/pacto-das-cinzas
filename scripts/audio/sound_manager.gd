class_name SoundManager
extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}

func _ready() -> void:
 music_player = AudioStreamPlayer.new()
 add_child(music_player)

 for i in range(8):
  var player = AudioStreamPlayer.new()
  add_child(player)
  sfx_players.append(player)

 generate_placeholder_sounds()

func generate_placeholder_sounds() -> void:
 sounds = {
  "hit": SoundGenerator.create_hit_sound(),
  "magic": SoundGenerator.create_magic_sound(),
  "heal": SoundGenerator.create_heal_sound(),
  "click": SoundGenerator.create_click_sound(),
  "select": SoundGenerator.create_select_sound(),
  "victory": SoundGenerator.create_victory_sound(),
  "defeat": SoundGenerator.create_defeat_sound(),
  "step": SoundGenerator.create_step_sound(),
  "death": SoundGenerator.create_death_sound()
 }

func play_sfx(sound_name: String) -> void:
 if not sounds.has(sound_name):
  return

 for player in sfx_players:
  if not player.playing:
   player.stream = sounds[sound_name]
   player.play()
   return

 sfx_players[0].stream = sounds[sound_name]
 sfx_players[0].play()

func play_sfx_with_pitch(sound_name: String, pitch: float) -> void:
 if not sounds.has(sound_name):
  return

 for player in sfx_players:
  if not player.playing:
   player.stream = sounds[sound_name]
   player.pitch_scale = pitch
   player.play()
   return

 sfx_players[0].stream = sounds[sound_name]
 sfx_players[0].pitch_scale = pitch
 sfx_players[0].play()

func play_music(track_name: String, fade_time: float = 1.0) -> void:
 if music_player.playing:
  var tween = create_tween()
  tween.tween_property(music_player, "volume_db", -40, fade_time / 2)
  await tween.finished

 music_player.volume_db = 0
 music_player.play()

func stop_music(fade_time: float = 1.0) -> void:
 if music_player.playing:
  var tween = create_tween()
  tween.tween_property(music_player, "volume_db", -40, fade_time)
  await tween.finished
  music_player.stop()

func play_hit() -> void:
 play_sfx("hit")

func play_magic() -> void:
 play_sfx("magic")

func play_heal() -> void:
 play_sfx("heal")

func play_click() -> void:
 play_sfx("click")

func play_select() -> void:
 play_sfx("select")

func play_victory() -> void:
 play_sfx("victory")

func play_defeat() -> void:
 play_sfx("defeat")

func play_step() -> void:
 play_sfx("step")

func play_death() -> void:
 play_sfx("death")
