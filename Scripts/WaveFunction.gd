# https://github.com/robert/wavefunction-collapse

class CompatibilityOracle:
	"""The CompatibilityOracle class is responsible for telling us
	which combinations of tiles and directions are compatible. It's
	so simple that it perhaps doesn't need to be a class, but I think
	it helps keep things clear.
	"""
	var data = {}
	
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
	var coefficients = {}
	var weights = {}
	var gridmap : GridMap

	func _init(weights_in, gridmap):
		weights = weights_in.duplicate(true)
		self.gridmap = gridmap

	func add_cell(co_ords, tiles = null):
		if tiles == null:
			tiles = weights.keys()
		coefficients[Vector2(co_ords[0],co_ords[1])] = tiles

	func remove_cell(co_ords):
		coefficients.erase(co_ords)

	func get(co_ords):
		"""Returns the set of possible tiles at `co_ords`"""
		return coefficients[Vector2(co_ords[0],co_ords[1])]
		
	func set(co_ords, tile, set_tilemap = true):
		coefficients[Vector2(co_ords[0],co_ords[1])] = [tile]
		if set_tilemap:
			gridmap.set_cell_item(co_ords[0], 0, co_ords[1], tile[0], tile[1])

	func get_collapsed(co_ords):
		"""Returns the only remaining possible tile at `co_ords`.
		If there is not exactly 1 remaining possible tile then
		this method raises an exception. """
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
		"""Calculates the Shannon Entropy of the wavefunction at `co_ords`."""
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
	var compatibility_oracle : CompatibilityOracle
	var wavefunction : Wavefunction
	const DIRS = [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
	
	func _init(weights, compatibility_oracle_in, gridmap):
		compatibility_oracle = compatibility_oracle_in
		wavefunction = Wavefunction.new(weights, gridmap)

	func run():
		"""Collapses the Wavefunction until it is fully collapsed,
		then returns a 2-D matrix of the final, collapsed state. """
		if not wavefunction.is_fully_collapsed():
			iterate()
		#return wavefunction.get_all_collapsed()
		return wavefunction.is_fully_collapsed()

	func updateRadius(co_ords, radius):
		var noUpdate = true
		for x in range(-radius, radius+1):
			for y in range(-radius, radius+1):
				if (pow(x,2) + pow(y,2)) <= pow(radius,2):
					var tile = [co_ords[0]+x, co_ords[1]+y]
					wavefunction.add_cell(tile)
					propagate(tile)
					noUpdate = false;
		
		# remove cells no longer in range
		for cell in wavefunction.coefficients:
			if (pow(cell[0], 2) + pow(cell[1], 2)) > pow(radius, 2):
				wavefunction.remove_cell(cell)
		
		return noUpdate

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
		
		var cell = wavefunction.get(co_ords)
		if cell.size() == 1:
			wavefunction.gridmap.set_cell_item(co_ords[0], 0, co_ords[1], cell[0][0], cell[0][1])

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
			for d in DIRS: #valid_dirs(cur_coords, output_size):
				var other_coords = [cur_coords[0] + d.x, cur_coords[1] + d.y]
				if not Vector2(other_coords[0], other_coords[1]) in wavefunction.coefficients:
					continue
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
					wavefunction.set(other_coords, new_tiles[0], len(new_tiles) == 1)
					if not stack.has(other_coords):
						stack.append(other_coords)

	func set(co_ords, tile, propagate = true):
		wavefunction.set(co_ords, tile)
		if propagate:
			propagate(co_ords)

	func min_entropy_co_ords():
		"""Returns the co-ords of the location whose wavefunction has the lowest entropy. """
		var min_entropy = null
		var min_entropy_coords = null

		for cell in wavefunction.coefficients:
				if len(wavefunction.get([cell.x,cell.y])) == 1:
					continue

				var entropy = wavefunction.shannon_entropy([cell.x, cell.y])
				# Add some noise to mix things up a little
				var entropy_plus_noise = entropy - (randf() / 1000)
				if min_entropy == null or entropy_plus_noise < min_entropy:
					min_entropy = entropy_plus_noise
					min_entropy_coords = [cell.x, cell.y]

		return min_entropy_coords
