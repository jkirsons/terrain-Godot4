shader_type spatial;
render_mode unshaded, world_vertex_coords, depth_draw_alpha_prepass, cull_disabled;
 
uniform vec4 main_color : hint_color;
uniform vec4 intersection_color : hint_color;
uniform float intersection_max_threshold = 0.5;
uniform sampler2D displ_tex : hint_white;
uniform float displ_amount = 0.6;
uniform float displ_x_amount = 1000.0;
uniform float displ_speed = 20.0;
uniform float near = 0.15;
uniform float far = 300.0;

uniform vec2 amplitude = vec2(0.05, 0.02);
uniform vec2 frequency = vec2(.2, .2);
uniform vec2 time_factor = vec2(2.0, 2.0);
uniform bool waves_by_height = false;
uniform float water_height = 0.05;
uniform sampler2D height_map;

float height(vec2 pos, float time, float noise){
	float t_height = texture(height_map, pos.xy * vec2(1.0)).r;
	float th = 1.0;
	if (waves_by_height) {
		th = t_height*.2;
	}
	return (amplitude.x * th * sin(pos.x * frequency.x * noise + time * time_factor.x)) + (amplitude.y * th * sin(pos.y * frequency.y * noise + time * time_factor.y));
}

float fake_random(vec2 p){
	return fract(sin(dot(p.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec2 faker(vec2 p){
	return vec2(fake_random(p), fake_random(p*124.32));
}

void vertex() {
	float dist = length(CAMERA_MATRIX[3].xyz - VERTEX) / 25.0; 
	VERTEX.y -= pow(dist, 3.0); 
	
	float noise = faker(VERTEX.xz).x;
	VERTEX.y += height(VERTEX.xz, TIME, noise) + water_height;
	TANGENT = normalize( vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME, noise) - height(VERTEX.xz + vec2(0.0, -0.2), TIME, noise), 0.4));
	BINORMAL = normalize( vec3(0.4, height(VERTEX.xz + vec2(0.2, 0.0), TIME, noise) - height(VERTEX.xz + vec2(-0.2, 0.0), TIME, noise), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);	
}
 
float linearize(float c_depth) {
    c_depth = 2.0 * c_depth - 1.0;
    return near * far / (far + c_depth * (near - far));
}
 
void fragment()
{
    float zdepth = linearize(texture(DEPTH_TEXTURE, SCREEN_UV).x);
    float zpos = linearize(FRAGCOORD.z);
    float diff = zdepth - zpos;
   
    vec2 displ = texture(displ_tex, UV / displ_x_amount - TIME / displ_speed).rg;
    displ = ((displ * 2.0) - 1.0) * displ_amount;
    diff += displ.x;
   
    vec4 col = mix(intersection_color, main_color, step(intersection_max_threshold, diff));
    ALBEDO = col.rgb;
   
}