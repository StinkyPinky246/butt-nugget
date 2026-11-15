shader_type canvas_item;

uniform vec4 outline : source_color = vec4(0.044, 0.059, 0.104, 1.0);
uniform vec4 highlight : source_color = vec4(1.0, 1.0, 1.0, 0.0);
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 sprite = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	float lit_edge = max(texture(TEXTURE, UV + vec2(px.x, 0)).a, texture(TEXTURE, UV + vec2(0, px.y)).a);
	float shadow_edge = max(texture(TEXTURE, UV - vec2(px.x, 0)).a, texture(TEXTURE, UV - vec2(0, px.y)).a);
	float edge = max(lit_edge, shadow_edge);
	vec3 rim = mix(outline.rgb, highlight.rgb, lit_edge * highlight.a);
	COLOR = mix(vec4(rim, edge * outline.a), sprite, step(0.05, sprite.a)) * tint;
}
