
express = require 'express'
http = require 'http'
socket_io = require 'socket.io'

PORT = process.env.OPENSHIFT_NODEJS_PORT ? 8080
IP = process.env.OPENSHIFT_NODEJS_IP ? '127.0.0.1'

app = express()
server = app.listen(PORT, IP)
console.log "Server listening on port #{PORT}"

io = socket_io.listen(server, {'log level': 2})

app.use express.static(__dirname)



tiles_x = 10
tiles_y = 14


class Piece
	constructor: (@team)->
	position: (@xi, @yi)-> @

team_1_pieces = []
team_2_pieces = []
for xi in [0...tiles_x]
	team_1_pieces.push new Piece(1).position(xi, 0)
	team_2_pieces.push new Piece(2).position(xi, tiles_y-1)
pieces = team_1_pieces.concat team_2_pieces

players = []
turn = 1
game = off

io.sockets.on 'connection', (socket)->
	
	if players.length >= 2 # room already full
		socket.emit 'room-already-full'
		socket.disconnect()
		return
	
	players.push player = {socket}
	player.team = players.length
	
	socket.emit 'you-join', player.team
	socket.broadcast.emit 'other-join', player.team
	
	socket.on 'position', ({pi, xi, yi})->
		#console.log 'position', {pi, xi, yi}
		pieces[pi].position(xi, yi)
		socket.broadcast.emit 'position', {pi, xi, yi}
		
		socket.emit 'other-turn'
		socket.broadcast.emit 'your-turn'
	
	socket.on 'disconnect', ->
		#players.splice players.indexOf player
		socket.broadcast.emit 'other-disconnected'
	
	if players.length >= 2 # room now full
		
		if Math.random() < 0.5
			socket.emit 'your-turn'
			socket.broadcast.emit 'other-turn'
		else
			socket.broadcast.emit 'your-turn'
			socket.emit 'other-turn'
		
		game = on
			
