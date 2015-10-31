
@dice = []
@dice_meshes = []

class @Die
	constructor: (@type)->
		@lifted = no
		
		material = P.createMaterial(
			new T.MeshPhongMaterial(color: 0xff00ff)
			0.8 # high friction
			0.3 # low restitution
		)
		
		points =
			for i in [0..6]
				new V2(
					Math.sin(i/6*TAU)
					Math.cos(i/6*TAU)
				)
		
		geometry = new T.ExtrudeGeometry(
			new T.Shape(points)
			
			amount: 50
			steps: 1
			bevelSegments: 0 # I do not want a bevel
			bevelEnabled: yes # but it doesn't work with bevel disabled
		)
		
		@mesh = new T.Mesh(geometry, material)
		
		###@mesh = new P.ConvexMesh(geometry, material, 1)###
		
		@mesh.scale.x = 0.4
		@mesh.scale.y = 0.4
		@mesh.scale.z = 0.5
		
		@mesh.position.y = 15
		
		@mesh.receiveShadow = yes
		
		@mesh.die = @
		scene.add @mesh
		dice_meshes.push @mesh
		dice.push @
		
		@lifted = no
		@lifted_lag = 0
	
	roll: (n)-> # omg it's totally rigged
		# (fairly by the server)
		
	lift: ->
		@lifted = yes
	
	update: ->
		slowness = 10
		@lifted_lag += (@lifted - @lifted_lag) / slowness
		

