#extends Spatial
#class_name WaveFunction
# https://github.com/robert/wavefunction-collapse

#const DIRS = [[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]
const DIRS = [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]

class CompatibilityOracle:
	"""The CompatibilityOracle class is responsible for telling us
	which combinations of tiles and directions are compatible. It's
	so simple that it perhaps doesn't need to be a class, but I think
	it helps keep things clear.
	"""
	var data = []
	
	func _init(data_in):
		data = data_in

	func check(tile1, tile2, direction):
		if direction in data:
			if tile1 in data[direction]:
				if tile2 in data[direction][tile1]:
					return true
		return false

class Wavefunction:

	"""The Wavefunction class is responsible for storing which tiles
	are permitted and forbidden in each location of an output image.
	"""
	var coefficients = []
	var weights = {}
	var gridmap : GridMap
	
	static func mk(size, weights_in):
		"""Initialize a new Wavefunction for a grid of `size`,
		where the different tiles have overall weights `weights`.
		Arguments:
		size -- a 2-tuple of (width, height)
		weights -- a dict of tile -> weight of tile
		"""
		var coef = Wavefunction.init_coefficients(size, weights_in.keys())
		return Wavefunction.new(coef, weights_in)

	static func init_coefficients(size, tiles):
		"""Initializes a 2-D wavefunction matrix of coefficients.
		The matrix has size `size`, and each element of the matrix
		starts with all tiles as possible. No tile is forbidden yet.
		Arguments:
		size -- a 2-tuple of (width, height)
		tiles -- a set of all the possible tiles
		Returns:
		A 2-D matrix in which each element is a set
		"""

		var coef = {}
		for x in range(size[0]):
			#var row = []
			for y in range(size[1]):
				coef[Vector2(x, y)] = tiles
				#row.append(tiles)
			#coef.append(row)

		return coef

	func _init(coef_in, weights_in):
		coefficients = coef_in.duplicate(true)
		weights = weights_in.duplicate(true)

	func get(co_ords):
		"""Returns the set of possible tiles at `co_ords`"""
		return coefficients[Vector2(co_ords[0],co_ords[1])]

	func get_collapsed(co_ords):
		"""Returns the only remaining possible tile at `co_ords`.
		If there is not exactly 1 remaining possible tile then
		this method raises an exception.
		"""
		var opts = get(co_ords)
		assert(len(opts) == 1)
		return opts[0]

	func get_all_collapsed():
		"""Returns a 2-D matrix of the only remaining possible
		tiles at each location in the wavefunction. If any location
		does not have exactly 1 remaining possible tile then
		this method raises an exception.
		"""
		var width = len(coefficients)
		var height = len(coefficients[0])

		var collapsed = []
		for x in range(width):
			var row = []
			for y in range(height):
				row.append(get_collapsed([x,y]))
			collapsed.append(row)

		return collapsed

	func shannon_entropy(co_ords):
		"""Calculates the Shannon Entropy of the wavefunction at
		`co_ords`.
		"""
		var sum_of_weights = 0
		var sum_of_weight_log_weights = 0
		for opt in self.coefficients[Vector2(co_ords[0],co_ords[1])]:
			var weight = self.weights[opt]
			sum_of_weights += weight
			sum_of_weight_log_weights += weight * log(weight)

		return log(sum_of_weights) - (sum_of_weight_log_weights / sum_of_weights)


	func is_fully_collapsed():
		# Returns true if every element in Wavefunction is fully collapsed, and false otherwise.
		for cell in coefficients:
			if len(coefficients[cell]) > 1:
				return false
		return true

	func collapse(co_ords):
		"""Collapses the wavefunction at `co_ords` to a single, definite
		tile. The tile is chosen randomly from the remaining possible tiles
		at `co_ords`, weighted according to the Wavefunction's global `weights`.
		This method mutates the Wavefunction, and does not return anything.
		"""
		var opts = coefficients[Vector2(co_ords[0],co_ords[1])]
		#valid_weights = {tile: weight for [tile, weight] in self.weights.items() if tile in opts}
		var valid_weights = {}
		for tile in weights:
			if opts.has(tile):
				valid_weights[tile] = weights[tile]

		var total_weights = 0
		for tile in valid_weights:
			total_weights += valid_weights[tile]
			
		var rnd = randf() * total_weights

		var chosen = null
		for tile in valid_weights:
			rnd -= valid_weights[tile]
			if rnd < 0:
				chosen = [tile, valid_weights[tile]]
				break

		coefficients[Vector2(co_ords[0],co_ords[1])] = [chosen[0]]
		#print("Collapsed ", co_ords, " to ", chosen[0])

