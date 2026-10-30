#pragma language glsl3

uniform highp float time;
uniform highp float scale;
uniform highp float intensity;
uniform highp float distortionStrength;

const highp float RAIN_SPEED = 8.0;

highp float rand(highp vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

highp float rainDrop(highp vec2 p, highp float sc, out highp float distortAmount) {
	p *= 0.1;
	p.x += p.y * 0.1;
	p.y -= time * (RAIN_SPEED * 100.0) / sc;
	p.y *= 0.03;

	highp float ix = floor(p.x);
	highp float iy = floor(p.y);
	highp vec2 idx = vec2(ix, iy);

	p.y += mod(ix, 2.0) * 0.5 + (rand(vec2(ix)) - 0.5) * 0.3;
	iy = floor(p.y);
	idx = vec2(ix, iy);

	p -= vec2(ix, iy);
	p.x += (rand(idx.yx) * 2.0 - 1.0) * 0.35;
	highp vec2 d = abs(p - 0.5);
	highp float drop = max(d.x * 0.8, d.y * 0.5) - 0.1;

	distortAmount = 0.0;
	if (drop < 0.0) {
		highp float center = length(p - 0.5);
		distortAmount = smoothstep(0.0, 0.4, -drop) * smoothstep(0.0, 0.2, center);
	}

	bool empty = rand(idx) < mix(1.0, 0.1, intensity);
	return empty ? 1.0 : drop;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
	highp vec2 pos = screen_coords;
	highp vec2 originalPos = pos;

	highp vec2 distortedUV = uv;
	highp float totalDistortion = 0.0;
	highp float maxDistortScale = 3.0;
	highp float rainAmount = 0.0;

	highp float scales[3] = float[3](1.0, 2.0, 3.0);

	for (int i = 0; i < 3; i++) {
		highp float sc = scales[i];
		highp float offset = float(i) * 500.0;
		highp float distortAmount;

		highp float drop = rainDrop(pos * sc / max(scale, 0.0001) + offset, sc, distortAmount);

		if (drop < 0.0) {
			highp vec2 dir = normalize(pos - originalPos + vec2(0.01, 0.01));

			highp float distFactor = distortAmount * distortionStrength * (sc / maxDistortScale);
			distortedUV += dir * distFactor;
			totalDistortion += distFactor;
			rainAmount += (1.0 - rainAmount) * 0.75;
		}
	}

	vec4 texcolor = Texel(tex, distortedUV);
	vec3 rainAtmosphere = vec3(0.4, 0.5, 0.8);
	vec3 finalColor = mix(texcolor.rgb, rainAtmosphere, 0.1 * rainAmount);
	return vec4(finalColor, texcolor.a) * color;
}
