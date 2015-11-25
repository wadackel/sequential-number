{Range, Point} = require "atom"
SequentialNumber = require "../lib/sequential-number"


# Event trigger utility
trigger = (el, event, type, data = {}) ->
  e = document.createEvent event
  e.initEvent type, true, true
  e = Object.assign e, data
  el.dispatchEvent e


# Package
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

    expectModelUndoToOriginal = ->
      pane.undo()
      expect(pane.getText()).toBe previousText

    expectModalTextToEnter = (input, simulateExpected, expected, undo = false) ->
      model.setText(input)

      # Simulate the Right key
      trigger editor, "HTMLEvents", "keyup", keyCode: 39
      expect(simulator.textContent).toBe simulateExpected

      # Simulate the Enter key
      trigger editor, "HTMLEvents", "keyup", keyCode: 13
      expect(pane.getText()).toBe expected

      if undo
        expectModelUndoToOriginal()

    it "does not change if the invalid value", ->
      expectModalTextToEnter "", "", previousText
      expectModalTextToEnter "--0011", "", previousText
      expectModalTextToEnter "++1", "", previousText
      expectModalTextToEnter "+1/", "", previousText
      expectModalTextToEnter "1%1", "", previousText
      expectModalTextToEnter "1*2", "", previousText
      expectModalTextToEnter "-2+++", "", previousText
      expectModalTextToEnter "+34hoge", "", previousText
      expectModalTextToEnter "alphabet", "", previousText

    describe "addition", ->
      it "syntax of the '0'", ->
        expectModalTextToEnter "0",
        "0, 1, 2, ...",
        """
        0
        1
        2
        3
        4
        """,
        true

      it "syntax of the '1'", ->
        expectModalTextToEnter "1",
        "1, 2, 3, ...",
        """
        1
        2
        3
        4
        5
        """,
        true

      it "syntax of the '1 + 2'", ->
        expectModalTextToEnter "1 + 2",
        "1, 3, 5, ...",
        """
        1
        3
        5
        7
        9
        """,
        true

      it "syntax of the '5++'", ->
        expectModalTextToEnter "5++",
        "5, 6, 7, ...",
        """
        5
        6
        7
        8
        9
        """,
        true

      it "syntax of the '015 + 1'", ->
        expectModalTextToEnter "015 + 1",
        "015, 016, 017, ...",
        """
        015
        016
        017
        018
        019
        """,
        true

      it "syntax of the '09 + 65'", ->
        expectModalTextToEnter "09 + 65",
        "09, 74, 139, ...",
        """
        09
        74
        139
        204
        269
        """,
        true

      it "syntax of the '-20+12'", ->
        expectModalTextToEnter "-20+12",
        "-20, -8, 4, ...",
        """
        -20
        -8
        4
        16
        28
        """,
        true

      it "syntax of the '-10 + 1 : 2'", ->
        expectModalTextToEnter "-10 + 1 : 2",
        "-10, -09, -08, ...",
        """
        -10
        -09
        -08
        -07
        -06
        """,
        true

      it "syntax of the '-9 + 1000'", ->
        expectModalTextToEnter "-9 + 1000 : 3",
        "-009, 991, 1991, ...",
        """
        -009
        991
        1991
        2991
        3991
        """,
        true

    describe "subtraction", ->
      it "syntax of the '10 - 3'", ->
        expectModalTextToEnter "10 - 3",
        "10, 7, 4, ...",
        """
        10
        7
        4
        1
        -2
        """,
        true

      it "syntax of the '15--'", ->
        expectModalTextToEnter "15--",
        "15, 14, 13, ...",
        """
        15
        14
        13
        12
        11
        """,
        true

      it "syntax of the '0020 - 2'", ->
        expectModalTextToEnter "0020 - 2",
        "0020, 0018, 0016, ...",
        """
        0020
        0018
        0016
        0014
        0012
        """,
        true

      it "syntax of the '-003120 - 21'", ->
        expectModalTextToEnter "-003120 - 21",
        "-003120, -003141, -003162, ...",
        """
        -003120
        -003141
        -003162
        -003183
        -003204
        """,
        true

      it "syntax of the '-8 - 90 : 3'", ->
        expectModalTextToEnter "-8 - 90 : 2",
        "-08, -98, -188, ...",
        """
        -08
        -98
        -188
        -278
        -368
        """,
        true

    describe "when the currently selected text", ->
      it "replace selected text", ->
        pane.insertText "Hello World!!"

        # Select all of the "Hello World!!"
        for cursor in pane.getCursors()
          position = cursor.getBufferPosition()
          startPoint = new Point position.row, 0
          endPoint = new Point position.row, 13
          cursor.selection.setBufferRange new Range startPoint, endPoint

        model.setText "01+1:3"

        # Simulate the Enter key
        trigger editor, "HTMLEvents", "keyup", keyCode: 13

        expect(pane.getText()).toBe """
        001
        002
        003
        004
        005
        """