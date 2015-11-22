SequentialNumber = require "../lib/sequential-number"

describe "SequentialNumber", ->
  [workspaceElement, pane, element, panel] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = null

    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.workspace.open "test.txt"

    runs ->
      activationPromise = atom.packages.activatePackage "sequential-number"
      pane = atom.workspace.getActivePaneItem()
      pane.setText Array(5).join "\n"
      pane.setCursorBufferPosition [0, 0]
      atom.commands.dispatch workspaceElement, "sequential-number:open"

    waitsForPromise ->
      activationPromise

    runs ->
      element = workspaceElement.querySelector ".sequential-number"
      panel = atom.workspace.panelForItem(element)

  describe "when the sequential-number:open event is triggered", ->
    it "show the modal panel", ->
      expect(panel.isVisible()).toBe true

    it "hide the modal panel", ->
      atom.commands.dispatch element, "sequential-number:close"
      expect(panel.isVisible()).toBe false

    it "clears the previous editor text", ->
      model = panel.getItem().querySelector("atom-text-editor").getModel()
      model.setText "Sequential Number!!"
      expect(model.getText()).toBe "Sequential Number!!"

      atom.commands.dispatch element, "sequential-number:close"
      atom.commands.dispatch element, "sequential-number:open"
      expect(model.getText()).toBe ""

  describe "when the text is entered", ->
    [editor, simulator, model, previousText] = []

    beforeEach ->
      pane.addCursorAtScreenPosition [1, 0]
      pane.addCursorAtScreenPosition [2, 0]
      pane.addCursorAtScreenPosition [3, 0]
      pane.addCursorAtScreenPosition [4, 0]
      pane.addCursorAtScreenPosition [5, 0]
      _panelItem = panel.getItem()
      editor = _panelItem.querySelector "atom-text-editor"
      simulator = _panelItem.querySelector "#sequential-number-simulator"
      model = editor.getModel()
      previousText = pane.getText()

    modelTextToEnter = (text) ->
      model.setText(text)

      # Simulate the Right key
      keyupEventRight = document.createEvent "HTMLEvents"
      keyupEventRight.initEvent "keyup", true, true
      keyupEventRight.keyCode = 39
      editor.dispatchEvent keyupEventRight

      simulate = simulator.textContent

      # Simulate the Enter key
      keyupEventEnter = document.createEvent "HTMLEvents"
      keyupEventEnter.initEvent "keyup", true, true
      keyupEventEnter.keyCode = 13
      editor.dispatchEvent keyupEventEnter

      return {
        text: pane.getText()
        simulate
      }

    expectModelUndoToOriginal = ->
      pane.undo()
      expect(pane.getText()).toBe previousText

    it "does not change if the invalid value", ->
      {text, simulate} = modelTextToEnter ""
      expect(text).toBe previousText
      expect(simulate).toBe ""

      {text, simulate} = modelTextToEnter "--0011"
      expect(text).toBe previousText
      expect(simulate).toBe ""

      {text, simulate} = modelTextToEnter "++1"
      expect(text).toBe previousText
      expect(simulate).toBe ""

      {text, simulate} = modelTextToEnter "+1/"
      expect(text).toBe previousText
      expect(simulate).toBe ""

      {text, simulate} = modelTextToEnter "1%1"
      expect(text).toBe previousText
      expect(simulate).toBe ""

      {text, simulate} = modelTextToEnter "-2+++"
      expect(text).toBe previousText
      expect(simulate).toBe ""

      {text, simulate} = modelTextToEnter "+34hoge"
      expect(text).toBe previousText
      expect(simulate).toBe ""

      {text, simulate} = modelTextToEnter "alphabet"
      expect(text).toBe previousText
      expect(simulate).toBe ""

    describe "addition", ->
      it "syntax of the '0'", ->
        {text, simulate} = modelTextToEnter "0"
        expect(text).toBe """
        0
        1
        2
        3
        4
        """
        expect(simulate).toBe "0, 1, 2, ..."
        expectModelUndoToOriginal()

      it "syntax of the '1'", ->
        {text, simulate} = modelTextToEnter "1"
        expect(text).toBe """
        1
        2
        3
        4
        5
        """
        expect(simulate).toBe "1, 2, 3, ..."
        expectModelUndoToOriginal()

      it "syntax of the '1 + 2'", ->
        {text, simulate} = modelTextToEnter "1 + 2"
        expect(text).toBe """
        1
        3
        5
        7
        9
        """
        expect(simulate).toBe "1, 3, 5, ..."
        expectModelUndoToOriginal()

      it "syntax of the '5++'", ->
        {text, simulate} = modelTextToEnter "5++"
        expect(text).toBe """
        5
        6
        7
        8
        9
        """
        expect(simulate).toBe "5, 6, 7, ..."
        expectModelUndoToOriginal()

      it "syntax of the '015 + 1'", ->
        {text, simulate} = modelTextToEnter "015 + 1"
        expect(text).toBe """
        015
        016
        017
        018
        019
        """
        expect(simulate).toBe "015, 016, 017, ..."
        expectModelUndoToOriginal()

      it "syntax of the '09 + 65'", ->
        {text, simulate} = modelTextToEnter "09 + 65"
        expect(text).toBe """
        09
        74
        139
        204
        269
        """
        expect(simulate).toBe "09, 74, 139, ..."
        expectModelUndoToOriginal()

      it "syntax of the '-20+12'", ->
        {text, simulate} = modelTextToEnter "-20+12"
        expect(text).toBe """
        -20
        -8
        4
        16
        28
        """
        expect(simulate).toBe "-20, -8, 4, ..."
        expectModelUndoToOriginal()

      it "syntax of the '-10 + 1 : 2'", ->
        {text, simulate} = modelTextToEnter "-10 + 1 : 2"
        expect(text).toBe """
        -10
        -09
        -08
        -07
        -06
        """
        expect(simulate).toBe "-10, -09, -08, ..."
        expectModelUndoToOriginal()

      it "syntax of the '-9 + 1000'", ->
        {text, simulate} = modelTextToEnter "-9 + 1000 : 3"
        expect(text).toBe """
        -009
        991
        1991
        2991
        3991
        """
        expect(simulate).toBe "-009, 991, 1991, ..."
        expectModelUndoToOriginal()

    describe "subtraction", ->
      it "syntax of the '10 - 3'", ->
        {text, simulate} = modelTextToEnter "10 - 3"
        expect(text).toBe """
        10
        7
        4
        1
        -2
        """
        expect(simulate).toBe "10, 7, 4, ..."
        expectModelUndoToOriginal()

      it "syntax of the '15--'", ->
        {text, simulate} = modelTextToEnter "15--"
        expect(text).toBe """
        15
        14
        13
        12
        11
        """
        expect(simulate).toBe "15, 14, 13, ..."
        expectModelUndoToOriginal()

      it "syntax of the '0020 - 2'", ->
        {text, simulate} = modelTextToEnter "0020 - 2"
        expect(text).toBe """
        0020
        0018
        0016
        0014
        0012
        """
        expect(simulate).toBe "0020, 0018, 0016, ..."
        expectModelUndoToOriginal()

      it "syntax of the '-003120 - 21'", ->
        {text, simulate} = modelTextToEnter "-003120 - 21"
        expect(text).toBe """
        -003120
        -003141
        -003162
        -003183
        -003204
        """
        expect(simulate).toBe "-003120, -003141, -003162, ..."
        expectModelUndoToOriginal()

      it "syntax of the '-8 - 90 : 3'", ->
        {text, simulate} = modelTextToEnter "-8 - 90 : 2"
        expect(text).toBe """
        -08
        -98
        -188
        -278
        -368
        """
        expect(simulate).toBe "-08, -98, -188, ..."
        expectModelUndoToOriginal()