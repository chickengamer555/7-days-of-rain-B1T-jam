shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 paper_color : source_color = vec4(0.776471, 0.729412, 0.67451, 1.0); // #c6baac
uniform vec4 ink_color : source_color = vec4(0.117647, 0.109804, 0.196078, 1.0);   // #1e1c32
uniform float outline_width : hint_range(0.0, 3.0, 1.0) = 1.0;
uniform bool outline_enabled = true;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	if (col.a > 0.0) {
		// Native player sprite pixel
		COLOR = col;
	} else if (outline_enabled && outline_width > 0.0) {
		// Check neighborhood for sprite silhouette boundary
		vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
		
		float max_a = 0.0;
		// 4 cardinal directions
		max_a = max(max_a, texture(TEXTURE, UV + vec2(ps.x, 0.0)).a);
		max_a = max(max_a, texture(TEXTURE, UV - vec2(ps.x, 0.0)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, ps.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV - vec2(0.0, ps.y)).a);
		
		// 4 diagonal directions for 8-way continuous contour
		max_a = max(max_a, texture(TEXTURE, UV + vec2(ps.x, ps.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV - vec2(ps.x, ps.y)).a);
		
		if (max_a > 0.0) {
			// This is an outline pixel bordering the player
			// Sample the screen background directly behind this pixel:
			vec4 bg = texture(screen_texture, SCREEN_UV);
			float lum = dot(bg.rgb, vec3(0.299, 0.587, 0.114));
			
			// Dynamic Contrast Inversion (Strict 2-Color Palette):
			// Light background -> Ink outline
			// Dark background -> Paper outline
			COLOR = (lum > 0.5) ? ink_color : paper_color;
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		COLOR = vec4(0.0);
	}
}
