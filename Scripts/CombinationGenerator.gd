var compatibilities = {}
var weights = {}
const DIRS = [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]

func rotate(tuple, times):
	var basisList = [
		Basis().get_orthogonal_index(),
		Basis( Quat(Vector3(0, 1, 0), deg2rad(-90)) ).get_orthogonal_index(),
		Basis( Quat(Vector3(0, 1, 0), deg2rad(-180)) ).get_orthogonal_index(),
		Basis( Quat(Vector3(0, 1, 0), deg2rad(-270)) ).get_orthogonal_index()
		]
	
	var index = basisList.find(tuple[1])
	index += times 
	if index >= basisList.size():
		index -= basisList.size()
	return [tuple[0], basisList[index]]
	
func rotate_dir(dir, times):
	var index = DIRS.find(dir)
	index += times * 1
	if index >= DIRS.size():
		index -= DIRS.size()
	return DIRS[index]
	
func add_tile(tile, other_tile, dir):
	if not dir in compatibilities:
		compatibilities[dir] = {}
	if not tile in compatibilities[dir]:
		compatibilities[dir][tile] = {}
	if not compatibilities[dir][tile].has(other_tile):
		compatibilities[dir][tile][other_tile] = 1
	
func _init(matrix):
	"""Parses an example `matrix`. Extracts:
	1. Tile compatibilities - which pairs of tiles can be placed next
		to each other and in which directions
	2. Tile weights - how common different tiles are
	Arguments:
	matrix -- a 2-D matrix of tiles
	Returns:
	A tuple of:
	* A set of compatibile tile combinations, where each combination is of
		the form (tile1, tile2, direction)
	* A dict of weights of the form tile -> weight
	"""
	var symetric_tiles = [9, 15, 16]
	for key in matrix:
		for i in range(4):
			# only store 1 rotation for symetric tiles
			var tile = rotate(matrix[key], i)
			if matrix[key][0] in symetric_tiles:
				tile = [matrix[key][0], 0]
				
			if not tile in weights:
				weights[tile] = 0
			weights[tile] += 1

		for d in DIRS:
			var other_tile_pos = Vector3(key.x + d.x, key.y, key.z + d.y)
			if other_tile_pos in matrix:	# Mirrored positions
				for i in range(4):
					# only store 1 rotation for symetric tiles
					var tile = rotate(matrix[key], i)
					var other_tile = rotate(matrix[other_tile_pos], i)
					if matrix[key][0] in symetric_tiles:
						tile = [matrix[key][0],0]
					if matrix[other_tile_pos][0] in symetric_tiles:
						other_tile = [matrix[other_tile_pos][0],0]
					add_tile(tile, other_tile, rotate_dir(d, i))
