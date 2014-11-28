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
#
# Author:
#   dualmoon

Pokemon = require 'joemon'
pokemon = new Pokemon()
Fuzzy = require 'fuzzyset.js'
pokeDex = pokemon.getPokedex()
pokeList = []
pokeList.push(item) for item in pokeDex.body.pokemon
pokeNames = []
pokeNames.push(item.name) for item in pokeDex.body.pokemon
pokeDict = []
for item in pokeList
  pokeDict[item.name] = item.resource_uri.split('/')[3]
pokeFuzzy = new Fuzzy(pokeNames)

getPokemonByName = (name) ->
  match = pokeFuzzy.get(name)[0][1]
  poke = pokemon.getPokemon(pokeDict[match]).body
  

module.exports = (robot) ->
  # Test command
  robot.respond /bulba/, (msg) ->
    response = pokemon.getPokemon(1)
    if response.status is 200
      bulba = response.body
    else
      return "Error getting pokemon."
    list = []
    list.push type.name for type in bulba.types
    msg.reply "Bulbasaur's type(s): #{list.join ', '}"

  robot.respond /poke sprite(?: me)? (\w+)$/im, (msg) ->
    msg.reply "Coming soonish."
    
  robot.respond /poke(?:mon)?(?: me)? (\w+)$/im, (msg) ->
    thePoke = getPokemonByName msg.match[1]
    # msg[1] -> balbaseur
    msg.reply "I am #{thePoke.name} and my attack is #{thePoke.attack}!"
