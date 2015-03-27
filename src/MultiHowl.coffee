
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
	
	get: ->
		@howls[~~(Math.random() * @howls.length)]
	
	play: ->
		h = @get()
		h.play()
