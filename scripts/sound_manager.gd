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
  "hit": create_hit_sound(),
  "magic": create_magic_sound(),
  "heal": create_heal_sound(),
  "click": create_click_sound(),
  "select": create_select_sound(),
  "victory": create_victory_sound(),
  "defeat": create_defeat_sound(),
  "step": create_step_sound(),
  "death": create_death_sound()
 }

# ... rest of the file

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
 # P0-4 (auditoria): play_music nunca setava stream (tocava silêncio) e nunca
 # era chamada. BGM procedural (mesmo padrão dos SFX create_*), loop infinito.
 var stream: AudioStreamWAV = _get_or_create_music(track_name)
 if stream == null:
  return
 if music_player.stream == stream and music_player.playing:
  return  # mesma faixa já tocando: nada a fazer
 music_player.stop()
 music_player.stream = stream
 music_player.volume_db = 0
 music_player.play()

var _music_cache: Dictionary = {}

func _get_or_create_music(track_name: String) -> AudioStreamWAV:
 if _music_cache.has(track_name):
  return _music_cache[track_name]
 var stream: AudioStreamWAV = null
 match track_name:
  "exploration":
   stream = create_exploration_music()
  "battle":
   stream = create_battle_music()
 if stream:
  stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin = 0
  stream.loop_end = stream.data.size() / 2  # 16-bit mono: 2 bytes/frame
  _music_cache[track_name] = stream
 return stream

## BGM exploração: drone grave + arpejo lento em menor (atmosfera cinzenta).
static func create_exploration_music() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var duration = 8.0
 var samples = int(22050 * duration)
 var frames = PackedByteArray()
 var scale_steps = [0, 3, 5, 7, 10]  # pentatônica menor sobre A
 var root_freq = 110.0

 for i in range(samples):
  var t = float(i) / 22050.0
  # Bass drone (A2) contínuo
  var sample = sin(2.0 * PI * root_freq * t) * 0.15
  # Arpejo: nota a cada 0.5s, envolvente decay
  var step := int(fmod(t, 4.0) / 0.5)
  var note_freq: float = root_freq * 2.0 * pow(2.0, scale_steps[step % scale_steps.size()] / 12.0)
  var note_t := fmod(t, 0.5)
  var envelope := 1.0 - (note_t / 0.5)
  sample += sin(2.0 * PI * note_freq * t) * envelope * 0.12
  var byte = int(clamp(sample, -1.0, 1.0) * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

## BGM batalha: pulso percussivo + linha de baixo tensa em ritmo acelerado.
static func create_battle_music() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var duration = 4.0
 var samples = int(22050 * duration)
 var frames = PackedByteArray()
 var root_freq = 98.0  # G2

 for i in range(samples):
  var t = float(i) / 22050.0
  # Pulso a cada 0.25s (ritmo de combate)
  var beat := fmod(t, 0.25)
  var pulse := maxf(0.0, 1.0 - beat / 0.05) * 0.25
  # Baixo em oitavas alternadas (tensão)
  var bass_freq: float = root_freq if int(t / 0.5) % 2 == 0 else root_freq * 1.5
  var sample := sin(2.0 * PI * bass_freq * t) * 0.18 + pulse
  var byte = int(clamp(sample, -1.0, 1.0) * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

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

# === SOUND GENERATION METHODS (moved from SoundGenerator for reliability) ===

static func create_hit_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.1
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 200.0 + (1.0 - t) * 800.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.5
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_magic_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.3
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 400.0 + t * 600.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.3
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_heal_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.25
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 600.0 + t * 400.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.3
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_click_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.05
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 1000.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.4
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_select_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.08
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 800.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.3
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_victory_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.5
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 400.0 + sin(t * 20.0) * 200.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.4
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_defeat_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.6
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 300.0 - t * 200.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.4
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_step_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.06
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 150.0 + randf() * 50.0
  var sample = (randf() * 2.0 - 1.0) * envelope * 0.2
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream

static func create_death_sound() -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.stereo = false

 var frames = PackedByteArray()
 var duration = 0.4
 var samples = int(22050 * duration)

 for i in range(samples):
  var t = float(i) / 22050.0
  var envelope = 1.0 - (t / duration)
  var freq = 500.0 - t * 400.0
  var sample = sin(2.0 * PI * freq * t) * envelope * 0.5
  var byte = int(sample * 127) + 128
  frames.append(byte)

 stream.data = frames
 return stream
