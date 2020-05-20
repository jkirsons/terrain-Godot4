extends Camera3D

export var speed = 4.0
var fixedMode := true # This is set on the player

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_toplevel(true)

func _physics_process(delta):
	var player = get_parent().get_parent().global_transform.origin
	var pos = global_transform.origin
	var target 
	
	if fixedMode:
		# global offset from player
		target = player + get_parent().transform.origin
	else:
		# behind player
		target = get_parent().global_transform.origin
		
	var offset = pos - target
	pos = pos - offset * delta * speed
	look_at_from_position(pos, player, Vector3.UP)
