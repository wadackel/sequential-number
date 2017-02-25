{CompositeDisposable, Range} = require "atom"
SequentialNumberView = require "./sequential-number-view"

SIMULATE_CURSOR_LENGTH = 3

module.exports = SequentialNumber =
  activate: () ->
    @view = new SequentialNumberView
    @view.on "blur", => @close()
    @view.on "change", (value) => @simulate value
    @view.on "done", (value) => @exec value

    @previousFocused

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add "atom-workspace", "sequential-number:open": => @open()
    @subscriptions.add atom.commands.add "atom-workspace", "sequential-number:close": => @close()

  deactivate: ->
    @subscriptions.dispose()
    @view.destroy()

  serialize: ->

  open: ->
    if !@view.isVisible()
      @view.show()

  close: ->
    @view.hide()
    atom.views.getView(atom.workspace).focus()

  simulate: (value) ->
    result = @parseValue value
    text = ""

    if result != null
      simulateList = [0..SIMULATE_CURSOR_LENGTH - 1].map (index) =>
        @calculateValue index, result
      simulateList.push "..."
      text = simulateList.join ", "

    @view.setSimulatorText text

  exec: (value) ->
    editor = @getEditor()
    result = @parseValue value

    if result != null
      editor.transact( =>
        length = editor.cursors.length
        for index in [0...length]
          cursors = editor.cursors.slice()
          cursors = cursors.map (cursor) -> cursor.selection.getBufferRange()
          cursors = cursors.sort (a, b) -> a.start.row - b.start.row || a.start.column - b.start.column
          range = cursors[index]
          editor.setTextInBufferRange new Range(range.start, range.end), @calculateValue index, result
      )

    @close()

  getEditor: ->
    atom.workspace.getActivePane().activeItem

  parseValue: (input) ->
    matches = "#{input}".match /^([+\-]?[\da-zA-Z]+(?:\.\d+)?)\s*([+\-]|(?:\+\+|\-\-))?\s*(\d+)?\s*(?:\:\s*(\d+))?\s*(?:\:\s*([\daA]+))?$/
    return null if matches == null

    radix = matches[5]
    radix = if radix != undefined then radix else 10
    radix = if /\d+/.test radix then parseInt radix, 10 else radix
    isAlphaRadix = /[aA]/.test radix

    start = matches[1]
    return null if isAlphaRadix and /\d+/.test(start)

    start = if isAlphaRadix then start else parseInt(start, radix)

    operator = matches[2] || "+"
    step = parseInt matches[3], 10
    step = if isNaN matches[3] then 1 else step

    _digit = parseInt matches[4], 10
    digit = if "#{start}" == matches[1] then 0 else matches[1].length
    digit = if /^[+\-]/.test matches[1] then Math.max(digit - 1, 0) else digit
    digit = if isNaN _digit then digit else _digit

    return {start, digit, operator, step, radix, input}

  calculateValue: (index, args) ->
    if /[aA]/.test args.radix
      return @calculateAlphaValue index, args
    else
      return @calculateNumberValue index, args

  calculateNumberValue: (index, {start, digit, operator, step, radix, input}) ->
    _start = parseInt start, 10

    switch operator
      when "++" then value = _start + index
      when "--" then value = _start - index
      when "+" then value = _start + (index * step)
      when "-" then value = _start - (index * step)
      else return ""

    if isNaN value
      return ""

    value = @zeroPadding value, digit, radix
    firstAlpha = input.match /([a-fA-F])/

    if firstAlpha
      value = value[if firstAlpha[1] == firstAlpha[1].toLowerCase() then "toLowerCase" else "toUpperCase"]()

    return value

  calculateAlphaValue: (index, {start, digit, operator, step, radix, input}) ->
    switch operator
      when "++" then count = (index - 1) + step
      when "--" then count = (index - 1) - step
      when "+" then count = index * step
      when "-" then count = index * step * -1

    value = @alphaSequence(start.toLowerCase(), count)
    value = @leftPadding(value, digit, "a")

    if /[A-Z]/.test(start) or /[A-Z]/.test(radix)
      value = value.toUpperCase()

    return value

  alphaSequence: (str, count) ->
    return str if count == 0

    alphabet = "abcdefghijklmnopqrstuvwxyz".split ""
    last = str.slice -1
    index = alphabet.indexOf last
    n = Math.floor((index + count) / alphabet.length)
    next = alphabet[(index + count) % alphabet.length]

    return "" if !next

    s = "#{str.slice(0, str.length - 1)}#{next}"

    if n > 0
      if s.length == 1 and index == alphabet.length - 1
        s = "a#{s}"
      else
        s = "#{@alphaSequence(s.slice(0, s.length - 1), n)}#{next}"

    return s

  leftPadding: (str, digit, padString) ->
    _digit = Math.max str.length, digit
    return (Array(_digit).join(padString) + str).slice(_digit * -1)

  zeroPadding: (number, digit = 0, radix = 10) ->
    num = number.toString radix
    numAbs = num.replace "-", ""
    positive = num.indexOf("-") < 0
    return (if positive then "" else "-") + @leftPadding(numAbs, digit, "0")
