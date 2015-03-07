
express = require 'express'
http = require 'http'
socket_io = require 'socket.io'
{env} = process

PORT = env.OPENSHIFT_NODEJS_PORT ? env.PORT ? 8080
IP = env.OPENSHIFT_NODEJS_IP ? env.IP ? '127.0.0.1'

app = express()
server = app.listen(PORT, IP)
console.log "Server listening on http://#{IP}:#{PORT}/"

io = socket_io.listen(server, {'log level': 2})

app.use express.static("#{__dirname}/..")



players = []

io.sockets.on 'connection', (socket)->
	
	if players.length >= 2
		socket.emit 'room-already-full'
		socket.disconnect()
		return
	
	player = {socket, team: players.length + 1}
	players.push player
	
	socket.emit 'you-join', player.team
	socket.broadcast.emit 'other-join', player.team

	socket.on 'position', ({pi, xi, yi, fx, fy})->
		socket.broadcast.emit 'position', {pi, xi, yi, fx, fy}

		socket.emit 'other-turn'
		socket.broadcast.emit 'your-turn'
	
	socket.on 'disconnect', ->
		socket.broadcast.emit 'other-disconnected'
	
	if players.length >= 2
		# room now full, start the game
		if Math.random() < 0.5
			socket.emit 'your-turn'
			socket.broadcast.emit 'other-turn'
		else
			socket.broadcast.emit 'your-turn'
			socket.emit 'other-turn'

