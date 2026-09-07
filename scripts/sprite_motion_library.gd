class_name SpriteMotionLibrary
extends RefCounted

## Movimento multi-frame em runtime para os sprites HD estáticos (ComfyUI).
##
## Os PNGs são ilustrações únicas — não há sheet com frames. Esta biblioteca
## gera ciclos de animação fatiando a ilustração em bandas horizontais
## (cabeça/tronco/pernas) e deslocando cada banda com fase própria: as pernas
## oscilam mais, o tronco o meio, a cabeça quase nada — o clássico truque
## "cutout walk cycle" para sprite único, sem assets novos.
##
## Frames são gerados a 256px (4x downscale do PNG 1024px): 1MB por sprite
## em vez de 16MB, e o caller compensa a escala (scale * source_width/256).

const FRAME_SIZE := 256
const BANDS := 6

## Sets de animação a partir do PNG: {"idle": [Texture2D], "walk": [Texture2D]}.
## idle: 2 frames (respiração/sway sutil); walk: 4 frames (passada completa).
static func build_motion_sets(source: Image) -> Dictionary:
 if source == null or source.get_width() < 64:
  return {}
 var small := Image.new()
 small.copy_from(source)
 # blit_rect exige mesmo formato: PNGs RGB8 (sem alpha) são convertidos.
 if small.get_format() != Image.FORMAT_RGBA8:
  small.convert(Image.FORMAT_RGBA8)
 small.resize(FRAME_SIZE, FRAME_SIZE, Image.INTERPOLATE_LANCZOS)
 var idle := []
 for i in range(2):
  idle.append(ImageTexture.create_from_image(_shifted_frame(small, PI * float(i), 1.5, 1.0)))
 var walk := []
 for i in range(4):
  walk.append(ImageTexture.create_from_image(_shifted_frame(small, TAU * float(i) / 4.0, 5.0, 2.0)))
 return {"idle": idle, "walk": walk}


## Um frame: cópia da imagem com cada banda deslocada horizontalmente.
## phase: ângulo do ciclo; amplitude: deslocamento máx (px) nas pernas;
## bob: oscilação vertical do corpo inteiro.
static func _shifted_frame(source: Image, phase: float, amplitude: float, bob: float) -> Image:
 var w := source.get_width()
 var h := source.get_height()
 var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
 var dy := int(round(cos(phase) * bob))
 for band in range(BANDS):
  var y0 := int(h * float(band) / float(BANDS))
  var band_h := int(h * float(band + 1) / float(BANDS)) - y0
  if band_h <= 0:
   continue
  # weight quadrático: cabeça ~0, tronco médio, pernas máximo.
  var weight := float(band) / float(BANDS - 1)
  var dx := int(round(sin(phase) * amplitude * weight * weight))
  var region := source.get_region(Rect2i(0, y0, w, band_h))
  out.blit_rect(region, Rect2i(0, 0, w, band_h), Vector2i(dx, y0 + dy))
 return out


# === Sets de combate (réplica SoS: ataques 16-32 frames, 24fps) ===
# Frames gerados por bandas com as MESMAS técnicas do idle/walk, mas com
# enérgica de ação: antecipação → golpe → follow-through.

const ATTACK_FRAMES := 16
const CAST_FRAMES := 12
const HIT_FRAMES := 8
const DEATH_FRAMES := 10
const COMBAT_FPS := 24.0

## {"attack": [...], "cast": [...], "hit": [...], "death": [...]}.
## attack: 16 frames — agacha (antecipação), lunge à frente, recupera.
static func build_combat_sets(source: Image) -> Dictionary:
 if source == null or source.get_width() < 64:
  return {}
 var small := Image.new()
 small.copy_from(source)
 if small.get_format() != Image.FORMAT_RGBA8:
  small.convert(Image.FORMAT_RGBA8)
 small.resize(FRAME_SIZE, FRAME_SIZE, Image.INTERPOLATE_LANCZOS)
 var sets := {"attack": [], "cast": [], "hit": [], "death": []}
 for i in range(ATTACK_FRAMES):
  sets["attack"].append(ImageTexture.create_from_image(
   _attack_frame(small, float(i) / float(ATTACK_FRAMES))))
 for i in range(CAST_FRAMES):
  sets["cast"].append(ImageTexture.create_from_image(
   _cast_frame(small, float(i) / float(CAST_FRAMES))))
 for i in range(HIT_FRAMES):
  sets["hit"].append(ImageTexture.create_from_image(
   _hit_frame(small, float(i) / float(HIT_FRAMES))))
 for i in range(DEATH_FRAMES):
  sets["death"].append(ImageTexture.create_from_image(
   _death_frame(small, float(i) / float(DEATH_FRAMES))))
 return sets


