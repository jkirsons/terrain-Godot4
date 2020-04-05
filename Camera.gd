extends Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_toplevel(true)

func _physics_process(delta):
	var target = get_parent().get_global_transform().origin
	var pos = get_global_transform().origin
	var offset = pos - target
	
	look_at_from_position(pos - offset * delta, target, Vector3.UP)
