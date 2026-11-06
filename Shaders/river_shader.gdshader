shader_type canvas_item;

// River waves: little ink dashes that drift with the current, drawn only on the light water pixels
uniform vec2 flow = vec2(1.0, 0.0);  // direction the river flows: (1, 0) = right, (0, 1) = down
uniform float speed = 6.0;           // pixels per second the waves drift
uniform float row_spacing = 6.0;     // pixels between each wave, along the river
uniform float wave_height = 1.0;     // how many pixels each wave wiggles sideways
uniform float wave_length = 0.5;     // bigger = tighter wiggles
uniform float dash_length = 4.0;     // how long each wave mark is, across the river
uniform float density = 0.35;        // 0..1, how many dashes are showing
uniform vec4 wave_color : source_color = vec4(0.117647, 0.109804, 0.196078, 1.0);

varying vec2 world_pos;

// A fixed random number for any pair of numbers
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Is this colour light water (not the dark bank)?
bool is_water(vec4 c) {
	return c.a > 0.5 && dot(c.rgb, vec3(0.299, 0.587, 0.114)) > 0.5;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	COLOR = base;

	if (is_water(base)) {
		// Turn the world so "along the river" is x and "across the river" is y
		vec2 dir = normalize(flow);
		vec2 p = floor(world_pos);
		vec2 river = vec2(dot(p, dir), dot(p, vec2(-dir.y, dir.x)));

		// Slide everything along the river over time, in whole pixels
		float along = floor(river.x - TIME * speed);
		float across = river.y;

		// Which wave this pixel is near, with a random offset per wave
		float wave = floor(along / row_spacing);
		float wave_rnd = hash(vec2(wave, 7.0));

		// The wiggle: each wave line bends a little as it crosses the river
		float wiggle = floor(sin(across * wave_length + wave_rnd * 6.2831) * wave_height + 0.5);
		bool on_line = mod(along + wiggle, row_spacing) == 0.0;

		// Chop each wave line into marks. Each wave keeps the same marks as it travels
		float dash = floor((across + wave_rnd * 50.0) / dash_length);
		float dash_rnd = hash(vec2(dash, wave));
		bool dash_on = dash_rnd > 1.0 - density;

		if (on_line && dash_on) {
			COLOR = wave_color;
		}
	}
}
