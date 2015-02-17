
TAU = Math.PI + Math.PI # or C/r
T = THREE
P = Physijs
V2 = T.Vector2
V3 = T.Vector3

choose = (args...)->
	arr = if args.length > 1 then args else args[0]
	arr[~~(Math.random()*arr.length)]

###################################

my_team = -1
my_team_pieces = []
it_is_your_turn = false
you_got_kicked_bro = false
op_disconnected = false

###################################

tiles_x = 10
tiles_y = 14

board_thickness = 4
board_extension = 5
tile_length = 10
tile_spacing = 0
tile_thickness = 0.9

spaced_tile_length = tile_length + tile_spacing
board_width = spaced_tile_length * tiles_x
board_height = spaced_tile_length * tiles_y

get_tile_x = (xi)-> (xi+.5) * spaced_tile_length - board_width/2
get_tile_y = (yi)-> (yi+.5) * spaced_tile_length - board_height/2

###################################

# relative to this file
P.scripts.worker = './lib/physijs_worker.js'
# relative to the above worker file
P.scripts.ammo = './ammo.js'


# SCENE
scene = new P.Scene(fixedTimeStep: 1/30)
scene.setGravity(new V3(0, -300, 0))

# CAMERA
WIDTH = window.innerWidth
HEIGHT = window.innerHeight
ASPECT = WIDTH / HEIGHT
FOV = 45
NEAR = 0.1
FAR = 20000
camera = new T.PerspectiveCamera(FOV, ASPECT, NEAR, FAR)
scene.add(camera)
camera.position.set(150, 550, 400)
camera.lookAt(scene.position)

# RENDERER
renderer = 
	if Detector.webgl
		new T.WebGLRenderer(antialias: yes)
	else
		new T.CanvasRenderer()

renderer.setSize(WIDTH, HEIGHT)
renderer.setClearColor(0x0f0f0f)
document.body.appendChild(renderer.domElement)

window.onresize = ->
	WIDTH = window.innerWidth
	HEIGHT = window.innerHeight
	ASPECT = WIDTH / HEIGHT
	
	renderer.setSize(WIDTH, HEIGHT)
	camera.aspect = ASPECT
	camera.updateProjectionMatrix()


# CONTROLS
controls = new T.OrbitControls(camera, renderer.domElement)

# LIGHTING
light = new T.PointLight(0xffffff, 1, 10000)
light.position.set(0, 100, 0)
scene.add light

#alight = new T.AmbientLight(0x222222)
#scene.add alight

# SKYBOX/FOG
#skyBoxGeometry = new T.BoxGeometry(10000, 10000, 10000)
#skyBoxMaterial = new T.MeshBasicMaterial(color: 0xaabDf0, side: T.BackSide)
#skyBox = new T.Mesh(skyBoxGeometry, skyBoxMaterial)
#scene.add skyBox


###################################

class Board
	
	constructor: ->
		base_material = P.createMaterial(
			new T.MeshPhongMaterial(color: 0x77544A)
			0.8 # high friction
			0.3 # low restitution
		)

		@base_mesh = new P.BoxMesh(
			new T.BoxGeometry(board_width+board_extension, board_thickness, board_height+board_extension)
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
		
		@all_tile_meshes = []
		
		for xi in [0...tiles_x]
			for yi in [0...tiles_y]
				
				tile_mesh = new P.BoxMesh(
					new T.BoxGeometry(tile_length, board_thickness, tile_length)
					(if ((xi+yi)%2) is 0 then tile_material_1 else tile_material_2)
					0 # mass, 0 = static
				)
				tile_mesh.position.set(
					get_tile_x xi
					tile_thickness
					get_tile_y yi
				)
				tile_mesh.receiveShadow = true
				
				scene.add tile_mesh
				
				@all_tile_meshes.push tile_mesh
				


all_piece_meshes = []
class Piece
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
		
		extrudeSettings =
			amount: 2
			steps: 1
			#material: 1
			#extrudeMaterial: 0
			bevelEnabled: yes
			bevelThickness: 1
			bevelSize: 4
			bevelSegments: 4
		
		geometry = new T.ExtrudeGeometry(shape, extrudeSettings)
		
		@mesh = new T.Mesh(geometry, material)
		
		###@mesh = new P.ConvexMesh(geometry, material, 1)###

		@mesh.receiveShadow = true
		
		@mesh.piece = @
		
		scene.add @mesh
		all_piece_meshes.push @mesh
	
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
		if it_is_your_turn and not space_occupied(xi, yi)
			
			if socket?
				socket.emit 'position', {pi: pieces.indexOf(@), xi, yi, fx, fy}
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
			get_tile_x @xi_lag
			5
			get_tile_y @yi_lag
		)
		rotation = Math.atan2(@fy_lag, @fx_lag)
		@mesh.rotation.set(
			TAU/4
			0
			rotation - TAU/4
		)
		@


###################################
# INTERACTION
###################################

unprojector = new T.Projector()
mouse = {x: 0, y: 0}

