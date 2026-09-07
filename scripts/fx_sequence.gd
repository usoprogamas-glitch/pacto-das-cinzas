class_name FxSequence
extends RefCounted
## Sequências de FX como texturas geradas em runtime (réplica do padrão SoS:
## FX = sequência de texturas _F00.._FNN, ex. Sunball 66f). Nossa versão:
## 16 frames de 64px quantizados (paleta limitada como o jogo real).

const FRAME_SIZE := 64
const BURST_FRAMES := 16

## Orbe de éter em expansão: núcleo branco, halo cobalto, faíscas orbitando.
## t: 0..1 (cresce, pulsa e some no final — molde Sunball).
static func ether_burst_frame(t: float) -> Image:
 var img := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
 var c := Vector2(FRAME_SIZE / 2.0, FRAME_SIZE / 2.0)
 # raio cresce e some no fim (pop + fade)
 var grow := sin(t * PI * 0.85)
 var fade := clampf(1.0 - t * t, 0.0, 1.0)
 var radius := 4.0 + grow * (FRAME_SIZE * 0.30)
 # halo cobalto
 var halo_r := radius * (1.0 + 0.35 * sin(t * TAU))
 for y in range(FRAME_SIZE):
  for x in range(FRAME_SIZE):
   var dist := Vector2(x, y).distance_to(c)
   if dist < halo_r:
    var k := 1.0 - dist / halo_r
    var a := k * k * 0.55 * fade
    img.set_pixel(x, y, Color(0.25, 0.5, 1.0, a))
 # núcleo branco pulsante
 var core_r := radius * (0.45 + 0.1 * sin(t * TAU * 3.0))
 for y in range(FRAME_SIZE):
  for x in range(FRAME_SIZE):
   var dist := Vector2(x, y).distance_to(c)
   if dist < core_r:
    var k := 1.0 - dist / core_r
    img.set_pixel(x, y, Color(1.0, 1.0, 1.0, k * fade))
 # faíscas orbitando (6 braços, ângulo avança com t)
 for arm in range(6):
  var ang := t * TAU * 1.5 + float(arm) * TAU / 6.0
  var spark_dist := radius * (0.55 + 0.25 * sin(t * PI * 2.0 + arm))
  var sx := int(round(c.x + cos(ang) * spark_dist))
  var sy := int(round(c.y + sin(ang) * spark_dist * 0.8))
  if sx >= 0 and sx < FRAME_SIZE and sy >= 0 and sy < FRAME_SIZE:
   img.set_pixel(sx, sy, Color(1.0, 0.95, 0.7, fade))
 return _quantize(img, 12)


## Todas as texturas do burst: [Texture2D] (BURST_FRAMES).
static func ether_burst_frames() -> Array:
 var frames: Array = []
 for i in range(BURST_FRAMES):
  frames.append(ImageTexture.create_from_image(ether_burst_frame(float(i) / float(BURST_FRAMES))))
 return frames


## Exporta a sequência em assets/pixel/fx/ (convenção SoS <nome>_F<NN>).
static func export_ether_burst(dir: String = "res://assets/pixel/fx") -> int:
 DirAccess.make_dir_recursive_absolute(dir)
 var count := 0
 for i in range(BURST_FRAMES):
  var img := ether_burst_frame(float(i) / float(BURST_FRAMES))
  img.save_png("%s/fx_ether_burst_F%02d.png" % [dir, i])
  count += 1
 return count


## Carrega a sequência exportada (se presente) — senão gera em runtime.
static func ether_burst_frames_cached() -> Array:
 var frames: Array = []
 for i in range(BURST_FRAMES):
  var path := "res://assets/pixel/fx/fx_ether_burst_F%02d.png" % i
  if not ResourceLoader.exists(path):
   return ether_burst_frames()
  frames.append(load(path))
 return frames


static func _quantize(img: Image, colors: int) -> Image:
 # quantize nativo via paleta aproximada: median cut do Godot não existe em
 # Image; aproximação barata = reduzir canais para passos de 1/8.
 var out := Image.new()
 out.copy_from(img)
 for y in range(out.get_height()):
  for x in range(out.get_width()):
   var px := out.get_pixel(x, y)
   out.set_pixel(x, y, Color(
    roundf(px.r * 8.0) / 8.0,
    roundf(px.g * 8.0) / 8.0,
    roundf(px.b * 8.0) / 8.0,
    roundf(px.a * 8.0) / 8.0))
 return out
