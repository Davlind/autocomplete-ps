provider = require './provider'

module.exports =
  activate: ->
    provider.loadCmdlets()

  getProvider: ->
    provider
