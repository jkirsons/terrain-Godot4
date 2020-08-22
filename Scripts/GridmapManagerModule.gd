@tool
extends GridMap

@export_node_path(Node3D) var playerPath : NodePath
var player : Node3D

@export_node_path(WaveCollapse) var wavecollapsePath : NodePath
var wavecollapse : WaveCollapse

var lastPlayerPos := Vector3()
var mutex = Mutex.new()
var tiles = {}

func _ready():
	#if not Engine.editor_hint:
	player = get_node(playerPath) as Node3D
	wavecollapse = get_node(wavecollapsePath) as WaveCollapse
	setup()

func setup():
	clear()
	var self_var = self
	#wavecollapse.connect("cell_changed", Callable(self_var, "_on_Model_tile_ready"))
	wavecollapse.connect("cell_changed", self._on_Model_tile_ready)
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
