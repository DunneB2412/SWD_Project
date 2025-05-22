shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//COLOR.rgb = 1.0 - textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	//COLOR.a = texture(TEXTURE , UV).a;

	vec4 tex_color = texture(TEXTURE, UV);

	if (tex_color.a > 0.0) {
		// Read the screen color underneath using screen UVs
		vec4 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
		COLOR = vec4(1.0 - screen_color.rgb, tex_color.a);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
