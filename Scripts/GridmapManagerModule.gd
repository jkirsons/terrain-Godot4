tool
extends GridMap

export var playerPath : NodePath
onready var player : Node3D = get_node(playerPath)

export var wavecollapsePath : NodePath
onready var wavecollapse : WaveCollapse = get_node(wavecollapsePath)

var lastPlayerPos := Vector3()

func _ready():
	#if not Engine.editor_hint:
	setup()

func setup():
	clear()
	var self_var = self
	wavecollapse.connect("cell_changed", Callable(self_var, "_on_Model_tile_ready"))
	iterate()

func iterate():
	var currentPos = world_to_map(player.global_transform.origin)
	wavecollapse._on_Player_position_changed(currentPos, 10.0)
	wavecollapse.process()

func _on_Model_tile_ready(pos, item, orientation):
	#set_cell_item(x, y, z, item, orientation)
	call_deferred("set_cell_item", pos.x, pos.y, pos.z, item, orientation)

func _process(delta):
	iterate()