## Frame de ataque no tempo t (0..1): antecipação (sobe, comprime) → lunge
## (avanço horizontal forte com squash) → follow-through (retorna, estica).
static func _attack_frame(source: Image, t: float) -> Image:
 var out := _shifted_frame(source, 0.0, 0.0, 0)
 var w := out.get_width()
 var h := out.get_height()
 # curva: 0-0.25 antecipa; 0.25-0.55 golpe; 0.55-1 recupera
 var lunge := 0.0
 var squash := 0.0
 var lean := 0.0
 if t < 0.25:
  var k := t / 0.25
  squash = -0.06 * k  # agacha antes
  lean = -0.03 * k    # puxa para trás (antecipação)
 elif t < 0.55:
  var k := (t - 0.25) / 0.3
  lunge = 0.10 * sin(k * PI * 0.5)
  squash = 0.04 * sin(k * PI)  # estica no avanço
  lean = 0.08 * sin(k * PI * 0.5)
 else:
  var k := (t - 0.55) / 0.45
  lunge = 0.10 * (1.0 - k)
  lean = 0.08 * (1.0 - k)
  squash = 0.02 * sin(k * PI)
 # aplica: bandas superiores puxam mais para frente (lean), corpo inteiro avança
 var dx_px := int(round(lunge * w * 0.18))
 var dy_px := int(round(squash * h))
 var scaled_h := h - absi(dy_px)
 var body := out.get_region(Rect2i(0, 0, w, h))
 if dy_px < 0:
  body = body.get_region(Rect2i(0, -dy_px, w, scaled_h))
 elif dy_px > 0:
  var grown := Image.create(w, h + dy_px, false, Image.FORMAT_RGBA8)
  grown.blit_rect(body, Rect2i(0, 0, w, h), Vector2i(0, dy_px))
  body = grown
 var result := Image.create(w + absi(dx_px), h, false, Image.FORMAT_RGBA8)
 var off_x := maxi(dx_px, 0)
 result.blit_rect(body, Rect2i(0, 0, w, body.get_height()), Vector2i(off_x, h - body.get_height()))
 # lean: desloca bandas superiores na direção do golpe
 if absf(lean) > 0.001:
  result = _band_lean(result, lean)
 return result


## Desloca bandas superiores horizontalmente (lean/anticipação).
static func _band_lean(source: Image, lean: float) -> Image:
 var w := source.get_width()
 var h := source.get_height()
 var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
 for band in range(BANDS):
  var y0 := int(h * float(band) / float(BANDS))
  var band_h := int(h * float(band + 1) / float(BANDS)) - y0
  if band_h <= 0:
   continue
  var weight := 1.0 - float(band) / float(BANDS - 1)  # topo puxa mais
  var dx := int(round(lean * w * 0.12 * weight))
  out.blit_rect(source, Rect2i(0, y0, w, band_h), Vector2i(dx, y0))
 return out


## Frame de cast no tempo t: levita (sobe), brilho cresce, pulsa, desce.
static func _cast_frame(source: Image, t: float) -> Image:
 var lift := sin(t * PI)  # sobe e desce
 var glow := 0.5 + 0.5 * sin(t * TAU * 2.0)
 var out := _shifted_frame(source, t * TAU, 0.0, 0)
 # desloca o corpo para cima com borda transparente embaixo
 var h := out.get_height()
 var dy := int(round(lift * h * 0.06))
 var moved := Image.create(out.get_width(), h, false, Image.FORMAT_RGBA8)
 moved.blit_rect(out, Rect2i(0, 0, out.get_width(), h - dy), Vector2i(0, 0))
 out = moved
 # aura: modulate azulada pulsante aplicada por canal (sem tocar alpha)
 if glow > 0.01:
  out = _tint(out, Color(0.6 * glow, 0.6 * glow, 1.0 * glow), false)
 return out


## Frame de hit no tempo t: recoil para trás com wobble decrescente.
static func _hit_frame(source: Image, t: float) -> Image:
 var recoil := (1.0 - t) * 0.10
 var wobble := sin(t * TAU * 3.0) * (1.0 - t) * 0.04
 var out := _shifted_frame(source, wobble * PI, 0.0, 0)
 var w := out.get_width()
 var dx := int(round(recoil * w))
 var out2 := Image.create(w + dx, out.get_height(), false, Image.FORMAT_RGBA8)
 out2.blit_rect(out, Rect2i(0, 0, w, out.get_height()), Vector2i(dx, 0))
 return _tint(out2, Color(1.0, 0.4, 0.4, 1.0).lerp(Color.WHITE, t), true)


## Frame de death no tempo t: desaba (squash vertical crescente) + fade.
static func _death_frame(source: Image, t: float) -> Image:
 var squash := t * 0.45
 var out := _shifted_frame(source, 0.0, 0.0, 0)
 var w := out.get_width()
 var h := out.get_height()
 var new_h := maxi(int(h * (1.0 - squash)), 8)
 var collapsed := Image.create(w, h, false, Image.FORMAT_RGBA8)
 var body := out.get_region(Rect2i(0, 0, w, new_h))
 collapsed.blit_rect(body, Rect2i(0, 0, w, new_h), Vector2i(0, h - new_h))  # pés no chão
 # fade: alpha global decrescente
 var a := 1.0 - t * 0.7
 for y in range(h):
  for x in range(w):
   var px := collapsed.get_pixel(x, y)
   if px.a > 0.0:
    collapsed.set_pixel(x, y, Color(px.r, px.g, px.b, px.a * a))
 return collapsed


## Tint simples por pixel (multiply aditivo suave). keep_alpha preserva a.
static func _tint(source: Image, tint: Color, keep_alpha: bool) -> Image:
 var out := Image.new()
 out.copy_from(source)
 for y in range(out.get_height()):
  for x in range(out.get_width()):
   var px := out.get_pixel(x, y)
   if px.a < 0.01:
    continue
   out.set_pixel(x, y, Color(
    clampf(px.r + tint.r, 0.0, 1.0),
    clampf(px.g + tint.g, 0.0, 1.0),
    clampf(px.b + tint.b, 0.0, 1.0),
    px.a if keep_alpha else px.a))
 return out
