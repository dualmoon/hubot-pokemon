# Description:
#   Get pokemon info.
#
# Dependencies:
#   joemon
#
# Configuration:
#   None
#
# Commands:
#   hubot (poke)dex (me) Pikachu - fuzzy pokemon name search that returns some basic pokémon info
#   hubot (poke)dex sprite (me) Pikachu - grabs a direct link to a sprite of the given pokemon
#   hubot (poke)dex art (me) Pikachu - grabs a direct link to the official art of the given pokemon
#   hubot (poke)dex moves (me) Pikachu - shows the moves that a pokemon can learn
#   hubot (poke)dex moves (me) Pikachu Tackle - shows how a pokemon learns a move, if they can
#   hubot (poke)dex move (me) Tackle - shows information about a move
#
# Author:
#   dualmoon

# This is for grabbing pokemon art from bulbapedia
cheerio = require 'cheerio'

Fuzzy = require 'fuzzyset.js'
Pokemon = require 'joemon'


module.exports = (robot) ->
	pokeNames = []
	pokeFuzzy = {}
	moveNames = []
	moveFuzzy = {}
	namesReady = false
	movesReady = false

	pokemon = new Pokemon()

	pokemon.getPokedex 1, (status, body) ->
		pokeNames.push pokemon.pokemon_species.name for pokemon in body.pokemon_entries
		pokeFuzzy = new Fuzzy(pokeNames)
		namesReady = true
	pokemon.getMoves 9999, (status, body) ->
		moveNames.push move.name.replace('-',' ') for move in body.results
		moveFuzzy = new Fuzzy(moveNames)
		movesReady = true

	getPokemonByName = (name) =>
		if name not in pokeNames
			fuzzyMatch = pokeFuzzy.get(name)
			if match.length > 0
				match = fuzzyMatch[0][1]
				{match: 'fuzzy', name: match}
			else
				{match: 'none', name:''}
		else
			{match: 'exact', name: name}

	getMoveByName = (name) =>
		if name not in moveNames
			fuzzyMatch = moveFuzzy.get(name)
			if match.length > 0
				match = fuzzyMatch[0][1]
				{match: 'fuzzy', name: match}
			else
				{match: 'none', name: ''}
		else
			{match: 'exact', name: name}

	String::capitalize = () ->
		@[0].toUpperCase() + @.substring(1)

	robot.respond /(?:poke)?dex sprite(?: me)? (\S+)$/im, (msg) =>
		if namesReady and movesReady
			{match, name} = getPokemonByName(msg.match[1])
			if match is 'none'
				msg.reply "I'm not sure what Pokémon you're looking for!"
			else
				if match is 'fuzzy'
					msg.reply "I'm assuming you mean #{name}, right?"
				pokemon.getPokemon name, (status, body) ->
					msg.send body.sprites.front_female
		else
			msg.reply "Sorry, I'm still initializing the Pokédex"
###
	robot.respond /(?:poke)?dex(?: me)? (\S+)$/im, (msg) ->
		thePoke = getPokemonByName msg.match[1]
		types = []
		types.push(item.name.capitalize()) for item in thePoke.types
		evoTxt = "I don't evolve into anything!"
		if thePoke.evolutions.length > 0
			evos = []
			evos.push("#{item.to.capitalize()} via #{if item.method is 'other' then item.detail else item.method}") for item in thePoke.evolutions
			evoTxt = "I evolve into #{evos.join ' and '}!"
			evoTxt = evoTxt.replace('_', ' ')
		msg.reply "I am #{thePoke.name}. I am a #{types.join ' and '} pokemon! #{evoTxt}"

	robot.respond /(?:poke)?dex art(?: me)? (\S+)$/im, (msg) ->
		thePoke = getPokemonByName msg.match[1]
		robot.http("http://bulbapedia.bulbagarden.net/wiki/#{thePoke.name}")
			.get() (err, res, body) ->
				if err or res.statusCode isnt 200
				 return "It's broke."
				$ = cheerio.load(body)
				img = $("a[title=\"#{thePoke.name}\"].image img")
				result = []
				if not img.attr('srcset')?
					result.push img.attr('src')
				else  
					if img.length is 1
						result.push(img.attr('srcset').split(', ')[1].split(' ')[0])
					else
						result.push(item.attribs.srcset.split(', ')[1].split(' ')[0]) for item in img
				msg.reply "Here's #{thePoke.name}: #{result.join ', '}"

	robot.respond /(?:poke)?dex moves(?: me)? (\S+)$/im, (msg) ->
		thePoke = getPokemonByName msg.match[1]
		text = "Here's the moves I can learn: "
		moves = []
		moves.push item.name for item in thePoke.moves
		msg.reply "#{text}#{moves.join ', '}"

	robot.respond /(?:poke)?dex moves(?: me)? (\S+) (\S+)$/im, (msg) ->
		thePoke = getPokemonByName msg.match[1]
		for item in thePoke.moves
			if item.name.toLowerCase() is msg.match[2].toLowerCase()
				if item.learn_type is "level up"
					msg.reply "#{thePoke.name} learns #{item.name} by gaining level #{item.level}"
				else
					msg.reply "#{thePoke.name} learns #{item.name} via #{item.learn_type}"
	robot.respond /(?:poke)?dex move(?: me)? (\S+(?: \S+)?)$/im, (msg) ->
		theMove = getMoveByName msg.match[1]
		msg.reply "#{theMove.name.replace '-', ' '}: #{theMove.description} [POW:#{theMove.power} ACC:#{theMove.accuracy} PP: #{theMove.pp}]"
###
