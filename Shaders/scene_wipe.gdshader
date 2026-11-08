shader_type canvas_item;

// 0 = no ink, 1 = screen covered
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.117647, 0.109804, 0.196078, 1.0);
uniform vec2 screen_px = vec2(240.0, 160.0); // game res
uniform float wave_height = 5.0; // pixels up and down
uniform float wave_length = 48.0; // pixels per wave
uniform float wave_speed = 6.0; // how fast the wave rolls
uniform float dither_rows = 3.0; // checker rows above the edge

void fragment() {
	vec2 px = floor(UV * screen_px); // snap to grid 
	float wave = sin(px.x / wave_length * 6.2832 + TIME * wave_speed);
	wave = floor(wave * wave_height + 0.5); // whole pixels only ( pixel consitincy)
	float travel = screen_px.y + wave_height * 2.0 + dither_rows;
	float edge = screen_px.y + wave_height - progress * travel + wave;
	float a = 0.0;
	if (px.y >= edge) {
		a = 1.0; 
	} else if (px.y >= edge - dither_rows && mod(px.x + px.y, 2.0) == 0.0) {
		a = 1.0; // dither band on wave crest
	}
	COLOR = vec4(ink_color.rgb, a);
}