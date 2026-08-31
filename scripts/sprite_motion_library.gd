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
