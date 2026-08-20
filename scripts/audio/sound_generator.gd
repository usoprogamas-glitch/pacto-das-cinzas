class_name SoundGenerator
extends RefCounted

# Gera sons placeholder usando AudioStreamGenerator

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
