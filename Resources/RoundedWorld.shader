shader_type spatial;
//render_mode world_vertex_coords;//, depth_draw_alpha_prepass;//, cull_disabled;//, vertex_lighting;
render_mode depth_draw_always;
// Rounded World
uniform float world_roundness = 25.0;
uniform float world_falloff = 3.0;
uniform sampler2D BASE_TEX;

vec3 to_world(mat4 world_matrix, vec3 pos)
{
	return (world_matrix * vec4(pos, 1.0)).xyz;
}

void vertex() {
	float dist = length(CAMERA_MATRIX[3].xyz - to_world(WORLD_MATRIX, VERTEX)) / world_roundness; 
	VERTEX -= (vec4(0.0, pow(dist, world_falloff), 0.0, 1.0) * WORLD_MATRIX).xyz;
	//float dist = length(CAMERA_MATRIX[3].xyz - VERTEX) / world_roundness; 
	//VERTEX.y -= pow(dist, world_falloff); 
}

void fragment() {
	vec4 tex = texture(BASE_TEX, UV);


	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	//METALLIC = 0.0;
	//SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}