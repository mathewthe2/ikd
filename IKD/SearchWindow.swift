import Cocoa

final class SearchWindow: NSWindow {

    var hasResults = false

    private weak var searchEditor: NSTextView?
    private var savedCaretColor: NSColor?
    private var caretIsHidden = false

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    // MARK: - Keyboard Handling

    override func sendEvent(_ event: NSEvent) {

        guard event.type == .keyDown else {
            super.sendEvent(event)
            return
        }

        // LEFT / RIGHT
        //
        // Restore the caret and allow the text field
        // to handle the cursor movement normally.

        if event.keyCode == 123 ||
           event.keyCode == 124 {

            showCaret()

            super.sendEvent(event)

            return
        }

        // Everything else goes through normally.

        showCaret()

        super.sendEvent(event)

        // After normal typing, hide the caret if
        // there is text in the search field.

        updateSearchEditor()

        guard let editor = searchEditor else {
            return
        }

        if editor.string.isEmpty {
            showCaret()
        } else {
            hideCaret()
        }
    }

    // MARK: - Find Field Editor

    private func updateSearchEditor() {

        guard let editor = firstResponder as? NSTextView else {
            return
        }

        searchEditor = editor
    }

    // MARK: - Caret

    func hideCaret() {

        updateSearchEditor()

        guard let editor = searchEditor else {
            return
        }

        if !caretIsHidden {

            savedCaretColor =
                editor.insertionPointColor

            caretIsHidden = true
        }

        editor.insertionPointColor = .clear

        editor.needsDisplay = true
    }

    func showCaret() {

        updateSearchEditor()

        guard let editor = searchEditor else {
            return
        }

        if let savedCaretColor {

            editor.insertionPointColor =
                savedCaretColor

        } else {

            editor.insertionPointColor =
                .controlAccentColor
        }

        savedCaretColor = nil
        caretIsHidden = false

        editor.needsDisplay = true
    }

    func restoreSearchCaret() {
        showCaret()
    }
}
