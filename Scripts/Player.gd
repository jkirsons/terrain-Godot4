extends KinematicBody

export var gravity = -10
export var max_speed = 4
export var fixedMode := true

onready var camera = get_node("/root/Spatial/Player/Target/Camera")
var velocity = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	velocity.y += gravity * delta
	var input = get_input()
	var desired_velocity 
	if fixedMode:
		desired_velocity = input * max_speed
	else:
		desired_velocity = global_transform.basis * input.z

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity = move_and_slide(velocity, Vector3.UP, true)

	if(input != Vector3.ZERO):
		transform.basis = Basis(input, Vector3.UP, input.cross(Vector3.UP))

func get_input():
	var input_dir = Vector3()
	# var trans = camera.get_global_transform()
	# desired move in camera direction
	if Input.is_action_pressed("ui_up"):
		input_dir += Vector3.FORWARD
	if Input.is_action_pressed("ui_down"):
		input_dir += Vector3.BACK
	if Input.is_action_pressed("ui_left"):
		input_dir += Vector3.LEFT
	if Input.is_action_pressed("ui_right"):
		input_dir += Vector3.RIGHT
	input_dir = input_dir.normalized()
	return input_dir
