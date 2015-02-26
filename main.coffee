
# SCENE
@scene = new P.Scene(fixedTimeStep: 1/30)
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
controls = new T.TrackballControls(camera, renderer.domElement)

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

my_team = null
it_is_your_turn = false
you_got_kicked_bro = false
op_disconnected = false

###################################
# INTERACTION
###################################

unprojector = new T.Projector()
mouse = x: 0, y: 0

document.body.onmousemove = (e)->
	e.preventDefault()
	
	mouse.x = (e.offsetX / WIDTH) * 2 - 1
	mouse.y = (e.offsetY / HEIGHT) * -2 + 1
	
	vector = new V3(mouse.x, mouse.y, 1)
	unprojector.unprojectVector(vector, camera)
	ray = new T.Raycaster(camera.position, vector.sub(camera.position).normalize())
	
	intersects = ray.intersectObjects(piece_meshes)
	
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
	document.body.onmousemove(e)
	if it_is_your_turn and mouse.intersect
		e.preventDefault()
		e.stopPropagation()
		
		o = mouse.intersect.object
		#force = mouse.intersect.point.sub(o.position)
		#force.multiplyScalar(-30)
		#o.setLinearVelocity(force)
		
		p = o.piece
		if p.team is my_team
			msg "" if msg.is /other team/i
			p.move(p.xi, p.yi+p.team.facing, choose(-1, 0, +1), p.team.facing)
		else
			msg "You're the other team.", if io? then "" else "(Yes, I know it's silly since there isn't another player.)"

document.body.ontouchstart = (e)->
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

@board = new Board

@team_blue = new Team 1, +1
@team_red = new Team 2, -1

for xi in [0...board.tiles_x]
	new Piece(team_blue).position(xi, team_blue.side_yi, 0, team_blue.facing)
	new Piece(team_red).position(xi, team_red.side_yi, 0, team_red.facing)


assign_team = (team)->
	my_team = Team.get team
	camera.position.set(0, 100, -200 * my_team.facing)
	camera.lookAt(scene.position)

random_space = ->
	xi: ~~(Math.random() * board.tiles_x)
	yi: ~~(Math.random() * board.tiles_y)
	
random_free_space = ->
	loop
		{xi, yi} = random_space()
		return {xi, yi} if space_free(xi, yi)

if io?
	@socket = io.connect location.origin
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
				p = choose(my_team.pieces)
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
