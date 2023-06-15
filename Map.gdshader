shader_type spatial;

void vertex() {
	VERTEX.y += sin(TIME * 5.0 + VERTEX.x * 1.0);
}

void fragment() {
	vec3 color;
	color.r = 0.0;
	color.g = 0.0;
	color.b = 0.0;
	ALBEDO = color;
}
