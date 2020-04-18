#tool
#extends "res://Scripts/FillMethods.gd"
extends GridMap

export var templatePath : NodePath
onready var templateGridMap : GridMap = get_node(templatePath)

export var updateScene : bool = false

const WaveFunction = preload("res://Scripts/WaveFunction.gd")

func _ready():
	#if Engine.editor_hint:
	#loadTiles()
	updateScene = true

func _process(delta):
	if updateScene:
		updateScene = false
		"""
		loadTiles()
		fillRect(-20, -20, 0, 40, 40, waterGridMap, "Water2")
		fillCircle (0, 0, 0, 8, sandGridMap, "Sand")
		fillCircle (0, 5, 0, 2, landGridMap, "Hill_Flat")
		"""
		
		var input_matrix = {}
		if templateGridMap:
			for pos in templateGridMap.get_used_cells():
				input_matrix[pos] = [templateGridMap.get_cell_item(pos.x, pos.y, pos.z), templateGridMap.get_cell_item_orientation(pos.x, pos.y, pos.z)]
		
		var ret = WaveFunction.Model.parse_matrix(input_matrix)
		var compatibility_oracle = WaveFunction.CompatibilityOracle.new(ret[0])
		var model = WaveFunction.Model.new([10, 50], ret[1], compatibility_oracle)
		var output = model.run()
		
		clear()
		mesh_library = templateGridMap.mesh_library
		cell_size = templateGridMap.cell_size
		
		var x = 0
		var z = 0
		for row in output:
			x += 1
			for col in row:
				z += 1
				set_cell_item(x, 0, z, output[x][z][0], output[x][z][1])

