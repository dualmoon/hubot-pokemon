chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'pokemon', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/pokemon')(@robot)

  #it 'registers a respond listener', ->
  #  expect(@robot.respond).to.have.been.calledWith(/hello/)
