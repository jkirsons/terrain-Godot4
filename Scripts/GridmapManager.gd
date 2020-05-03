tool
extends GridMap

export var templatePath : NodePath
onready var templateGridMap : GridMap = get_node(templatePath)

export var playerPath : NodePath
onready var player : KinematicBody = get_node(playerPath)

export var updateScene : bool = false

var lastPlayerPos := Vector3()

const WaveFunction = preload("res://Scripts/WaveFunction.gd")
const CombinationGenerator = preload("res://Scripts/CombinationGenerator.gd")

var model : WaveFunction.Model

func _ready():
	if not Engine.editor_hint:
		setup()

func setup():
	# Print tile list
	for i in templateGridMap.mesh_library.get_item_list():
		print("Tile: ", i, " - ", templateGridMap.mesh_library.get_item_name(i))

	# Get possible tile combinations from template
	var input_matrix = {}
	for pos in templateGridMap.get_used_cells():
		input_matrix[pos] = [templateGridMap.get_cell_item(pos.x, pos.y, pos.z), templateGridMap.get_cell_item_orientation(pos.x, pos.y, pos.z)]
	var parse = CombinationGenerator.new(input_matrix)
	var compatibility_oracle = WaveFunction.CompatibilityOracle.new(parse.compatibilities)
	
	# Clear this gridmap
	clear()
	
	# Use the same settings as the template Gridmap
	mesh_library = templateGridMap.mesh_library
	cell_size = templateGridMap.cell_size
	
	model = WaveFunction.Model.new(parse.weights, compatibility_oracle)
	model.connect("tile_ready", self, "_on_Model_tile_ready")
	
	# Set under player to sand
	var position = world_to_map(player.global_transform.origin)
	model.updateRadius([position.x, position.z], 5)
	model.set([position.x, position.z], [[15, 0]])
	model.start()


func _on_Model_tile_ready(x, y, z, item, orientation):
	#set_cell_item(x, y, z, item, orientation)
	call_deferred("set_cell_item", x, y, z, item, orientation)

func _process(delta):
	if not Engine.editor_hint:
		var currentPos = world_to_map(player.global_transform.origin)
		if currentPos != lastPlayerPos:
			model.updateRadiusThread([currentPos.x, currentPos.z], 15)
			
	if updateScene:
		updateScene = false
		setup()


	"""
	var file = File.new()
	file.open("res://Compatibility.json", file.WRITE)
	var ps = PoolStringArray(compatibility_oracle.data)
	file.store_string(ps.join(", "))
	file.close()
	"""
