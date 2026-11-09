shader_type canvas_item;

// 1-Bit Palette
uniform vec4 paper_color : source_color = vec4(0.776471, 0.729412, 0.67451, 1.0);
uniform vec4 ink_color : source_color = vec4(0.117647, 0.109804, 0.196078, 1.0);

// Style mode:
// 0 = Outline (1px ink border around fence slats and posts - crispest contrast)
// 1 = Drop Shadow (1px ink shadow down & right)
// 2 = Solid Silhouette (All blocked tiles rendered as solid ink)
uniform int mode : hint_range(0, 2) = 0;
uniform vec2 shadow_offset = vec2(1.0, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	if (mode == 2) {
		// Solid silhouette
		if (col.a > 0.1) {
			COLOR = vec4(ink_color.rgb, col.a);
		} else {
			COLOR = col;
		}
	} else if (mode == 0) {
		// 1px Outline: if current pixel is transparent, check 4-connected neighbors
		if (col.a < 0.1) {
			float a_up = texture(TEXTURE, UV + vec2(0.0, -TEXTURE_PIXEL_SIZE.y)).a;
			float a_down = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
			float a_left = texture(TEXTURE, UV + vec2(-TEXTURE_PIXEL_SIZE.x, 0.0)).a;
			float a_right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;
			if (max(max(a_up, a_down), max(a_left, a_right)) > 0.1) {
				COLOR = ink_color;
			} else {
				COLOR = col;
			}
		} else {
			COLOR = col;
		}
	} else if (mode == 1) {
		// Drop shadow: check offset neighbor
		if (col.a < 0.1) {
			vec2 offset_uv = UV - shadow_offset * TEXTURE_PIXEL_SIZE;
			if (texture(TEXTURE, offset_uv).a > 0.1) {
				COLOR = ink_color;
			} else {
				COLOR = col;
			}
		} else {
			COLOR = col;
		}
	} else {
		COLOR = col;
	}
}
