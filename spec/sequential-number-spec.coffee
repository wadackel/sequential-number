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
    [editor, model, previousText] = []

    beforeEach ->
      pane.addCursorAtScreenPosition [1, 0]
      pane.addCursorAtScreenPosition [2, 0]
      pane.addCursorAtScreenPosition [3, 0]
      pane.addCursorAtScreenPosition [4, 0]
      pane.addCursorAtScreenPosition [5, 0]
      editor = panel.getItem().querySelector "atom-text-editor"
      model = editor.getModel()
      previousText = pane.getText()

    modelTextToEnter = (text) ->
      model.setText(text)
      e = document.createEvent "HTMLEvents"
      e.initEvent "keyup", true, true
      e.keyCode = 13
      editor.dispatchEvent e
      return pane.getText()

    expectModelUndoToOriginal = ->
      pane.undo()
      expect(pane.getText()).toBe previousText


    it "does not change if the invalid value", ->
      expect(modelTextToEnter("")).toBe previousText
      expect(modelTextToEnter("--0011")).toBe previousText
      expect(modelTextToEnter("++1")).toBe previousText
      expect(modelTextToEnter("+1/")).toBe previousText
      expect(modelTextToEnter("1%1")).toBe previousText
      expect(modelTextToEnter("-2+++")).toBe previousText
      expect(modelTextToEnter("+34hoge")).toBe previousText
      expect(modelTextToEnter("alphabet")).toBe previousText

    describe "addition", ->
      it "syntax of the '0'", ->
        expect(modelTextToEnter("0")).toBe """
        0
        1
        2
        3
        4
        """
        expectModelUndoToOriginal()

      it "syntax of the '1'", ->
        expect(modelTextToEnter("1")).toBe """
        1
        2
        3
        4
        5
        """
        expectModelUndoToOriginal()

      it "syntax of the '1 + 2'", ->
        expect(modelTextToEnter("1 + 2")).toBe """
        1
        3
        5
        7
        9
        """
        expectModelUndoToOriginal()

      it "syntax of the '5++'", ->
        expect(modelTextToEnter("5++")).toBe """
        5
        6
        7
        8
        9
        """
        expectModelUndoToOriginal()

      it "syntax of the '015 + 1'", ->
        expect(modelTextToEnter("015 + 1")).toBe """
        015
        016
        017
        018
        019
        """
        expectModelUndoToOriginal()

      it "syntax of the '-20+12'", ->
        expect(modelTextToEnter("-20+12")).toBe """
        -20
        -8
        4
        16
        28
        """
        expectModelUndoToOriginal()

    describe "subtraction", ->
      it "syntax of the '10 - 3'", ->
        expect(modelTextToEnter("10 - 3")).toBe """
        10
        7
        4
        1
        -2
        """
        expectModelUndoToOriginal()

      it "syntax of the '15--'", ->
        expect(modelTextToEnter("15--")).toBe """
        15
        14
        13
        12
        11
        """
        expectModelUndoToOriginal()

      it "syntax of the '0020 - 2'", ->
        expect(modelTextToEnter("0020 - 2")).toBe """
        0020
        0018
        0016
        0014
        0012
        """
        expectModelUndoToOriginal()

      it "syntax of the '-003120 - 21", ->
        expect(modelTextToEnter("-003120 - 21")).toBe """
        -003120
        -003141
        -003162
        -003183
        -003204
        """
        expectModelUndoToOriginal()

      it "syntax of the '-10 + 1 : 2", ->
        expect(modelTextToEnter("-10 + 1 : 2")).toBe """
        -10
        -09
        -08
        -07
        -06
        """
        expectModelUndoToOriginal()