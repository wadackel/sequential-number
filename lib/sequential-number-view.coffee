{Emitter} = require "event-kit"
TemplateHelper = require "./template-helper"

ENABLE_ENTER_KEY_DELAY = 250

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
    @simulator = @element.querySelector "#sequential-number-simulator"
    @modalPanel = atom.workspace.addModalPanel item: @element, visible: false

    @handleBlur = @handleBlur.bind this
    @handleKeyup = @handleKeyup.bind this

  serialize: ->

  bindEvents: ->
    @isEnableEnterKey = false
    @isEnableEnterKeyTimer = setTimeout =>
      @isEnableEnterKey = true
    , ENABLE_ENTER_KEY_DELAY

    @textEditor.addEventListener "blur", @handleBlur, false
    @textEditor.addEventListener "keyup", @handleKeyup, false

  unbindEvents: ->
    @isEnableEnterKey = false
    clearTimeout @isEnableEnterKeyTimer
    @isEnableEnterKeyTimer = null

    @textEditor.removeEventListener "blur", @handleBlur, false
    @textEditor.removeEventListener "keyup", @handleKeyup, false

  handleBlur: ->
    @emit "blur"

  handleKeyup: (e) ->
    text = @getText()
    if @isEnableEnterKey && e.keyCode == 13
      @emit "done", text
    else
      @emit "change", text

  isVisible: ->
    @modalPanel.isVisible()

  show: ->
    @modalPanel.show()
    @textEditor.focus()
    @bindEvents()

  hide: ->
    @unbindEvents()
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
