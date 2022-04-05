shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float blur: hint_range(0.0, 5) = 0.0;

void fragment(){
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, blur);
	COLOR = color;
}