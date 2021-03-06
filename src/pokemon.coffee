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
Joemon = require 'joemon'
pokemon = new Joemon()

module.exports = (robot) =>

	###
		INIT
	###

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

	###
		/INIT
	###


	###
		HELPERS
	###

	## Get pokemon or move name by fuzzy matching
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

	## Give strings a capitalize method
	String::capitalize = () ->
		@[0].toUpperCase() + @.substring(1)

	## Helper for checking that the plugin is ready and whatnot
	pre = (msg, name, type) ->
		# make sure we've grabbed and cached pokemon names and moves dicts
		if namesReady and movesReady
			# replace unicode symbold for M/F to make searching for nidoran-m/f easier
			name = name.replace('♂','m').replace('♀','f')
			if type is 'pokemon'
				{match, name} = getPokemonByName name
			else if type is 'move'
				{match, name} = getMoveByName name
			if match is 'none'
				msg.reply "I'm not sure what Pokémon you're looking for!"
				return false
			else
				if match is 'fuzzy'
					msg.send "I'm assuming you mean #{name}?"
				# put the symbols back in place of -m/f that PokeAPI uses
				return name.replace('-m','♂').replace('-f','♀')
		else
			msg.reply "Sorry, I'm still initializing the Pokédex."
	###
		/HELPERS
	###


	###
		ACTIONS
	###

	## <bot> dex sprite <pokemon> - get the sprite for this pokemon from PokeAPI
	robot.respond /(?:poke)?dex sprite(?: me)? (\S+)$/im, (msg) ->
		if name = pre(msg, msg.match[1], 'pokemon')
			pokemon.getPokemon name, (status, body) ->
				if body.sprites.front_default
					msg.send body.sprites.front_default
				else
					msg.reply "Sorry, I can't find a sprite for #{name}."


	## <bot> dex <pokemon> - return general information for a pokemon
	robot.respond /(?:poke)?dex(?: me)? (\S+)$/im, (msg) ->
		if name = pre(msg, msg.match[1], 'pokemon')
			pokemon.getPokemon name, (status, pkmn) ->
				pokemon.getSpecies name, (status, species) ->

					# pull the evolution chain ID then grab it
					evoChainId = species.evolution_chain.url.match(/(?:\/([0-9]+)\/)/)[1]
					pokemon.getEvoChain evoChainId, (status, chain) ->

						# prepare a var for our output to go all at once
						outLines = []

						# walk the evolution chain
						arr = []
						next = (chain, arr) ->
							arr.push chain.species.name.capitalize()
							if chain.evolves_to.length > 1
								bArr = []
								next(branch, bArr) for branch in chain.evolves_to
								arr.push bArr
							else
								next(chain.evolves_to[0], arr) if chain.evolves_to.length > 0
						next(chain.chain, arr)

						# grab pokemon types
						types = []
						for slot in pkmn.types
							if slot.slot is 1
								types.push slot.type.name.capitalize()
							else if slot.slot is 2
								types.push slot.type.name.capitalize()
						# build our first line of pokemon information for output
						outLines.push "##{pkmn.id}: #{pkmn.name.capitalize()} (#{types.join('/')})"

						# if the array is only 1 then it's a pokemon that doesn't evolve
						if arr.length > 1
							outLines.push "Raw evolution chain (WIP): #{JSON.stringify arr}"
						else
							outLines.push "This pokémon doesn't evolve."

						# send out our lines, don't ping the caller
						msg.send outLines.join('\n')

	## <bot> dex art <pokemon> - grabs official art for pokemon from TPCI
	robot.respond /(?:poke)?dex art(?: me)? (\S+)$/im, (msg) ->
		if name = pre(msg, msg.match[1], 'pokemon')
			uri = 'https://assets.pokemon.com/assets/cms2/img/pokedex/detail/'
			pokeID = padleft pokeDict[name], 3, '0'
			msg.send "#{uri}#{pokeID}.png"
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

	###
		/ACTIONS
	###