class Model:
	"""The Model class is responsible for orchestrating the
	Wavefunction Collapse algorithm.
	"""
		
	var output_size
	var compatibility_oracle
	var wavefunction
	
	func _init(output_size_in, weights, compatibility_oracle_in):
		output_size = output_size_in
		compatibility_oracle = compatibility_oracle_in
		wavefunction = Wavefunction.mk(output_size, weights)

	func run(gridmap):
		"""Collapses the Wavefunction until it is fully collapsed,
		then returns a 2-D matrix of the final, collapsed state.
		"""
		wavefunction.gridmap = gridmap
		
		if not wavefunction.is_fully_collapsed():
			iterate(gridmap)

		#return wavefunction.get_all_collapsed()
		return wavefunction.is_fully_collapsed()

	func iterate(gridmap):
		"""Performs a single iteration of the Wavefunction Collapse
		Algorithm.
		"""
		# 1. Find the co-ordinates of minimum entropy
		var co_ords = min_entropy_co_ords()
		# 2. Collapse the wavefunction at these co-ordinates
		wavefunction.collapse(co_ords)
		# 3. Propagate the consequences of this collapse
		propagate(co_ords)
		
		var cell = wavefunction.get(co_ords)
		if cell.size() == 1:
			gridmap.set_cell_item(co_ords[0], 0, co_ords[1], cell[0][0], cell[0][1])

	static func valid_dirs(cur_co_ord, matrix_size):
		"""Returns the valid directions from `cur_co_ord` in a matrix
		of `matrix_size`. Ensures that we don't try to take step to the
		left when we are already on the left edge of the matrix.
		"""
		var width = matrix_size[0]
		var height = matrix_size[1]
		
		if cur_co_ord[0] > 1 and cur_co_ord[0] < width - 1 and cur_co_ord[1] > 1 and cur_co_ord[1] < height - 1:
			return DIRS
		
		var dirs = []
		for dir in DIRS:
			var new_x = cur_co_ord[0] + dir.x
			var new_y = cur_co_ord[1] + dir.y
			if -1 < new_x and new_x <  width and -1 < new_y and new_y < height:
				dirs.append(dir)
		
		return dirs
	
	func propagate(co_ords):
		"""Propagates the consequences of the wavefunction at `co_ords`
		collapsing. If the wavefunction at (x,y) collapses to a fixed tile,
		then some tiles may not longer be theoretically possible at
		surrounding locations.
		This method keeps propagating the consequences of the consequences,
		and so on until no consequences remain.
		"""
		var stack = [co_ords]
				
		while len(stack) > 0:
			var cur_coords = stack.pop_back()
			
			# Get the set of all possible tiles at the current location
			var cur_possible_tiles = wavefunction.get(cur_coords)

			# Iterate through each location immediately adjacent to the
			# current location.
			for d in valid_dirs(cur_coords, output_size):
				var other_coords = [cur_coords[0] + d.x, cur_coords[1] + d.y]
				# Iterate through each possible tile in the adjacent location's
				# wavefunction.
				var possible_other_tiles = wavefunction.get(other_coords).duplicate(true)
				if possible_other_tiles.size() == 1:
					continue

				var new_tiles = []
				for other_tile in possible_other_tiles:
					# Check whether the tile is compatible with any tile in
					# the current location's wavefunction.
					for cur_tile in cur_possible_tiles:
						if compatibility_oracle.check(cur_tile, other_tile, d):
							new_tiles.append(other_tile)
							break

				# If the tile is not compatible with any of the tiles in
				# the current location's wavefunction then it is impossible
				# for it to ever get chosen. We therefore remove it from
				# the other location's wavefunction.
				if len(new_tiles)!= len(possible_other_tiles):
					if len(new_tiles) == 1:
						wavefunction.gridmap.set_cell_item(other_coords[0], 0, other_coords[1], new_tiles[0][0], new_tiles[0][1])
					wavefunction.coefficients[Vector2(other_coords[0],other_coords[1])] = new_tiles
					if not stack.has(other_coords):
						stack.append(other_coords)

	func min_entropy_co_ords():
		"""Returns the co-ords of the location whose wavefunction has
		the lowest entropy.
		"""
		var min_entropy = null
		var min_entropy_coords = null

		for x in range(output_size[0]):
			for y in range(output_size[1]):
				if len(wavefunction.get([x,y])) == 1:
					continue

				var entropy = wavefunction.shannon_entropy([x, y])
				# Add some noise to mix things up a little
				var entropy_plus_noise = entropy - (randf() / 1000)
				if min_entropy == null or entropy_plus_noise < min_entropy:
					min_entropy = entropy_plus_noise
					min_entropy_coords = [x, y]

		return min_entropy_coords

class Parse:
	var compatibilities = {}
	var weights = {}
	
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
			compatibilities[dir][tile] = []
		if not other_tile in compatibilities[dir][tile]:
			compatibilities[dir][tile].append(other_tile)
		
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
