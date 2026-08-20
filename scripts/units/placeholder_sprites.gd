class_name PlaceholderSprites
extends Node

# Gera sprites placeholder de 32x32 baseados nos cards de asset

static func create_character_sprite(character_name: String) -> Sprite2D:
 var sprite = Sprite2D.new()
 var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)

 match character_name:
  "Kael":
   draw_imp(image, Color("#4A3728"), Color("#00FFAA"))
  "Kroug":
   draw_goblin(image, Color("#5A6B3C"), Color("#8B7355"))
  "Lira":
   draw_plant(image, Color("#4A3520"), Color("#2E8B57"))
  "Thal'kor":
   draw_angel(image, Color("#2C2C3E"), Color("#8B008B"))
  "Mercenário":
   draw_mercenary(image, Color("#8B4513"), Color("#696969"))
  "Paladino":
   draw_paladin(image, Color("#FFD700"), Color("#F5F5F5"))
  _:
   draw_default(image, Color("#FF0000"))

 var texture = ImageTexture.create_from_image(image)
 sprite.texture = texture
 return sprite

static func draw_imp(image: Image, skin: Color, glow: Color) -> void:
 # Corpo principal
 image.fill_rect(Rect2i(10, 8, 12, 16), skin)
 # Olhos brilhantes
 image.set_pixel(14, 12, glow)
 image.set_pixel(18, 12, glow)
 # Chifres
 image.set_pixel(12, 6, skin.darkened(0.3))
 image.set_pixel(20, 6, skin.darkened(0.3))
 image.set_pixel(11, 5, skin.darkened(0.3))
 image.set_pixel(21, 5, skin.darkened(0.3))

static func draw_goblin(image: Image, skin: Color, armor: Color) -> void:
 # Corpo
 image.fill_rect(Rect2i(8, 10, 16, 14), skin)
 # Armadura
 image.fill_rect(Rect2i(10, 12, 12, 8), armor)
 # Olhos
 image.set_pixel(13, 14, Color("#FF4444"))
 image.set_pixel(19, 14, Color("#FF4444"))

static func draw_plant(image: Image, bark: Color, leaves: Color) -> void:
 # Tronco
 image.fill_rect(Rect2i(12, 14, 8, 12), bark)
 # Folhas
 image.fill_rect(Rect2i(8, 6, 16, 10), leaves)
 # Brilho
 image.set_pixel(16, 10, Color("#90EE90"))

static func draw_angel(image: Image, feathers: Color, corruption: Color) -> void:
 # Corpo
 image.fill_rect(Rect2i(10, 8, 12, 18), feathers)
 # Asas
 image.fill_rect(Rect2i(4, 10, 6, 12), feathers.darkened(0.2))
 image.fill_rect(Rect2i(22, 10, 6, 12), feathers.darkened(0.2))
 # Corrupção
 image.fill_rect(Rect2i(6, 14, 4, 4), corruption)
 image.fill_rect(Rect2i(22, 14, 4, 4), corruption)
 # Olhos
 image.set_pixel(14, 12, corruption)
 image.set_pixel(18, 12, corruption)

static func draw_mercenary(image: Image, armor: Color, chain: Color) -> void:
 # Corpo
 image.fill_rect(Rect2i(8, 8, 16, 18), armor)
 # Malha
 image.fill_rect(Rect2i(10, 10, 12, 10), chain)
 # Olhos
 image.set_pixel(13, 12, Color("#FFFFFF"))
 image.set_pixel(19, 12, Color("#FFFFFF"))

static func draw_paladin(image: Image, gold: Color, white: Color) -> void:
 # Corpo
 image.fill_rect(Rect2i(8, 6, 16, 20), white)
 # Armadura dourada
 image.fill_rect(Rect2i(10, 8, 12, 8), gold)
 # Aura
 image.fill_rect(Rect2i(6, 4, 20, 2), Color("#FFFFAA", 0.5))

static func draw_default(image: Image, color: Color) -> void:
 image.fill_rect(Rect2i(8, 8, 16, 16), color)

static func create_terrain_tile(terrain_type: String) -> Sprite2D:
 var sprite = Sprite2D.new()
 var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)

 match terrain_type:
  "grass":
   image.fill(Color("#1A3A1A"))
   for i in range(20):
    var x = randi() % 32
    var y = randi() % 32
    image.set_pixel(x, y, Color("#2A4A2A"))
  "stone":
   image.fill(Color("#4A4A5A"))
   for i in range(15):
    var x = randi() % 32
    var y = randi() % 32
    image.set_pixel(x, y, Color("#5A5A6A"))
  "lava":
   image.fill(Color("#CC3300"))
   for i in range(30):
    var x = randi() % 32
    var y = randi() % 32
    image.set_pixel(x, y, Color("#FF4500"))
  "water":
   image.fill(Color("#0A1A3A"))
   for i in range(25):
    var x = randi() % 32
    var y = randi() % 32
    image.set_pixel(x, y, Color("#1A2A4A"))
  _:
   image.fill(Color("#3A3A3A"))

 var texture = ImageTexture.create_from_image(image)
 sprite.texture = texture
 return sprite
