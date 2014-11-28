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
pokeList = []
pokeList.push(item.name) for item in pokemon.getPokedex(1).body.pokemon
pokeList = new Fuzzy(pokeList)
pokeDict = []
for item in pokeList
  pokeDict[item.name] = item.resource_uri.split('/')[3]

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
    
  robot.respond /pokemon(?: me)? (\w+)$/im, (msg) ->
    if thePoke = pokeList.get(msg.get[1])[0][1]
      thePoke = pokemon.getPokemon pokeDict[thePoke]
      msg.respond "I am #{thePoke.name} and my attack is #{thePoke.attack}!"
