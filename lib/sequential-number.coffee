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
        cursors = editor.cursors.slice()
        cursors = cursors.map (cursor) -> cursor.getBufferPosition()
        cursors = cursors.sort (a, b) -> a.row - b.row || a.column - b.column

        for point, index in cursors
          editor.setTextInBufferRange new Range(point, point), @calculateValue index, result
      )

    @close()

  getEditor: ->
    atom.workspace.getActivePane().activeItem

  parseValue: (input) ->
    matches = "#{input}".match /^([+\-]?\d+(?:\.\d+)?)\s*([+\-]|(?:\+\+|\-\-))?\s*(\d+)?\s*(?:\:\s*(\d+))?$/
    return null if matches == null

    start = parseInt matches[1], 10
    operator = matches[2] || "+"
    step = parseInt matches[3], 10
    step = if isNaN matches[3] then 1 else step
    _digit = parseInt matches[4], 10
    digit = if "#{start}" == matches[1] then 0 else matches[1].length
    digit = if /^[+\-]/.test matches[1] then Math.max(digit - 1, 0) else digit
    digit = if isNaN _digit then digit else _digit

    return {start, digit, operator, step, input}

  calculateValue: (index, {start, digit, operator, step}) ->
    switch operator
      when "++" then value = start + index
      when "--" then value = start - index
      when "+" then value = start + (index * step)
      when "-" then value = start - (index * step)
      else return ""
    return if isNaN value then "" else @zeroPadding value, digit

  zeroPadding: (number, digit = 0) ->
    positive = parseInt(number, 10) >= 0
    num = Math.abs number
    _digit = Math.max "#{num}".length, digit
    return (if positive then "" else "-") + (Array(_digit).join("0") + num).slice -_digit