extends Spatial

# Y-axis rotations for rotating tiles
var basisList = [
	Basis().get_orthogonal_index(),
	Basis( Quat(Vector3(0, 1, 0), deg2rad(90)) ).get_orthogonal_index(),
	Basis( Quat(Vector3(0, 1, 0), deg2rad(180)) ).get_orthogonal_index(),
	Basis( Quat(Vector3(0, 1, 0), deg2rad(270)) ).get_orthogonal_index()
	]

var surrounding = [[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]

export var tiles = {}

func _ready():
	loadTiles()

func loadTiles():
	var file = File.new()
	file.open("res://Tiles.json", file.READ)
	var txt = file.get_as_text()
	var data_parse = JSON.parse(txt)
	tiles = data_parse.result
	
	# pre-calculate rotation positions
	for tileSet in tiles:
		for tile in tiles[tileSet]:
			var height = tiles[tileSet][tile].height
			tiles[tileSet][tile].rotations = {}
			for i in range(4):
				# dictionary of rotations eg:  { [1,0,0,0]: 10 }
				var orth = tiles[tileSet][tile].orth + i
				if orth > 3: orth -= 4
				tiles[tileSet][tile].rotations[leftRotate(height.duplicate(), i)] = basisList[orth]

func smooth(buff, tileSet, mesh_library):
	var edges = {}
	var edgeRotation = {}
	for cell in buff:
		for offset in surrounding:
			var offset_cell = [cell[0]+offset[0],cell[1]+offset[1]]
			if not offset_cell in buff: # skip already filled cells
				var heights = getHeights(offset_cell, buff)
				# find a matching tile with these heights
				for tile in tiles[tileSet]:
					if tiles[tileSet][tile].rotations.has(heights):
						edgeRotation[offset_cell] = tiles[tileSet][tile].rotations[heights]
						edges[offset_cell] = mesh_library.find_item_by_name(tile)
	return {"edges": edges, "rotation": edgeRotation}

func getHeights(xy, buff):
	# Get cell heights based on neighbors
	var x = xy[0]
	var y = xy[1]
	# Order: ul, ur, lr, ll
	var h := [0.0, 0.0, 0.0, 0.0]
	# Sides
	if checkHeight([x, y-1], buff): 
		h[0] = 1.0; h[1] = 1.0
	if checkHeight([x, y+1], buff):
		h[2] = 1.0; h[3] = 1.0
	if checkHeight([x-1, y], buff):
		h[0] = 1.0; h[3] = 1.0
	if checkHeight([x+1, y], buff):
		h[1] = 1.0; h[2] = 1.0
	# Diagonals
	if checkHeight([x-1, y-1], buff):
		h[0] = 1.0
	if checkHeight([x+1, y-1], buff):
		h[1] = 1.0
	if checkHeight([x+1, y+1], buff):
		h[2] = 1.0
	if checkHeight([x-1, y+1], buff):
		h[3] = 1.0
	return h

func checkHeight(xy, buff):
	if xy in buff:
		if buff[xy] > 0:
			return true
	return false

func leftRotate(arr : Array, steps):
	for x in range(0,steps): 
		var temp = arr[0] 
		for i in range(arr.size() - 1): 
			arr[i] = arr[i+1] 
		arr[arr.size()-1] = temp
	return arr

func fillRect(x_start, z_start, y, width, height, gridMap :GridMap, itemName : String):
	var item = gridMap.mesh_library.find_item_by_name(itemName)
	for x in range(x_start, x_start+width):
		for z in range(z_start, z_start+height):
			gridMap.set_cell_item(x, y, z, item)

func fillCircle(x_centre, z_centre, y, radius, gridMap : GridMap, itemName : String):
	var item = gridMap.mesh_library.find_item_by_name(itemName)
	var tileSetName = ""
	for tileSet in tiles:
		if itemName in tiles[tileSet]:
			tileSetName = tileSet
	
	var buffer = {}
	for x in range(-radius, radius+1):
		for y in range(-radius, radius+1):
			if (pow(x,2) + pow(y,2)) < pow(radius,2):
				buffer[[x, y]] = item
		
	for obj in buffer:
		gridMap.set_cell_item(obj[0] + x_centre, y, obj[1] + z_centre, buffer[obj])
	
	# smooth edges
	var ret = smooth(buffer, tileSetName, gridMap.mesh_library)
	for obj in ret.edges:
		gridMap.set_cell_item(obj[0] + x_centre, y, obj[1] + z_centre, ret.edges[obj], ret.rotation[obj])
