
class @Board
	
	thickness = 4
	extension = 5
	tile_length = 10
	tile_spacing = 0
	tile_thickness = 0.9
	spaced_tile_length = tile_length + tile_spacing
	
	tiles_x: 10
	tiles_y: 14
	
	constructor: ->
		@width = spaced_tile_length * @tiles_x
		@height = spaced_tile_length * @tiles_y
		
		base_material = P.createMaterial(
			new T.MeshPhongMaterial(color: 0x77544A)
			0.8 # high friction
			0.3 # low restitution
		)
		
		@base_mesh = new P.BoxMesh(
			new T.BoxGeometry(
				@width + extension
				thickness
				@height + extension
			)
			base_material
			0 # mass, 0 = static
		)
		@base_mesh.position.set(0, 0, 0)
		@base_mesh.receiveShadow = true
		
		scene.add @base_mesh
		
		@tile_meshes = []
		
		for xi in [0...@tiles_x]
			for yi in [0...@tiles_y]
				
				tile_mesh = new P.BoxMesh(
					new T.BoxGeometry(tile_length, thickness, tile_length)
					P.createMaterial(
						new T.MeshPhongMaterial(
							color: if (xi+yi)%2 is 0 then 0x432F29 else 0xF4EDCE
						)
						0.8 # high friction
						0.3 # low restitution
					)
					0 # mass; 0 = static
				)
				tile_mesh.position.set(
					@get_tile_x xi
					tile_thickness
					@get_tile_y yi
				)
				tile_mesh.receiveShadow = true
				
				scene.add tile_mesh
				
				tile_mesh.xi = xi
				tile_mesh.yi = yi
				@tile_meshes.push tile_mesh
	
	
	get_tile_x: (xi)-> (xi + 1/2) * spaced_tile_length - @width/2
	get_tile_y: (yi)-> (yi + 1/2) * spaced_tile_length - @height/2
	
	space_free: (xi, yi)->
		
		within_bounds = (
			0 <= xi < board.tiles_x and
			0 <= yi < board.tiles_y
		)
		return no if not within_bounds
		
		for piece in pieces
			return no if (
				piece.xi is xi and
				piece.yi is yi
			)
		
		yes
	
