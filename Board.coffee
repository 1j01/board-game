
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
		
		tile_material_1 = P.createMaterial(
			new T.MeshPhongMaterial(color: 0xF4EDCE)
			0.8 # high friction
			0.3 # low restitution
		)
		tile_material_2 = P.createMaterial(
			new T.MeshPhongMaterial(color: 0x432F29)
			0.8 # high friction
			0.3 # low restitution
		)
		
		@tile_meshes = []
		
		for xi in [0...@tiles_x]
			for yi in [0...@tiles_y]
				
				tile_mesh = new P.BoxMesh(
					new T.BoxGeometry(tile_length, thickness, tile_length)
					(if ((xi+yi)%2) is 0 then tile_material_1 else tile_material_2)
					0 # mass, 0 = static
				)
				tile_mesh.position.set(
					@get_tile_x xi
					tile_thickness
					@get_tile_y yi
				)
				tile_mesh.receiveShadow = true
				
				scene.add tile_mesh
				
				@tile_meshes.push tile_mesh
	
	
	get_tile_x: (xi)-> (xi+.5) * spaced_tile_length - @width/2
	get_tile_y: (yi)-> (yi+.5) * spaced_tile_length - @height/2
	
	space_free: (xi, yi)->
		return no if xi < 0 or yi < 0 or xi >= board.tiles_x or yi >= board.tiles_y
		#return no unless 0 >= xi > board.tiles_x and 0 >= yi > board.tiles_y
		
		for p in Piece.pieces
			return no if p.xi is xi and p.yi is yi
		
		return yes
	
	space_occupied: (xi, yi)-> not @space_free()
	