document.body.onmousemove = (e)->
	e.preventDefault()
	
	mouse.x = (e.offsetX / WIDTH) * 2 - 1
	mouse.y = (e.offsetY / HEIGHT) * -2 + 1
	
	vector = new V3(mouse.x, mouse.y, 1)
	unprojector.unprojectVector(vector, camera)
	ray = new T.Raycaster(camera.position, vector.sub(camera.position).normalize())
	
	intersects = ray.intersectObjects(all_piece_meshes)
	
	if mouse.intersect
		mat = mouse.intersect.object.material
		mat.emissive.setHex(mouse.oeh)
		mat.needsUpdate = true
		
		document.body.style.cursor = "default"
	
	mouse.intersect = intersect = intersects[0]
	
	if mouse.intersect and it_is_your_turn
		mat = mouse.intersect.object.material
		mouse.oeh = mat.emissive.getHex()
		mat.emissive.setHex(0x0f0f0f)
		mat.needsUpdate = true
		
		document.body.style.cursor = "pointer"


document.body.onmousedown = (e)->
	if it_is_your_turn and mouse.intersect
		e.preventDefault()
		e.stopPropagation()
		
		o = mouse.intersect.object
		#force = mouse.intersect.point.sub(o.position)
		#force.multiplyScalar(-30)
		#o.setLinearVelocity(force)
		
		p = o.piece
		if p.team is my_team
			if msg.is /other team/i then msg ""
			if p.team is 2
				unless space_occupied(p.xi, p.yi-1)
					p.move(p.xi, p.yi-1, choose(-1, 0, +1), -1)
			else
				unless space_occupied(p.xi, p.yi+1)
					p.move(p.xi, p.yi+1, choose(-1, 0, +1), +1)
		else
			msg "You're the other team.", if io? then "" else "(Yes, I know it's silly since there isn't another player.)"

document.body.ontouchstart = (e)->
	document.body.onmousemove(e)
	document.body.onmousedown(e)

###################################

overlay = document.createElement 'div'
document.body.appendChild overlay
overlay.id = "overlay"

overlay_text = document.createElement 'h2'
overlay.appendChild overlay_text

overlay_subtext = document.createElement 'p'
overlay.appendChild overlay_subtext

msg = (text, subtext)->
	overlay_text.innerHTML = text ? ""
	overlay_subtext.innerHTML = subtext ? ""

msg.is = (text)->
	overlay_text.innerHTML.match text

#=========#
#   ...   #
#=========#

board = new Board

team_1_pieces = []
team_2_pieces = []
for xi in [0...tiles_x]
	team_1_pieces.push new Piece(1).position(xi, 0, 0, 1)
	team_2_pieces.push new Piece(2).position(xi, tiles_y-1, 0, -1)
pieces = team_1_pieces.concat team_2_pieces


space_occupied = (xi, yi)->
	if xi < 0 or yi < 0 or xi >= tiles_x or yi >= tiles_y
		return yes # out of bounds
	
	well_is_it = no
	
	for p in pieces
		if p.xi is xi and p.yi is yi
			well_is_it = yes
	
	well_is_it

assign_team = (team)->
	my_team = team
	my_team_pieces = switch my_team
		when 1 then team_1_pieces
		when 2 then team_2_pieces
	
	camera.position.set(0, 100, 200 * [0,-1,+1][my_team])
	camera.lookAt(scene.position)

random_space = ->
	xi: ~~(Math.random() * tiles_x)
	yi: ~~(Math.random() * tiles_y)
	
random_free_space = ->
	loop
		{xi, yi} = random_space()
		return {xi, yi} unless space_occupied(xi, yi)

if io?
	socket = io.connect location.origin
	msg 'Connecting...'

	socket.on 'position', ({pi, xi, yi, fx, fy})->
		pieces[pi].position(xi, yi, fx, fy)

	socket.on 'other-turn', ->
		it_is_your_turn = false
		
		unless op_disconnected
			msg 'Other player\'s turn...'

	socket.on 'your-turn', ->
		unless op_disconnected
			msg 'Your turn...'
		
		it_is_your_turn = true
		
		# http://localhost:8080/#I_AM_AN_INSANE_ROUGE_AI
		if location.hash.match /ai/i
			setTimeout ->
				p = choose(my_team_pieces)
				{xi, yi} = random_free_space()
				facing_x = choose(-1, +1)
				facing_y = choose(-1, +1)
				
				p.move(xi, yi, facing_x, facing_y)
			, 500

	socket.on 'you-join', (team)->
		assign_team(team)
		msg 'Waiting for other player...'

	socket.on 'other-disconnected', ->
		msg 'Other player disconnected!'
		op_disconnected = true

	socket.on 'room-already-full', ->
		msg 'There are already two players.', 'Or there were. The server currently only handles one game and two connections, ever.'
		you_got_kicked_bro = true

	socket.on 'disconnect', ->
		unless you_got_kicked_bro
			msg 'You got disconnected!', 'This could be a problem with the server or your internet connection.'
 
else
	msg "There's no game server here", "(but you can see the 3d stuff hopefully)"
	# so you can still interact with some pieces...
	assign_team(choose(1, 2))
	it_is_your_turn = true


#=========#
# ...GO!  #
#=========#

do animate = ->
	requestAnimationFrame(animate)
	#scene.simulate(undefined, 1)
	renderer.render(scene, camera)
	controls.update()
	p.update() for p in pieces
