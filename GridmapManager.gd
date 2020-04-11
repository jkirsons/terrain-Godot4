tool
extends "res://FillMethods.gd"

export var sandPath : NodePath
onready var sandGridMap : GridMap = get_node(sandPath)

export var waterPath : NodePath
onready var waterGridMap : GridMap = get_node(waterPath)

export var landPath : NodePath
onready var landGridMap : GridMap = get_node(landPath)

export var updateScene : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#if Engine.editor_hint:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if updateScene:
		if waterGridMap:
			waterGridMap.clear()
			fillRect(-20, -20, 0, 40, 40, waterGridMap, "Water")
		if sandGridMap:
			sandGridMap.clear()
			fillCircle(0, 0, 0, 10, waterGridMap, "Sand")
		updateScene = false


