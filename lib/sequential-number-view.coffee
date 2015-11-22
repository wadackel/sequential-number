{Emitter} = require "event-kit"
TemplateHelper = require "./template-helper"

modalTemplate = """
<div class="padded">
  <atom-text-editor placeholder-text="example) 01 + 2" mini></atom-text-editor>
  <div class="inset-panel">
    <div class="padded">
      <span class="icon icon-terminal"></span>
      <span id="sequential-number-simulator"></span>
    </div>
  </div>
</div>
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

    @simulator = @element.querySelector "#sequential-number-simulator"

    @modalPanel = atom.workspace.addModalPanel item: @element, visible: false

  serialize: ->

  handleBlur: ->
    @emit "blur"

  handleKeyup: (e) ->
    text = @getText()
    if e.keyCode == 13
      @emit "done", text
    else
      @emit "change", text

  isVisible: ->
    @modalPanel.isVisible()

  show: ->
    @modalPanel.show()
    @textEditor.focus()

  hide: ->
    @modalPanel.hide()
    @setText ""
    @setSimulatorText ""

  destroy: ->
    @modalPanel.destroy()
    @modalPanel = null
    @element.remove()
    @element = null

  setText: (text) ->
    @textEditor.getModel().setText text

  getText: ->
    @textEditor.getModel().getText().trim()

  setSimulatorText: (text) ->
    @simulator.textContent = text

  getSimulatorText: ->
    @simulator.textContent