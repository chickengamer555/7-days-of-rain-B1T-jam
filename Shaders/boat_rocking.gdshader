
shader_type canvas_item;

uniform float speed = 1.5;          // rocks per second 
uniform vec2 direction = vec2(1.0, 0.0); // Which way foward is 
uniform float randomness = 1.0;     // 0 = wither all the boats rock togther or seprate
uniform float hold = 0.5;           // how much there pushed foward each rock

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	// world position of boat corner
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	// Work back from left corner so all pixels are in sync 
	vec2 origin = world - UV / TEXTURE_PIXEL_SIZE;
	float phase = hash(floor(origin / 16.0)) * 6.2831 * randomness;

	// sin goes -1..1. step then turns it into either 0 or 1 = back or forwar no in between
	float wave = sin(TIME * speed * 6.2831 + phase);
	float push = step(1.0 - hold * 2.0, wave);

	// move the whole boat by 0 or 1 pixel in the direction thats foward
	VERTEX += normalize(direction) * push;
}
