#tool
#extends "res://Scripts/FillMethods.gd"
extends Spatial

export var sandPath : NodePath
export var waterPath : NodePath
export var landPath : NodePath
export var updateScene : bool = false

onready var sandGridMap : GridMap = get_node(sandPath)
onready var waterGridMap : GridMap = get_node(waterPath)
onready var landGridMap : GridMap = get_node(landPath)

const WaveFunction = preload("res://Scripts/WaveFunction.gd")

func _ready():
	#if Engine.editor_hint:
	#loadTiles()
	updateScene = true

func _process(delta):
	if updateScene:
		"""
		loadTiles()
		if waterGridMap:
			waterGridMap.clear()
			fillRect(-20, -20, 0, 40, 40, waterGridMap, "Water2")
		
		if sandGridMap:
			sandGridMap.clear()
			fillCircle (0, 0, 0, 8, sandGridMap, "Sand")
			
		if landGridMap:
			landGridMap.clear()
			fillCircle (0, 5, 0, 2, landGridMap, "Hill_Flat")
		"""
		
		var input_matrix = {}
		if landGridMap:
			for pos in landGridMap.get_used_cells():
				input_matrix[pos] = [landGridMap.get_cell_item(pos.x, pos.y, pos.z), landGridMap.get_cell_item_orientation(pos.x, pos.y, pos.z)]
		
		var ret = WaveFunction.Model.parse_matrix(input_matrix)
		var compatibility_oracle = WaveFunction.CompatibilityOracle.new(ret[0])
		var model = WaveFunction.Model.new([10, 50], ret[1], compatibility_oracle)
		var output = model.run()
		
		
		updateScene = false
