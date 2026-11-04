shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 paper_color : source_color = vec4(0.776471, 0.729412, 0.67451, 1.0); // #c6baac
uniform vec4 ink_color : source_color = vec4(0.117647, 0.109804, 0.196078, 1.0);   // #1e1c32

void fragment() {
	vec4 bg = texture(screen_texture, SCREEN_UV);
	float lum = dot(bg.rgb, vec3(0.299, 0.587, 0.114));
	
	// Flip color where crossing ink so it always stays visible:
	// Light background -> Ink drop
	// Dark background -> Paper drop
	COLOR = (lum > 0.5) ? ink_color : paper_color;
}
