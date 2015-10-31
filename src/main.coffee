
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

my_team = null
it_is_your_turn = false
you_got_kicked_bro = false
op_disconnected = false

###################################
# INTERACTION
###################################

unprojector = new T.Projector()
mouse = x: 0, y: 0
holding = null
phase = "rotation"

unhover = ->
	console.log "unhover", mouse.pointed
	if mouse.pointed
		mat = mouse.pointed.material
		if mat.original
			mat.emissive.setHex(mat.original.emissive)
			mat.color.setHex(mat.original.color)
		mat.needsUpdate = true
		# mouse.pointed = null
	document.body.style.cursor = "default"

hover = (object, fn)->
	mat = object.material
	mat.original =
		emissive: mat.emissive.getHex()
		color: mat.color.getHex()
	document.body.style.cursor = "pointer"
	fn mat
	mat.needsUpdate = true

document.body.onmousemove = (e)->
	e.preventDefault()
	
	mouse.x = (e.offsetX / WIDTH) * 2 - 1
	mouse.y = (e.offsetY / HEIGHT) * -2 + 1
	
	vector = new V3(mouse.x, mouse.y, 1)
	unprojector.unprojectVector(vector, camera)
	ray = new T.Raycaster(
		camera.position
		vector.sub(camera.position).normalize()
	)
	pointed = (objects)->
		unhover()
		intersects = ray.intersectObjects(objects)
		mouse.pointed = intersects[0]?.object
		console.log "pointed", mouse.pointed
	
	piece = (pointed piece_meshes)?.piece
	
	if it_is_your_turn
		if piece
			if phase is "action" or (phase is "rotation" and not holding)
				hover piece.mesh, (mat)->
					mat.emissive.setHex(0x0f0f0f)
					if piece.team isnt my_team
						document.body.style.cursor = "not-allowed"
			# else
			# 	unhover()
		else
			if holding
				if phase is "action"
					tile_mesh = pointed board.tile_meshes
					if tile_mesh
						hover tile_mesh, (mat)->
							mat.color.setHex(0x03af0f)
		
		if phase is "rotation"
			if holding
				# @TODO: cast ray to infinite plane
				tile_mesh = pointed board.tile_meshes
				if tile_mesh
					{xi, yi} = tile_mesh
					dx = xi - holding.xi
					dy = yi - holding.yi
					if dx isnt 0 or dy isnt 0 and dx isnt holding.fx and dx isnt holding.fx
						dir = Math.atan2(fy, fx)
						d4 = Math.round(dir / TAU * 4)
						dir4 = d4 / 4 * TAU
						fx = Math.cos(dir4)
						fy = Math.sin(dir4)
						holding.rotate fx, fy
			else
				_mp = mouse.pointed
				die = (pointed dice_meshes)?.die
				if die
					die.lift()
				else
					mouse.pointed = _mp


document.body.onmousedown = (e)->
	document.body.onmousemove(e)
	if it_is_your_turn
		if phase is "rotation" and holding
			holding.place()
			holding = null
		else if o = mouse.pointed
			e.preventDefault()
			e.stopPropagation()
			
			if p = o.piece
				if p.team is my_team
					msg "" if msg.is /other team/i
					# p.move(p.xi, p.yi+p.team.facing, choose(-1, 0, +1), p.team.facing)
					if p.lifted
						p.place()
						holding = null
					else
						holding?.place()
						p.lift(if phase is "rotation" then 0.2 else 1)
						holding = p
				else
					msg "You're the other team.", if io? then "" else "(Yes, I know it's silly since there isn't another player.)"
			else
				{xi, yi} = o
				holding?.place xi, yi
				holding = null
				unhover()
				mouse.pointed = null

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
	new Piece(team_blue).position(xi, team_blue.side_yi + team_blue.facing, 0, team_blue.facing)
	new Piece(team_red).position(xi, team_red.side_yi, 0, team_red.facing)
	new Piece(team_red).position(xi, team_red.side_yi + team_red.facing, 0, team_red.facing)

new Die 1
new Die 2

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
			msg 'Your turn...', 'Orient your pieces'
		
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
	assign_team(choose(1, 2))
	it_is_your_turn = true


#=========#
# ...GO!  #
#=========#

do animate = ->
	requestAnimationFrame(animate)
	renderer.render(scene, camera)
	controls.update()
	p.update() for p in pieces
