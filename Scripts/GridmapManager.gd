tool
extends "res://Scripts/FillMethods.gd"

export var sandPath : NodePath
export var waterPath : NodePath
export var landPath : NodePath
export var updateScene : bool = false

onready var sandGridMap : GridMap = get_node(sandPath)
onready var waterGridMap : GridMap = get_node(waterPath)
onready var landGridMap : GridMap = get_node(landPath)

func _ready():
	#if Engine.editor_hint:
	loadTiles()
	updateScene = true

func _process(delta):
	if updateScene:
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
		
		updateScene = false
