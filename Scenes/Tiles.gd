tool
extends Spatial

func _ready():
	# Change tile materials to shader versions
	if Engine.editor_hint:
		var material = load("res://Resources/Curved.tres")
		var material2 = load("res://Resources/CurvedWater.tres")
		for child in get_children():
			if child.name != "AnimationPlayer":
				if "Water" in child.name:
					child.mesh.surface_set_material(0, material2)
				else:
					child.mesh.surface_set_material(0, material)
