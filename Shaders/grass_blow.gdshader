shader_type canvas_item;

// Wind
uniform float tile_size = 16.0;      // pixels per tile in the atlas
uniform float wind_speed = 1.0;      // how fast gusts roll across
uniform float gust_width = 0.02;     // smaller = wider gusts
uniform float strength = 0.5;        // 0..1, how much grass is bent at once
uniform float randomness = 0.5;      // 0 = clean wave, 1 = every tile does its own thing
uniform int max_bend = 2;            // pixels the blades lean

// Flattening (the player script sends current_time and trail)
uniform float flat_time = 5.0;       // seconds grass stays flat after being walked on
uniform float current_time = 0.0;    // sent by the player every frame
uniform vec3 trail[32];              // x, y = map cell, z = time it was stepped on
uniform vec4 paper_color : source_color = vec4(0.776471, 0.729412, 0.67451, 1.0);
uniform vec4 ink_color : source_color = vec4(0.117647, 0.109804, 0.196078, 1.0);

varying vec2 world_pos;

// A fixed random number for each map cell
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Is this spot still inside the current tile?
bool in_tile(vec2 p, float size) {
	return p.x >= 0.0 && p.y >= 0.0 && p.x < size && p.y < size;
}

// Is this colour a light blade pixel (not the dark background)?
bool is_blade(vec4 c) {
	return c.a > 0.5 && dot(c.rgb, vec3(0.299, 0.587, 0.114)) > 0.5;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);
	vec2 local = mod(texel, tile_size);              // pixel position inside this tile

	vec2 tile = floor(world_pos / tile_size);        // which map cell this pixel is in
	float rnd = hash(tile);

	// Was this cell walked on recently? Each cell springs back at a slightly different time
	bool is_flat = false;
	for (int i = 0; i < 32; i++) {
		if (trail[i].xy == tile && current_time - trail[i].z < flat_time + rnd) {
			is_flat = true;
		}
	}

	if (is_flat) {
		// Squash each tuft onto its bottom row: "^" becomes "_"
		bool blade_on_row = false;
		bool blade_below = false;
		bool blade_above = false;
		for (int dx = -3; dx <= 3; dx++) {
			vec2 side = vec2(float(dx), 0.0);
			vec2 under = vec2(float(dx), 1.0);
			if (in_tile(local + side, tile_size) && is_blade(texture(TEXTURE, UV + side * TEXTURE_PIXEL_SIZE))) {
				blade_on_row = true;
			}
			if (in_tile(local + under, tile_size) && is_blade(texture(TEXTURE, UV + under * TEXTURE_PIXEL_SIZE))) {
				blade_below = true;
			}
		}
		for (int dy = 0; dy <= 2; dy++) {
			vec2 up = vec2(0.0, -float(dy));
			if (in_tile(local + up, tile_size) && is_blade(texture(TEXTURE, UV + up * TEXTURE_PIXEL_SIZE))) {
				blade_above = true;
			}
		}
		COLOR = (blade_on_row && !blade_below && blade_above) ? paper_color : ink_color;
	} else {
		// Wind: blades lean over by whole pixels as gusts pass
		float gust = sin(TIME * wind_speed - world_pos.x * gust_width + rnd * 6.2831 * randomness);
		float flutter = sin(TIME * 2.3 + rnd * 40.0);
		float amount = (gust * 0.75 + flutter * 0.25) * 0.5 + 0.5;
		int bend = int(step(1.0 - strength, amount)) * max_bend;

		float src_x = local.x - float(bend);
		if (src_x >= 0.0 && src_x < tile_size) {
			COLOR = texture(TEXTURE, UV - vec2(float(bend), 0.0) * TEXTURE_PIXEL_SIZE);
		}
	}
}
