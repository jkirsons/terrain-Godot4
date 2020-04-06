extends Camera

export var speed = 3.0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_toplevel(true)

func _physics_process(delta):
	var target = get_parent().get_global_transform().origin
	var player = get_parent().get_parent().get_global_transform().origin
	var pos = get_global_transform().origin
	var offset = pos - target
	pos = pos - offset * delta * speed
	look_at_from_position(pos, player, Vector3.UP)
