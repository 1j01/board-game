
express = require 'express'
http = require 'http'
socket_io = require 'socket.io'

PORT = process.env.OPENSHIFT_NODEJS_PORT ? process.env.PORT ? 8080
IP = process.env.OPENSHIFT_NODEJS_IP ? process.env.IP ? '127.0.0.1'

app = express()
server = app.listen(PORT, IP)
console.log "Server listening on http://#{IP}:#{PORT}/"

io = socket_io.listen(server, {'log level': 2})

app.use express.static(__dirname)


class Board
	tiles_x: 10
	tiles_y: 14


class Piece
	@pieces = []
	constructor: (@team)-> Piece.pieces.push @
	position: (@xi, @yi, @fx, @fy)-> @

board = new Board

team_1_pieces = []
team_2_pieces = []
for xi in [0...board.tiles_x]
	team_1_pieces.push new Piece(1).position(xi, 0, 0, 1)
	team_2_pieces.push new Piece(2).position(xi, board.tiles_y-1, 0, -1)

players = []
game = off # wait for it...

io.sockets.on 'connection', (socket)->
	
	if players.length >= 2 # room already full
		socket.emit 'room-already-full'
		socket.disconnect()
		return
	
	players.push player = {socket}
	player.team = players.length
	
	socket.emit 'you-join', player.team
	socket.broadcast.emit 'other-join', player.team

	socket.on 'position', ({pi, xi, yi, fx, fy})->
		Piece.pieces[pi].position(xi, yi, fx, fy)
		socket.broadcast.emit 'position', {pi, xi, yi, fx, fy}

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
		
		game = on # YEAH
			
