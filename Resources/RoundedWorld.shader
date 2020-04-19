shader_type spatial;
render_mode world_vertex_coords, depth_draw_alpha_prepass;//, cull_disabled;//, vertex_lighting;

// Rounded World
uniform float world_roundness = 25.0;
uniform float world_falloff = 3.0;
uniform sampler2D BASE_TEX;

void vertex() {
	float dist = length(CAMERA_MATRIX[3].xyz - VERTEX) / world_roundness; 
	VERTEX.y -= pow(dist, world_falloff); 
}

void fragment() {
	vec4 tex = texture(BASE_TEX, UV);

	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	//METALLIC = 0.0;
	//SPECULAR = 0.0;
	ROUGHNESS = 1.0;	
}