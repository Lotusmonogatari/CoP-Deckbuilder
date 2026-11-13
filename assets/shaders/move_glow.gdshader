// A glow just outside a character's edge (Cameron, 2026-11-13): the picture's
// own transparent outline is traced, and the colour is strongest at the edge
// and tapers to nothing `width` pixels out. The layer using this is a little
// larger than the portrait so the glow has room; `img_rect` says where the
// picture sits inside it (x, y, width, height in the layer's own pixels).
// With no drawn picture (`use_art` 0) the picture's whole box is the shape.
// `amount` (0 to 1) is the flash's own fade over time.
shader_type canvas_item;

uniform sampler2D art : filter_linear;
uniform vec4 img_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float width = 5.0;
uniform float amount = 1.0;
uniform float use_art = 1.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float alpha_at(vec2 p) {
	vec2 uv = (p - img_rect.xy) / img_rect.zw;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return use_art > 0.5 ? texture(art, uv).a : 1.0;
}

void fragment() {
	float best = 0.0;
	for (int ring = 0; ring <= 3; ring++) {
		float radius = width * float(ring) / 3.0;
		float weight = 1.0 - smoothstep(0.0, 1.0, radius / max(width, 0.001));
		if (ring == 0) {
			best = max(best, alpha_at(local_pos));
			continue;
		}
		for (int i = 0; i < 12; i++) {
			float angle = 6.2831853 * float(i) / 12.0;
			vec2 p = local_pos + vec2(cos(angle), sin(angle)) * radius;
			best = max(best, alpha_at(p) * weight);
		}
	}
	COLOR = vec4(glow_color.rgb, best * glow_color.a * amount);
}
