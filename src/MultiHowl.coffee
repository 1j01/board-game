
class @MultiHowl
	@globalPrefix: "sound/"
	@globalPostfix: ".ogg"
	
	constructor: (prefix, parts, postfix="")->
		@howls =
			for part in parts
				url =
					MultiHowl.globalPrefix +
					prefix +
					part +
					postfix +
					MultiHowl.globalPostfix
				new Howl
					urls: [url]
		@antiRepeats = []
	
	play: ->
		choose(@howls).play()
