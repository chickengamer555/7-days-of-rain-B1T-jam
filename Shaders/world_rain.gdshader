shader_type canvas_item; // Prewitten code

// Reads what's behind each drop so it can be the opposite colour
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 paper_color : source_color = vec4(0.776, 0.729, 0.675, 1.0);
uniform vec4 ink_color   : source_color = vec4(0.118, 0.110, 0.196, 1.0);

uniform float cell = 14.0;           // ground is split into squares this size; one landing spot each
uniform float density : hint_range(0.0, 1.0) = 0.5;  // chance a square gets a drop each cycle
uniform float cycle = 1.0;           // seconds between drops for each square
uniform float fall_distance = 40.0;  // how far above its landing spot a drop starts (pixels)
uniform float fall_time = 0.25;      // seconds to fall (40px / 0.25s = 160 px/s)
uniform float drop_length = 4.0;     // streak length while falling
uniform float splash_time = 0.3;     // how long the splash ring lasts
uniform float max_radius = 3.0;      // biggest ring size

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;  // world position, so rain stays fixed to the ground
}

// Turns a position into a random-looking number from 0 to 1
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Does the drop that lands in square c cover pixel p right now?
bool drop_from_cell(vec2 p, vec2 c) {
	// Each square has its own timing so they don't all fall at once
	float t = TIME + hash(c) * cycle;
	float n = floor(t / cycle);   // which drop number this square is on
	float age = mod(t, cycle);    // seconds since this drop started

	// New random numbers for every drop
	vec2 seed = c + vec2(n * 17.0, n * 31.0);
	if (hash(seed) >= density) {
		return false;  // this square skips this cycle
	}

	// Random landing spot inside the square, leaving room for the ring
	float room = cell - 2.0 * max_radius - 1.0;
	vec2 land = c * cell + max_radius + floor(vec2(hash(seed + 3.1), hash(seed + 7.7)) * room);

	// Stage 1: falling. The streak's bottom (head) moves from
	// fall_distance above the landing spot down to the landing spot.
	if (age < fall_time) {
		float head = floor(land.y - fall_distance * (1.0 - age / fall_time));
		return p.x == land.x && p.y <= head && p.y > head - drop_length;
	}

	// Stage 2: landed. A dot first, then a ring that grows by 1px per step.
	float splash_age = age - fall_time;
	if (splash_age < splash_time) {
		float r = floor(splash_age / splash_time * (max_radius + 1.0));
		float d = distance(p, land);
		return (r < 0.5) ? (d < 0.5) : (abs(d - r) < 0.5);
	}

	return false;  // finished, so nothing is drawn until the next cycle
}

void fragment() {
	vec2 p = floor(local_pos);
	vec2 c = floor(p / cell);

	// A falling streak is ABOVE the square it lands in, so a pixel can belong
	// to a drop from its own square or from one of the squares below it.
	// Check this square plus enough squares below to cover fall_distance.
	bool is_drop = false;
	int cells_up = int(ceil(fall_distance / cell)) + 1;
	for (int i = 0; i <= 8; i++) {
		if (i > cells_up) {
			break;
		}
		if (drop_from_cell(p, c + vec2(0.0, float(i)))) {
			is_drop = true;
			break;
		}
	}

	if (is_drop) {
		vec4 bg = texture(screen_texture, SCREEN_UV);
		float lum = dot(bg.rgb, vec3(0.299, 0.587, 0.114));
		COLOR = (lum > 0.5) ? ink_color : paper_color;
	} else {
		COLOR = vec4(0.0);  // see-through
	}
}
