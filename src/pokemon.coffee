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
#   hubot (poke)dex art (me) Pikachu = grabs a direct link to the official art of the given pokemon
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

String::capitalize = () ->
  @[0].toUpperCase() + @.substring(1)

module.exports = (robot) ->

  robot.respond /(?:poke)?dex sprite(?: me)? (\w+)$/im, (msg) ->
    preURI = "http://pokeapi.co"
    thePoke = getPokemonByName msg.match[1]
    spriteID = thePoke.sprites[0].resource_uri.split('/')[4]
    img = pokemon.getSprite spriteID
    msg.reply "#{preURI}#{img.body.image}"
    
  robot.respond /(?:poke)?dex(?: me)? (\w+)$/im, (msg) ->
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

  robot.respond /(?:poke)?dex art(?: me)? (\w+)$/im, (msg) ->
    thePoke = getPokemonByName msg.match[1]
    robot.http("http://bulbapedia.bulbagarden.net/wiki/#{thePoke.name}")
      .get() (err, res, body) ->
        if err or res.statusCode isnt 200
         return "It's broke."
        $ = cheerio.load(body)
        img = $("a[title=\"#{thePoke.name}\"].image img")
        result = []
        if not img.attr('srcset')
          result.push img.attr('src')
        else  
          if img.length is 1
            result.push(img.attr('srcset').split(', ')[1].split(' ')[0])
          else
            result.push(item.attribs.srcset.split(', ')[1].split(' ')[0]) for item in img
        msg.reply "Here's #{thePoke.name}: #{result.join ', '}"
