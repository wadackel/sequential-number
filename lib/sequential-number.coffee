{CompositeDisposable, Range} = require "atom"
SequentialNumberView = require "./sequential-number-view"

module.exports = SequentialNumber =
  activate: () ->
    @view = new SequentialNumberView
    @view.on "blur", => @close()
    @view.on "done", (value) => @exec(value)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add "atom-workspace", "sequential-number:open": => @open()
    @subscriptions.add atom.commands.add "atom-workspace", "sequential-number:close": => @close()

  deactivate: ->
    @subscriptions.dispose()
    @view.destroy()

  serialize: ->

  open: ->
    @view.show()

  close: ->
    @view.hide()
    atom.views.getView(atom.workspace).focus()

  exec: (value) ->
    editor = atom.workspace.getActivePane().activeItem
    result = @parseValue value
    return if result == null

    editor.transact( =>
      for cursor, index in editor.cursors
        point = cursor.getBufferPosition()
        editor.setTextInBufferRange new Range(point, point), @calculateValue index, result
    )

    @close()

  parseValue: (input) ->
    matches = "#{input}".match /^([+\-]?\d+(?:\.\d+)?)\s*([+\-]|(?:\+\+|\-\-))?\s*(\d+)?$/
    return null if matches == null

    start = parseInt matches[1], 10
    digit = if "#{start}" == matches[1] then 0 else matches[1].length
    digit = if /^[+\-]/.test matches[1] then Math.max(digit - 1, 0) else digit
    operator = matches[2] || "+"
    step = parseInt matches[3], 10
    step = if isNaN matches[3] then 1 else step

    return {start, digit, operator, step, input}

  calculateValue: (index, {start, digit, operator, step}) ->
    switch operator
      when "++" then value = start + index
      when "--" then value = start - index
      when "+" then value = start + (index * step)
      when "-" then value = start - (index * step)
      else return ""
    return if isNaN value then "" else @zeroPadding value, digit

  zeroPadding: (number, digit = 1) ->
    positive = parseInt(number, 10) >= 0
    num = Math.abs number
    return (if positive then "" else "-") + (Array(digit).join("0") + num).slice -digit