extends TextureRect


#shader_type canvas_item;
#
func fragment() -> void:
	pass
	#COLOR.rgb = 1.0 - textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb
	#COLOR.a = texture(TEXTURE , UV).a;
