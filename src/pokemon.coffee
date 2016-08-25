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

padleft = require 'lodash.padstart'
Fuzzy = require 'fuzzyset.js'
Pokemon = require 'joemon'
pokemon = new Pokemon()

module.exports = (robot) =>
	moveNames = pokeNames = []
	moveFuzzy = pokeFuzzy = {}
	namesReady = movesReady = false
	pokeDict = {}
	pokemon.getPokedex 1, (status, body) ->
		pokeNames.push pkmn.pokemon_species.name for pkmn in body.pokemon_entries
		pokeDict[pkmn.pokemon_species.name] = pkmn.entry_number for pkmn in body.pokemon_entries
		pokeFuzzy = new Fuzzy(pokeNames)
		namesReady = true
	pokemon.getMoves 9999, (status, body) ->
		moveNames.push move.name.replace('-',' ') for move in body.results
		moveFuzzy = new Fuzzy(moveNames)
		movesReady = true

	getPokemonByName = (name) ->
		if name not in pokeNames
			fuzzyMatchNames = pokeFuzzy.get(name)
			if fuzzyMatchNames and fuzzyMatchNames.length > 0
				match = fuzzyMatchNames[0][1]
				{match: 'fuzzy', name: match}
			else
				{match: 'none', name:''}
		else
			{match: 'exact', name: name}

	getMoveByName = (name) ->
		if name not in moveNames
			fuzzyMatchMoves = moveFuzzy.get(name)
			if fuzzyMatchMoves and fuzzyMatchMoves.length > 0
				match = fuzzyMatchMoves[0][1]
				{match: 'fuzzy', name: match}
			else
				{match: 'none', name: ''}
		else
			{match: 'exact', name: name}

	String::capitalize = () ->
		@[0].toUpperCase() + @.substring(1)

	robot.respond /(?:poke)?dex sprite(?: me)? (\S+)$/im, (msg) ->
		if namesReady and movesReady
			{match, name} = getPokemonByName(msg.match[1])
			if match is 'none'
				msg.reply "I'm not sure what Pokémon you're looking for!"
			else
				if match is 'fuzzy'
					msg.reply "I'm assuming you mean #{name}, right?"
				pokemon.getPokemon name, (status, body) ->
					if body.sprites.front_default
						msg.send body.sprites.front_default
					else
						msg.reply "Sorry, I can't find a sprite for #{name}."
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
	###
	robot.respond /(?:poke)?dex art(?: me)? (\S+)$/im, (msg) ->
		thePoke = getPokemonByName msg.match[1]
		if namesReady
			{match, name} = getPokemonByName(msg.match[1])
			if match is 'none'
				msg.reply "I'm not sure what Pokémon you're looking for!"
			else
				if match is 'fuzzy'
					msg.reply "I'm assuming you mean #{name}, right?"
				uri = 'https://assets.pokemon.com/assets/cms2/img/pokedex/detail/'
				pokeID = padleft pokeDict[name], 3, '0'
				msg.reply "#{uri}#{pokeID}.png"
	###
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
