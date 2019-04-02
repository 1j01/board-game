
express = require 'express'
http = require 'http'
socket_io = require 'socket.io'
{env} = process

PORT = env.OPENSHIFT_NODEJS_PORT ? env.PORT ? 8181
IP = env.OPENSHIFT_NODEJS_IP ? env.IP ? '127.0.0.1'

app = express()
server = app.listen(PORT, IP)
console.log "Server listening on http://#{IP}:#{PORT}/"

io = socket_io.listen(server, {'log level': 2})

app.use express.static("#{__dirname}/..")



players = []

io.sockets.on 'connection', (socket)->
	
	socket.on 'join', (id)->
		id ?= "#{Math.random()}"
		
		for existing_player in players
			if existing_player.id is id
				socket.broadcast.emit 'other-reconnected'
				socket.emit 'you-join', existing_player.team, id
				for other_existing_player in players when other_existing_player.id isnt id
					console.log 'other-join', other_existing_player.team, other_existing_player.id
					socket.emit 'other-join', other_existing_player.team, other_existing_player.id
				return
		
		if players.length >= 2
			socket.emit 'room-already-full'
			socket.disconnect()
			return
		
		player = {id, socket, team: players.length + 1}
		players.push player
		
		socket.emit 'you-join', player.team
		socket.broadcast.emit 'other-join', player.team
		
		socket.on 'rotation', ({pi, fx, fy})->
			socket.broadcast.emit 'position', {pi, fx, fy}
		
		socket.on 'position', ({pi, xi, yi, fx, fy})->
			socket.broadcast.emit 'position', {pi, xi, yi, fx, fy}
			
			socket.emit 'other-turn'
			socket.broadcast.emit 'your-turn'
		
		socket.on 'roll', ({di})->
			n = ~~(Math.random() * 6) + 1
			socket.emit 'roll', {di, n}
		
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

