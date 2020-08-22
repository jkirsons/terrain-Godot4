@tool
extends Node3D

@export var new_material : Material

func _ready():
	# Change tile materials to shader versions
	if Engine.editor_hint:
		get_childrenx(self)

func get_childrenx(node):
	for child in node.get_children():
		if child.get_class() == 'MeshInstance3D':
			for i in range(child.mesh.get_surface_count() as int):
				#var mat = child.mesh.surface_get_material(i)
				print(child.name)
				child.mesh.surface_set_material(i, new_material)
		get_childrenx(child)
