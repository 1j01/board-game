
@piece_meshes = []
@pieces = []

class @Piece
	constructor: (@team)->
		material = P.createMaterial(
			new T.MeshPhongMaterial(color: @team.color)
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
		
		geometry = new T.ExtrudeGeometry(
			new T.Shape(points)
			
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
		
		@mesh.receiveShadow = yes
		
		@mesh.piece = @
		scene.add @mesh
		piece_meshes.push @mesh
		pieces.push @
		@team.pieces.push @
	
	position: (@xi, @yi, fx, fy)->
		
		@fx = fx ? @fx
		@fy = fy ? @fy
		
		@xi_lag ?= @xi
		@yi_lag ?= @yi
		@fx_lag ?= @fx
		@fy_lag ?= @fy
	
	move: (xi, yi, fx, fy)->
		# moves the piece, sending the update to the server
		if board.space_free(xi, yi)
			
			if socket?
				socket.emit 'position', {pi: pieces.indexOf(@), xi, yi, fx, fy}
				it_is_your_turn = false
			
			@position xi, yi, fx, fy
			
		else
			console?.log? "Can't move to #{xi}, #{yi}"
			console?.log? "From #{@xi}, #{@yi}"
	
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
