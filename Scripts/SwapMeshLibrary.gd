@tool
extends GridMap

@export var swapWith : MeshLibrary

func _ready():
	for tile in mesh_library.get_item_list():
		print(tile, ': ', mesh_library.get_item_name(tile))

func _process(delta):
	if swapWith != null:
		var map = {} 
		for tile in mesh_library.get_item_list():
			var name = mesh_library.get_item_name(tile)
			print(tile, ': ', name, " maps to: ", swapWith.find_item_by_name(name))
			map[tile] = swapWith.find_item_by_name(name)
		
		for vec in get_used_cells():
			set_cell_item(vec, map[get_cell_item(vec)], get_cell_item_orientation(vec))
		
		mesh_library = swapWith
		swapWith = null
