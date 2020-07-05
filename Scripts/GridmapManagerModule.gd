tool
extends GridMap

export var playerPath : NodePath
onready var player : Node3D = get_node(playerPath)

export var wavecollapsePath : NodePath
onready var wavecollapse : WaveCollapse = get_node(wavecollapsePath)

var lastPlayerPos := Vector3()
var mutex = Mutex.new()
var tiles = {}

func _ready():
	#if not Engine.editor_hint:
	setup()

func setup():
	clear()
	var self_var = self
	wavecollapse.connect("cell_changed", Callable(self_var, "_on_Model_tile_ready"))
	iterate()
	wavecollapse.process_thread()

func iterate():
	var currentPos = world_to_map(player.global_transform.origin)
	currentPos.y = 0
	wavecollapse._on_Player_position_changed(currentPos, 20.0)

func _on_Model_tile_ready(pos: Vector3i, item, orientation):
	call_deferred("set_cell_item", pos, item, orientation)

func _physics_process(delta):
	iterate()
