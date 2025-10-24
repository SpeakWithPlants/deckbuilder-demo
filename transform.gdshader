shader_type canvas_item;

void vertex() {
	UV.x = (UV.x - 0.5) * (((cos(TIME * 2.0) + 1.0) * 0.5) * 0.05 + 1.0) + 0.5;
}
