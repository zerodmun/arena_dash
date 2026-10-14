shader_type canvas_item;
void fragment() {
 vec4 c = texture(TEXTURE, UV);
 vec2 d = min(UV, vec2(1.0) - UV);
 float a = smoothstep(0.0, 0.18, min(d.x, d.y));
 COLOR = vec4(c.rgb, c.a * a * 0.55);
}
