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
#   hubot (poke)dex (me) Pikachu - fuzzy pokemon name search
#   hubot (poke)dex sprite (me) Pikachu - grabs a direct link to a sprite of the give pokemon
#
# Author:
#   dualmoon

cheerio = require 'cheerio'
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

  robot.respond /(?:poke)?dex sprite(?: me)? (\w+)$/im, (msg) ->
    preURI = "http://pokeapi.co"
    thePoke = getPokemonByName msg.match[1]
    spriteID = thePoke.sprites[0].resource_uri.split('/')[4]
    img = pokemon.getSprite spriteID
    msg.reply "#{preURI}#{img.body.image}"
    
  robot.respond /(?:poke)?dex(?: me)? (\w+)$/im, (msg) ->
    thePoke = getPokemonByName msg.match[1]
    # msg[1] -> balbaseur
    msg.reply "I am #{thePoke.name} and my attack is #{thePoke.attack}!"

  robot.respond /(?:poke)?dex art(?: me)? (\w+)$/im, (msg) ->
    thePoke = getPokemonByName msg.match[1]
    robot.http("http://bulbapedia.bulbagarden.net/wiki/#{thePoke.name}")
      .get() (err, res, body) ->
        if err or res.statusCode isnt 200
         return "It's broke."
        $ = cheerio.load(body)
        img = $("a[title=\"#{thePoke.name}\"].image img")
        result = []
        if img.length is 1
          result.push(img.attr('srcset').split(', ')[1].split(' ')[0])
        else
          result.push(item.attribs.srcset.split(', ')[1].split(' ')[0]) for item in img
        msg.reply "Here's #{thePoke.name}: #{result.join ', '}"
