extends Camera

export var speed = 6.0
export var fixedMode := true

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_toplevel(true)

func _physics_process(delta):
	var player = get_parent().get_parent().get_global_transform().origin
	var pos = get_global_transform().origin
	
	var target 
	if fixedMode:
		target = player + get_parent().transform.origin
	else:
		target = get_parent().global_transform.origin
		
	var offset = pos - target
	pos = pos - offset * delta * speed
	look_at_from_position(pos, player, Vector3.UP)
