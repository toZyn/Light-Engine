#pragma language glsl3
// Thorns background wave effect (GLSL ES 3.0 precision-compatible with LÖVE forward decl)
extern highp float time;

highp vec2 wiggle(highp vec2 uv, highp float t, highp float amp, highp float freq) {
	uv.x += sin(uv.y * freq + t) * amp;
	uv.y += cos(uv.x * freq + t) * amp;
	uv = mix(uv, vec2(uv.x, uv.y + sin(t * 0.5) * 0.002), 0.5);
	return uv;
}

vec4 effect(vec4 color, Image tex, vec2 coords, vec2 screen_coords) {
	highp vec2 uv = wiggle(coords, time, 0.016, 5.54);
	return Texel(tex, uv) * color;
}
