shader_type canvas_item;


uniform int color_depth : hint_range(1, 8) = 5;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform bool dithering = true;
uniform int pixel_size :hint_range(1, 8) = 4;
uniform vec4 tint : hint_color = vec4(1.0);
uniform float contrast : hint_range(0, 5) = 1.0;
uniform float saturation : hint_range(0, 5) = 1.0;



//---------------------------------------------
//CONTRAST
//---------------------------------------------
mat4 contrastMatrix( float _contrast ){
	float t = ( 1.0 - _contrast ) / 2.0;
    return mat4( 
		vec4(_contrast, 0, 0, 0),
		vec4(0, _contrast, 0, 0),
		vec4(0, 0, _contrast, 0),
		vec4(t, t, t, 1));
}

//---------------------------------------------
//SATURATION
//---------------------------------------------
mat4 saturationMatrix( float _saturation ){
    vec3 luminance = vec3( 0.3086, 0.6094, 0.0820 );
    float oneMinusSat = 1.0 - _saturation;
	
    vec3 red = vec3( luminance.x * oneMinusSat );
    red+= vec3(_saturation, 0, 0);
    vec3 green = vec3( luminance.y * oneMinusSat );
    green += vec3( 0,_saturation, 0 );
    vec3 blue = vec3( luminance.z * oneMinusSat );
    blue += vec3( 0, 0,_saturation );
	
    return mat4(vec4(red, 0),vec4(green,0),vec4(blue,0),vec4(0, 0, 0, 1));
}

int dithering_pattern(ivec2 fragcoord) {
	const int pattern[] = {
		-4, +0, -3, +1, 
		+2, -2, +3, -1, 
		-3, +1, -4, +0, 
		+3, -1, +2, -2
	};
	
	int x = fragcoord.x % 4;
	int y = fragcoord.y % 4;
	
	return pattern[y * 4 + x];
}


vec4 dither(sampler2D image, vec2 uv, int resolution_scale){
	ivec2 new_uv = ivec2(uv / float(resolution_scale));
	vec3 color = (contrastMatrix( contrast ) *saturationMatrix( saturation )*texelFetch(image, new_uv * resolution_scale, 0) ).rgb ;
	
	// Convert from [0.0, 1.0] range to [0, 255] range
	ivec3 c = ivec3(round(color * 255.0 * brightness));
	
	// Apply the dithering pattern
	if (dithering) {
		c += ivec3(dithering_pattern(new_uv));
	}
	
	// Truncate from 8 bits to color_depth bits
	c >>= (8 - color_depth);
	return  vec4(vec3(c) / float(1 << color_depth), 1.0);
}



void fragment() 
{
	
    COLOR.rgb = tint.rgb*dither(SCREEN_TEXTURE, SCREEN_UV/SCREEN_PIXEL_SIZE, pixel_size).rgb;

}