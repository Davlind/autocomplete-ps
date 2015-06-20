spawn = require('child_process').spawn

module.exports =
  selector: '.source.powershell'
  inclusionPriority: 1
  excludeLowerPriority: true
  # id: 'autocomplete-ps-psprovider'

  getSuggestions: (request) ->
    self = this
    text = request.editor.getTextInRange([[0, 0], request.bufferPosition])
    prefix = @getPrefix(request)

    p1 = @executeCommand(text)
    p1.then((result) -> self.displaySuggestions(result, prefix))


  getPrefix: ({editor, bufferPosition}) ->
    regex = /\S+$/g
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    line.match(regex)?[0] or ''

  displaySuggestions: (suggestions, prefix) ->
    self = this
    return new Promise (resolve) ->
      completions = []

      for suggestion, i in suggestions.CompletionMatches
        if i >= 50
          completions.push({
            text: 'Too many results...',
            replacementPrefix: ''})
          break
        completions.push({
          text: suggestion.CompletionText + ' ',
          description: suggestion.ToolTip,
          replacementPrefix: prefix,
          #leftLabel: suggestion.ResultType,
          type: suggestion.ResultType,
          rightLabelHTML: self.getRightLabel(suggestion)})


      resolve(completions)

  getRightLabel: (suggestion) ->
    label = ''
    style = 'variable'

    if suggestion.ResultType is 'ParameterName'
      label = /\[(.*)\] \w+/.exec(suggestion.ToolTip)?[1] or ''
    else if suggestion.ResultType is 'Property' or suggestion.ResultType is 'Method'
      label = /^([a-zA-Z\.\[\]]+)\s+/.exec(suggestion.ToolTip)?[1] or ''

    if label.match(/^string/)
      style = 'string'
    else if label.match(/^(int|long)/)
      style = 'support constant'

    '<span class="' + style + '">' + label + '</span>'


  loadCmdlets: ->
    @initPowershell()

  initPowershell: ->
    output = ''
    try
      console.log(__dirname)
      @child = spawn(__dirname + '\\..\\completeInput.exe', [])
      @child.on 'error', (err) =>
        atom.notifications.addSuccess("CMD: Error: " + err)
        @child = null
      @child.stderr.on 'data', (data) =>
        atom.notifications.addSuccess("CMD: stderr: " + data)
      @child.on 'close', (code, signal) =>
        atom.notifications.addSuccess("CMD: close")
        @child = null
    catch err

  executeCommand: (cmd, success) ->
    @child.stdout.removeAllListeners 'data'
    self = this
    return new Promise (resolve) ->
      output = ''
      self.child.stdout.on 'data', (data) =>
        output += data
        # console.log(output)
        try
          result = JSON.parse(output) unless error?
          resolve(result)

      self.child.stdin.write(cmd + '#EOL#\n')
