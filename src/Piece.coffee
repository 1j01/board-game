
@piece_meshes = []
@pieces = []

pickupSound = new MultiHowl "pickup", [0..3]
placeSound = new MultiHowl "place", [0..7]
cancelSound = new MultiHowl "cancel", [0]
moveSound = new MultiHowl "move", [0]

class @Piece
	constructor: (@team)->
		@lifted = no
		
		material = P.createMaterial(
			new T.MeshPhongMaterial(color: @team.color)
			0.8 # high friction
			0.3 # low restitution
		)
		
		u = 0.1
		o = 1
		points = [
			new V2(-u, -o)
			new V2(-u, u/999-o)
			new V2(0, u-o)
			new V2(u, u/999-o)
			new V2(u, -o)
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
		
		@mesh.scale.x = 0.9
		@mesh.scale.y = 0.8
		@mesh.scale.z = 0.5
		
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
		@lifted_lag ?= 0
	
	move: (xi, yi, fx, fy)->
		# moves the piece, sending the update to the server
		console.log "Move to #{xi}, #{yi}"
		if board.space_free(xi, yi)
			
			if socket?
				socket.emit 'position', {pi: pieces.indexOf(@), xi, yi, fx, fy}
				window.it_is_your_turn = false
			
			@position xi, yi, fx, fy
			
			moveSound.play()
			yes
		else
			console?.log? "Can't move to #{xi}, #{yi}"
			console?.log? "(From #{@xi}, #{@yi})"
			no
	
	rotate: (@fx, @fy)->
		# moveSound.play()
		if socket?
			socket.emit 'rotation', {pi: pieces.indexOf(@), fx, fy}
			window.it_is_your_turn = false
	
	lift: (@lifted = yes)->
		pickupSound.play()
	
	place: (xi, yi, fx, fy)->
		@lifted = no
		if xi? and @move xi, yi, fx, fy
			placeSound.play()
		else
			cancelSound.play()
	
	update: ->
		# called every frame, animates the movement of the piece
		slowness = 10
		@xi_lag += (@xi - @xi_lag) / slowness
		@yi_lag += (@yi - @yi_lag) / slowness
		@fx_lag += (@fx - @fx_lag) / slowness
		@fy_lag += (@fy - @fy_lag) / slowness
		@lifted_lag += (@lifted - @lifted_lag) / slowness
		@mesh.position.set(
			board.get_tile_x @xi_lag
			4 + @lifted_lag * 10
			board.get_tile_y @yi_lag
		)
		rotation = Math.atan2(@fy_lag, @fx_lag)
		@mesh.rotation.set(
			TAU/4 # - @lifted_lag/TAU # is not relative to the piece's orientation
			0
			rotation - TAU/4
		)

