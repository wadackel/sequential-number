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
    matches = "#{input}".match /^([+\-]?[\da-fA-F]+(?:\.\d+)?)\s*([+\-]|(?:\+\+|\-\-))?\s*(\d+)?\s*(?:\:\s*(\d+))?\s*(?:\:\s*(\d+))?$/
    return null if matches == null

    radix = if matches[5] != undefined then parseInt matches[5], 10 else 10

    start = parseInt matches[1], radix
    operator = matches[2] || "+"
    step = parseInt matches[3], 10
    step = if isNaN matches[3] then 1 else step

    _digit = parseInt matches[4], 10
    digit = if "#{start}" == matches[1] then 0 else matches[1].length
    digit = if /^[+\-]/.test matches[1] then Math.max(digit - 1, 0) else digit
    digit = if isNaN _digit then digit else _digit

    return {start, digit, operator, step, radix, input}

  calculateValue: (index, {start, digit, operator, step, radix, input}) ->
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

  zeroPadding: (number, digit = 0, radix = 10) ->
    num = number.toString radix
    numAbs = num.replace "-", ""
    positive = num.indexOf("-") < 0
    _digit = Math.max numAbs.length, digit
    return (if positive then "" else "-") + (Array(_digit).join("0") + numAbs).slice(_digit * -1)
