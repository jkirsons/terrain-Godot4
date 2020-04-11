extends Spatial

var r0 = Basis().get_orthogonal_index()
var r1 = Basis( Quat(Vector3(0, 1, 0), deg2rad(90)) ).get_orthogonal_index()
var r2 = Basis( Quat(Vector3(0, 1, 0), deg2rad(180)) ).get_orthogonal_index()
var r3 = Basis( Quat(Vector3(0, 1, 0), deg2rad(270)) ).get_orthogonal_index()

func fillRect(x_start, z_start, y, width, height, gridMap :GridMap, itemName : String):
	var item = gridMap.mesh_library.find_item_by_name(itemName)
	for x in range(x_start, x_start+width):
		for z in range(z_start, z_start+height):
			gridMap.set_cell_item(x, y, z, item)

func fillCircle(x_centre, z_centre, y, radius, gridMap : GridMap, \
	itemName : String):
	var item = gridMap.mesh_library.find_item_by_name(itemName)
	
	var buffer = {}
	for x in range(-radius, radius+1):
		for y in range(-radius, radius+1):
			if (pow(x,2) + pow(y,2)) < pow(radius,2):
				buffer[[x, y]] = item
		
	for obj in buffer:
		gridMap.set_cell_item(obj[0] + x_centre, y, obj[1] + z_centre, buffer[obj])
	
	var edges = {}
	for obj in buffer:
		if [obj[0]+1,obj[1]] in buffer:
			edges[obj] = gridMap.mesh_library.find_item_by_name("Sand_Diagonal")
	
	for obj in edges:
		gridMap.set_cell_item(obj[0] + x_centre, y, obj[1] + z_centre, edges[obj])

