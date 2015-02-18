
class @Piece
	@meshes = []
	@pieces = []
	constructor: (@team)->
		material = P.createMaterial(
			new T.MeshPhongMaterial(color: if @team is 1 then 0xFF5D5E else 0x432FFF)
			0.8 # high friction
			0.3 # low restitution
		)
		
		u = 0.1
		
		points = [
			new V2(-u, 0)
			new V2(-u, u/999)
			new V2(0, u)
			new V2(u, u/999)
			new V2(u, 0)
		]
		
		shape = new T.Shape(points)
		
		geometry = new T.ExtrudeGeometry(shape,
			amount: 2
			steps: 1
			#material: 1
			#extrudeMaterial: 0
			bevelEnabled: yes
			bevelThickness: 1
			bevelSize: 4
			bevelSegments: 4
		)
		
		@mesh = new T.Mesh(geometry, material)
		
		###@mesh = new P.ConvexMesh(geometry, material, 1)###

		@mesh.receiveShadow = true
		
		@mesh.piece = @
		scene.add @mesh
		Piece.meshes.push @mesh
		Piece.pieces.push @
	
	position: (@xi, @yi, fx, fy)->
		# sets the position of the piece
		@xi_lag ?= @xi
		@yi_lag ?= @yi
		@fx = fx ? @fx
		@fy = fy ? @fy
		@fx_lag ?= @fx
		@fy_lag ?= @fy
		@
	
	move: (xi, yi, fx, fy)->
		# moves the piece, sending the update to the server
		if board.space_free(xi, yi)
			
			if socket?
				socket.emit 'position', {pi: Piece.pieces.indexOf(@), xi, yi, fx, fy}
				it_is_your_turn = false
			
			@position xi, yi, fx, fy
		
		@
	
	update: ->
		# called every frame, animates the movement of the piece
		slowness = 10
		@xi_lag += (@xi - @xi_lag) / slowness
		@yi_lag += (@yi - @yi_lag) / slowness
		@fx_lag += (@fx - @fx_lag) / slowness
		@fy_lag += (@fy - @fy_lag) / slowness
		@mesh.position.set(
			board.get_tile_x @xi_lag
			5
			board.get_tile_y @yi_lag
		)
		rotation = Math.atan2(@fy_lag, @fx_lag)
		@mesh.rotation.set(
			TAU/4
			0
			rotation - TAU/4
		)
		@

