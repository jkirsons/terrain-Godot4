extends KinematicBody

export var gravity = -10
export var max_speed = 4

onready var camera = get_node("/root/Spatial/Player/Target/Camera")
var velocity = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	velocity.y += gravity * delta
	var desired_velocity = get_input() * max_speed

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity = move_and_slide(velocity, Vector3.UP, true)
	

func get_input():
	var input_dir = Vector3()
	var trans = camera.get_global_transform()
	# desired move in camera direction
	if Input.is_action_pressed("ui_up"):
		input_dir += -trans.basis.z
	if Input.is_action_pressed("ui_down"):
		input_dir += trans.basis.z
	if Input.is_action_pressed("ui_left"):
		input_dir += -trans.basis.x
	if Input.is_action_pressed("ui_right"):
		input_dir += trans.basis.x
	input_dir = input_dir.normalized()
	return input_dir
