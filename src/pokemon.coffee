# Description:
#   Get pokémon info.
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

Pokémon = require 'joemon'
pokémon = new Pokémon()

module.exports = (robot) ->
  # Test command
  robot.respond /bulba/, (msg) ->
    response = pokémon.getPokemon(1)
    if response.status is 200
      bulba = response.body
    else
      return "Error getting pokemon."
    list = []
    list.push type.name for type in bulba.types
    msg.reply "Bulbasaur's type(s): #{list.join ', '}"
