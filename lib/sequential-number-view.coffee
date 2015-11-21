{Emitter} = require "event-kit"
TemplateHelper = require "./template-helper"

modalTemplate = """
<atom-text-editor placeholder-text="example) 0001 + 2" mini></atom-text-editor>
"""

module.exports =
class SequentialNumberView extends Emitter
  constructor: (serializedState) ->
    super()

    @modalTemplate = TemplateHelper.create modalTemplate

    @element = document.createElement "div"
    @element.classList.add "sequential-number"
    @element.appendChild TemplateHelper.render @modalTemplate

    @textEditor = @element.querySelector "atom-text-editor"
    @textEditor.addEventListener "blur", => @handleBlur()
    @textEditor.addEventListener "keyup", (e) => @handleKeyup(e)
    @modalPanel = atom.workspace.addModalPanel item: @element, visible: false

  serialize: ->

  handleBlur: ->
    @emit "blur"

  handleKeyup: (e) ->
    if e.keyCode == 13
      @emit "done", @textEditor.getModel().getText().trim()

  show: ->
    @modalPanel.show()
    @textEditor.getModel().setText ""
    @textEditor.focus()

  hide: ->
    @modalPanel.hide()

  destroy: ->
    @modalPanel.destroy()
    @element.remove()