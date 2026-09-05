shader_type canvas_item;
// Água animada estilo SoS: ondas senoidais nas cores + highlight especular
// + distorção suave. Aplicar em Sprite2D/ColorRect representando água.

uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.35, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.1, 0.35, 0.6, 1.0);
uniform vec4 sparkle_color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float wave_speed : hint_range(0.0, 3.0) = 1.0;
uniform float wave_scale : hint_range(1.0, 40.0) = 12.0;

void fragment() {
	// Ondas: duas camadas senoidais em direções diferentes.
	vec2 uv = UV * wave_scale;
	float wave1 = sin(uv.x * 3.0 + TIME * 2.0 * wave_speed) * 0.5 + 0.5;
	float wave2 = sin(uv.y * 2.0 - TIME * 1.4 * wave_speed + uv.x * 1.5) * 0.5 + 0.5;
	float wave = (wave1 + wave2) * 0.5;

	// Cor base interpola entre profundo e raso pelas ondas.
	vec4 col = mix(deep_color, shallow_color, wave * 0.6);

	// Sparkle: brilho pontual nas cristas (threshold alto do wave combinado).
	float sparkle = step(0.94, wave1 * wave2);
	col = mix(col, sparkle_color, sparkle * 0.8);

	// Distorção sutil do alpha nas bordas? (não: alpha cheio para água sólida)
	COLOR = col;
}
