// Soft edges for pictures (Cameron, 2026-10-31): a picture fades out over a
// few pixels where its box ends against something else, instead of stopping
// at a hard line. PlaceholderArt sets the uniforms: `box_rect` is the visible
// box in the picture's own local pixels (it differs from the picture's rect
// while a picture is dragged or tilted), and `fade` is the width of the fade
// on each side (left, top, right, bottom); 0 on a side that meets the screen
// edge, so nothing fades where there is nothing beyond it.
shader_type canvas_item;

uniform vec4 box_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 fade = vec4(0.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float edge(float distance, float width) {
	return width > 0.0 ? smoothstep(0.0, 1.0, clamp(distance / width, 0.0, 1.0)) : 1.0;
}

void fragment() {
	vec2 p = local_pos - box_rect.xy;
	float alpha = edge(p.x, fade.x) * edge(p.y, fade.y)
		* edge(box_rect.z - p.x, fade.z) * edge(box_rect.w - p.y, fade.w);
	COLOR.a *= alpha;
}
