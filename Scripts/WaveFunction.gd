#extends Spatial
#class_name WaveFunction
# https://github.com/robert/wavefunction-collapse

const DIRS = [[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]

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
		return [tile1, tile2, direction] in data

class Wavefunction:

	"""The Wavefunction class is responsible for storing which tiles
	are permitted and forbidden in each location of an output image.
	"""
	var coefficients = []
	var weights = {}
	
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
		var coef = []
		for x in range(size[0]):
			var row = []
			for y in range(size[1]):
				row.append(tiles)
			coef.append(row)

		return coef

	func _init(coef_in, weights_in):
		coefficients = coef_in.duplicate(true)
		weights = weights_in.duplicate(true)

	func get(co_ords):
		"""Returns the set of possible tiles at `co_ords`"""
		var x = co_ords[0]
		var y = co_ords[1]
		return coefficients[x][y]

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
		var x = co_ords[0]
		var y = co_ords[1]

		var sum_of_weights = 0
		var sum_of_weight_log_weights = 0
		for opt in self.coefficients[x][y]:
			var weight = self.weights[opt]
			sum_of_weights += weight
			sum_of_weight_log_weights += weight * log(weight)

		return log(sum_of_weights) - (sum_of_weight_log_weights / sum_of_weights)


	func is_fully_collapsed():
		# Returns true if every element in Wavefunction is fully collapsed, and false otherwise.
		for row in coefficients:
			for sq in row:
				if len(sq) > 1:
					return false
		return true

	func collapse(co_ords):
		"""Collapses the wavefunction at `co_ords` to a single, definite
		tile. The tile is chosen randomly from the remaining possible tiles
		at `co_ords`, weighted according to the Wavefunction's global `weights`.
		This method mutates the Wavefunction, and does not return anything.
		"""
		var x = co_ords[0]
		var y = co_ords[1]
		var opts = coefficients[x][y]
		#valid_weights = {tile: weight for [tile, weight] in self.weights.items() if tile in opts}
		var valid_weights = {}
		for tile in weights:
			if tile in opts:
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

		coefficients[x][y] = [chosen[0]]

	func constrain(co_ords, forbidden_tile):
		"""Removes `forbidden_tile` from the list of possible tiles
		at `co_ords`.
		This method mutates the Wavefunction, and does not return anything.
		"""
		var x = co_ords[0]
		var y = co_ords[1]
		coefficients[x][y].erase(forbidden_tile)

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

	func run():
		"""Collapses the Wavefunction until it is fully collapsed,
		then returns a 2-D matrix of the final, collapsed state.
		"""
		while not wavefunction.is_fully_collapsed():
			iterate()

		return wavefunction.get_all_collapsed()

	func iterate():
		"""Performs a single iteration of the Wavefunction Collapse
		Algorithm.
		"""
		# 1. Find the co-ordinates of minimum entropy
		var co_ords = min_entropy_co_ords()
		# 2. Collapse the wavefunction at these co-ordinates
		wavefunction.collapse(co_ords)
		# 3. Propagate the consequences of this collapse
		propagate(co_ords)

	static func valid_dirs(cur_co_ord, matrix_size):
		"""Returns the valid directions from `cur_co_ord` in a matrix
		of `matrix_size`. Ensures that we don't try to take step to the
		left when we are already on the left edge of the matrix.
		"""
		var x = cur_co_ord[0]
		var y = cur_co_ord[1]
		var width = matrix_size[0]
		var height = matrix_size[1]
		var dirs = []
		
		for dir in DIRS:
			var new_x = x + dir[0]
			var new_y = y + dir[1]
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
				var other_coords = [cur_coords[0] + d[0], cur_coords[1] + d[1]]

				# Iterate through each possible tile in the adjacent location's
				# wavefunction.
				for other_tile in wavefunction.get(other_coords):
					# Check whether the tile is compatible with any tile in
					# the current location's wavefunction.
					var other_tile_is_possible = false
					for cur_tile in cur_possible_tiles:
						if compatibility_oracle.check(cur_tile, other_tile, d):
							other_tile_is_possible = true
							break
					# If the tile is not compatible with any of the tiles in
					# the current location's wavefunction then it is impossible
					# for it to ever get chosen. We therefore remove it from
					# the other location's wavefunction.
					if not other_tile_is_possible:
						wavefunction.constrain(other_coords, other_tile)
						#if not other_coords in stack:
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

	static func parse_matrix(matrix):
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
		var compatibilities = []
		var weights = {}
	
		for key in matrix:
			if not matrix[key] in weights:
				weights[matrix[key]] = 0
			weights[matrix[key]] += 1

			for d in DIRS:
				var other_tile_pos = Vector3(key.x+d[0], key.y, key.z+d[1])
				if other_tile_pos in matrix:
					compatibilities.append([matrix[key], matrix[other_tile_pos], d])
	
		return [compatibilities, weights]
