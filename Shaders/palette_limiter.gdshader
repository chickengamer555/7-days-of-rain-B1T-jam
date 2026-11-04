shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 paper_color : source_color = vec4(0.776471, 0.729412, 0.67451, 1.0); // #c6baac
uniform vec4 ink_color : source_color = vec4(0.117647, 0.109804, 0.196078, 1.0);   // #1e1c32
uniform bool invert_colors = false;
uniform float threshold : hint_range(0.0, 1.0) = 0.45;
uniform float dither_intensity : hint_range(0.0, 1.0) = 0.0;

// 4x4 Bayer dither matrix for progressive corner closing
float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int index = x + y * 4;
	float m[16] = float[16](
		 0.0/16.0, 12.0/16.0,  3.0/16.0, 15.0/16.0,
		 8.0/16.0,  4.0/16.0, 11.0/16.0,  7.0/16.0,
		 2.0/16.0, 14.0/16.0,  1.0/16.0, 13.0/16.0,
		10.0/16.0,  6.0/16.0,  9.0/16.0,  5.0/16.0
	);
	return m[index];
}

void fragment() {
	vec4 scene_col = texture(screen_texture, SCREEN_UV);
	float lum = dot(scene_col.rgb, vec3(0.299, 0.587, 0.114));
	
	// Progressive corner dither: corners darken slightly each day
	if (dither_intensity > 0.0) {
		vec2 uv_dist = abs(SCREEN_UV - vec2(0.5)) * 2.0;
		float corner_dist = length(uv_dist);
		float dither_val = bayer4(FRAGCOORD.xy);
		float vignette = smoothstep(0.75, 1.35, corner_dist) * dither_intensity;
		if (dither_val < vignette) {
			lum -= 0.4;
		}
	}
	
	vec4 result = (lum > threshold) ? paper_color : ink_color;
	
	if (invert_colors) {
		result = (result == paper_color) ? ink_color : paper_color;
	}
	
	COLOR = result;
}
