
class @Team
	teams = []
	
	constructor: (@id, @facing)->
		@pieces = []
		@color = switch @id
			when 1 then 0xFF5D5E
			when 2 then 0x432FFF
			else 0xF0F0F0
		@side_yi = switch @facing
			when +1 then 0
			when -1 then board.tiles_y - 1
		teams.push @
	
	@get: (id)->
		for team in teams
			return team if team.id is id

