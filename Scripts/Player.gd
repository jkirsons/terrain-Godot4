extends KinematicBody

export var gravity = -10
export var max_speed = 5
export var turn_speed = 1.2
export var fixedMode := true

onready var camera = get_node("/root/Spatial/Player/Target/Camera")
onready var anim = get_node("AnimationTree")

var velocity = Vector3()
var inputs = {"ui_up": Vector3.FORWARD, "ui_down": Vector3.BACK, "ui_left": Vector3.LEFT, "ui_right": Vector3.RIGHT}

func _ready():
	camera.fixedMode = fixedMode

func _physics_process(delta):
	velocity.y += gravity * delta
	var input = get_input()
	var desired_velocity 
	if fixedMode:
		desired_velocity = input * max_speed
	else:
		desired_velocity = global_transform.basis.xform(Vector3(0,0,input.z) * max_speed)

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity = move_and_slide(velocity, Vector3.UP, true)
	if fixedMode:
		anim.set("parameters/Idle_Run/blend_amount", input.length())
	else:
		anim.set("parameters/Idle_Run/blend_amount", abs(input.z))

	if(input != Vector3.ZERO and fixedMode):
		var dir = input.rotated(Vector3.UP, -PI/2.0).normalized()
		transform.basis = Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
	if(input != Vector3.ZERO and not fixedMode):
		var angle = min(PI/2, Vector3.FORWARD.angle_to(input)) * sign(input.x) * -1
		var turnBasis = Basis(Vector3.UP, angle)
		global_transform.basis = global_transform.basis * Basis().slerp(turnBasis, delta * turn_speed)
		#global_transform.basis = global_transform.basis.rotated(Vector3.UP, angle * delta * turn_speed)

func get_input():
	var input_dir = Vector3()
	if Input.is_action_just_pressed("change_camera"):
		fixedMode =! fixedMode
		camera.fixedMode = fixedMode
		
	for action in inputs:
		if Input.is_action_pressed(action):
			input_dir += inputs[action] * Input.get_action_strength(action)
	return input_dir#.normalized()
