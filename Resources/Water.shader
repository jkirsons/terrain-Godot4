shader_type spatial;
//render_mode unshaded, world_vertex_coords;//, depth_draw_alpha_prepass;//, cull_disabled;
//render_mode depth_draw_always;
render_mode depth_draw_always, cull_disabled; //, world_vertex_coords;//, world_vertex_coords;//, world_vertex_coords;
// Rounded World
uniform float world_roundness = 24.0;
uniform float world_falloff = 3.0;

// For edge foam
uniform vec4 water_color : hint_color;
uniform vec4 foam_color : hint_color;
uniform sampler2D foam_texture : hint_white;
uniform float foam_depth = 0.17;
uniform float foam_y_stretch = 0.15;
uniform float foam_x_stretch = 1.0;
uniform float foam_speed = 7.0;
uniform float near = 0.15;
uniform float far = 300.0;

// For wave displacement
uniform vec2 wave_amplitude = vec2(0.04, 0.05);
uniform vec2 wave_frequency = vec2(0.4, 0.4);
uniform vec2 wave_time_factor = vec2(2.0, 2.0);
uniform float water_height = 0.0;

vec3 to_world(mat4 world_matrix, vec3 pos)
{
	//return pos;
	return (world_matrix * vec4(pos, 1.0)).xyz;
}

float height(vec2 pos, float time, float noise){
	return (wave_amplitude.x * sin(pos.x * wave_frequency.x * noise + time * wave_time_factor.x)) + (wave_amplitude.y * sin(pos.y * wave_frequency.y * noise + time * wave_time_factor.y));
}

float fake_random(vec2 p){
	return fract(sin(dot(p.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec2 faker(vec2 p){
	return vec2(fake_random(p), fake_random(p*124.32));
}

void vertex() {
	// rounded world	
	float dist = length(CAMERA_MATRIX[3].xyz - to_world(WORLD_MATRIX, VERTEX)) / world_roundness; 
	VERTEX -= (vec4(0.0, pow(dist, world_falloff), 0.0, 1.0) * WORLD_MATRIX).xyz;

	// wave displacement
	vec3 vertex = to_world(WORLD_MATRIX, VERTEX);
	
	float noise = faker(vertex.xz).x;
	VERTEX.y += height(vertex.xz, TIME, noise) + water_height;
	TANGENT = normalize( vec3(0.0, height(vertex.xz + vec2(0.0, 0.2), TIME, noise) - height(vertex.xz + vec2(0.0, -0.2), TIME, noise), 0.4));
	BINORMAL = normalize( vec3(0.4, height(vertex.xz + vec2(0.2, 0.0), TIME, noise) - height(vertex.xz + vec2(-0.2, 0.0), TIME, noise), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);	

}
 
float linearize(float c_depth) {
    c_depth = 2.0 * c_depth - 1.0;
    return near * far / (far + c_depth * (near - far));
}
 
void fragment()
{
	// edge foam
	//float zdepth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
    float zdepth = linearize(texture(DEPTH_TEXTURE, SCREEN_UV).x);
    float zpos = linearize(FRAGCOORD.z);
    float diff = zdepth - zpos;
   
    vec2 displ = texture(foam_texture, UV / foam_x_stretch - TIME / foam_speed).rg;
    displ = ((displ * 2.0) - 1.0) * foam_y_stretch;
    diff += displ.x;
   
    vec4 col = mix(foam_color, water_color, step(foam_depth, diff));

	if(false) {
		ALBEDO = vec3(0.0, 0.0, zdepth / 5.0);
	} else
	ALBEDO = col.rgb;
}