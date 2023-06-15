shader_type spatial;
render_mode unshaded, cull_front;

uniform bool enabled = true;
uniform float size: hint_range(0, 5, 0.01) = 2.5;
uniform vec3 outline_color: source_color = vec3(0.25, 0.75, 0.1);

void vertex() {
	if (enabled) {
		VERTEX += normalize(VERTEX) * (size / 100.0);
	}
}

void fragment() {
	if (enabled) {
		ALBEDO = outline_color;
	}
}
