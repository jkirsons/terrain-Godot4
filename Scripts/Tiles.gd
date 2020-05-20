tool
extends Node3D

func _ready():
	# Change tile materials to shader versions
	if Engine.editor_hint:
		var material = load("res://Resources/Material_RoundedWorld.tres")
		var material2 = load("res://Resources/Material_Water.tres")
		var originalMat = load("res://Resources/Material.material")
		for child in get_children():
			if child.name != "AnimationPlayer":
				for i in range(child.mesh.get_surface_count()):
					var mat = child.mesh.surface_get_material(i)
					if mat == originalMat:
						child.mesh.surface_set_material(i, material)
					else:
						child.mesh.surface_set_material(i, material2)
