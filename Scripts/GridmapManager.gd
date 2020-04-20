tool
#extends "res://Scripts/FillMethods.gd"
extends GridMap

export var templatePath : NodePath
onready var templateGridMap : GridMap = get_node(templatePath)

export var updateScene : bool = false
var done := true

const WaveFunction = preload("res://Scripts/WaveFunction.gd")
var model : WaveFunction.Model

func _ready():
	if Engine.editor_hint:
		#loadTiles()
		pass
	else:
		updateScene = true
		
			
func _process(delta):
	if updateScene:
		updateScene = false
		done = false
		"""
		loadTiles()
		fillRect(-20, -20, 0, 40, 40, waterGridMap, "Water2")
		fillCircle (0, 0, 0, 8, sandGridMap, "Sand")
		fillCircle (0, 5, 0, 2, landGridMap, "Hill_Flat")
		"""
		clear()
		mesh_library = templateGridMap.mesh_library
		cell_size = templateGridMap.cell_size

		
		var input_matrix = {}
		if templateGridMap:
			for pos in templateGridMap.get_used_cells():
				input_matrix[pos] = [templateGridMap.get_cell_item(pos.x, pos.y, pos.z), templateGridMap.get_cell_item_orientation(pos.x, pos.y, pos.z)]
		
		var ret = WaveFunction.Model.parse_matrix(input_matrix)
		var compatibility_oracle = WaveFunction.CompatibilityOracle.new(ret[0])
		
		var file = File.new()
		file.open("res://Compatibility.json", file.WRITE)
		var ps = PoolStringArray(compatibility_oracle.data)
		file.store_string(ps.join(", "))
		file.close()

		for i in templateGridMap.mesh_library.get_item_list():
			print("Tile: ", i, " - ", templateGridMap.mesh_library.get_item_name(i))
					
		model = WaveFunction.Model.new([30, 30], ret[1], compatibility_oracle)
	
	if not done:
		done = model.run(self)
		
		"""
		var x = 0
		for row in output:
			var z = 0
			for col in row:
				set_cell_item(x, 0, z, col[0], col[1])
				z += 1
			x += 1
		"""
		

