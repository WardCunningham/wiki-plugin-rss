# build time tests for rss plugin
# see http://mochajs.org/

rss = require '../client/rss'
expect = require 'expect.js'

describe 'rss plugin', ->

  describe 'expand', ->

    # it 'can make itallic', ->
    #   result = rss.expand 'hello *world*'
    #   expect(result).to.be 'hello <i>world</i>'
