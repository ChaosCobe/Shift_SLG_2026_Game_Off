shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 curtain_color : source_color = vec4(0.027, 0.035, 0.059, 1.0);

float edge_side(vec2 point, vec2 start, vec2 end) {
	vec2 edge = end - start;
	vec2 offset = point - start;
	return (edge.y * offset.x - edge.x * offset.y) / length(edge);
}

float triangle(vec2 point, vec2 a, vec2 b, vec2 c) {
	return max(edge_side(point, a, b), max(edge_side(point, b, c), edge_side(point, c, a)));
}

void fragment() {
	// Quantize to two logical pixels, keeping the silhouette edge crisp.
	vec2 pixel = floor(UV * vec2(320.0, 180.0)) + 0.5;
	float radius = max(260.0 * (1.0 - progress), 0.001);
	vec2 point = (pixel - vec2(160.0, 90.0)) / radius;
	vec2 cheeks = abs((point - vec2(0.0, 0.13)) / vec2(1.0, 0.75));
	float face = pow(cheeks.x, 3.0) + pow(cheeks.y, 2.5) - 1.0;
	float left_ear = triangle(point, vec2(-0.91, -0.02), vec2(-0.89, -0.99), vec2(-0.19, -0.42));
	float right_ear = triangle(point, vec2(0.16, -0.42), vec2(0.82, -1.07), vec2(0.94, -0.02));
	float silhouette = min(face, min(left_ear, right_ear));

	float covered = progress >= 1.0 ? 1.0 : step(0.0, silhouette);
	COLOR = vec4(curtain_color.rgb, covered);
}
