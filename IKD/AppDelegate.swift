import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: SearchWindow!

    private let shortcut = GlobalShortcut()

    private let compactHeight: CGFloat = 64
    private let expandedHeight: CGFloat = 420
    private let windowWidth: CGFloat = 680

    private var keyboardMonitor: Any?

    // MARK: - Application

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        createWindow()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                handleApplicationDidResignActive
            ),
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )

        installKeyboardMonitor()

        shortcut.onShortcut = { [weak self] in
            self?.toggleWindow()
        }

        shortcut.register()
    }

    // MARK: - Window Creation

    private func createWindow() {

        let contentView = ContentView(
            onResultsChanged: { [weak self] hasResults in

                guard let self else {
                    return
                }

                self.window?.hasResults = hasResults

                self.updateWindowSize(
                    hasResults: hasResults
                )
            }
        )

        window = SearchWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: windowWidth,
                height: compactHeight
            ),
            styleMask: [
                .borderless
            ],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        let hostingView = NSHostingView(rootView: contentView)

        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        window.contentView = hostingView

        window.isMovableByWindowBackground = true

        window.level = .floating

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        window.isReleasedWhenClosed = false

        window.contentView = NSHostingView(
            rootView: contentView
        )

        positionWindowInitially()

        window.orderOut(nil)
    }

    // MARK: - Keyboard Monitor

    private func installKeyboardMonitor() {

        keyboardMonitor =
            NSEvent.addLocalMonitorForEvents(
                matching: .keyDown
            ) { [weak self] event in

                guard let self else {
                    return event
                }

                guard let window = self.window else {
                    return event
                }

                // Only intercept keys when our search window
                // is the active/key window.
                guard window.isKeyWindow else {
                    return event
                }

                // Only intercept plain arrow keys.
                //
                // Command/Option/Control + arrows should
                // remain available to AppKit.

                let modifiers =
                    event.modifierFlags.intersection([
                        .command,
                        .control,
                        .option
                    ])

                guard modifiers.isEmpty else {
                    return event
                }

                // -----------------------------------------
                // UP
                // -----------------------------------------

                if event.keyCode == 126 {

                    guard window.hasResults else {
                        return event
                    }

                    window.hideCaret()

                    NotificationCenter.default.post(
                        name: .searchMoveSelectionUp,
                        object: nil
                    )

                    // Returning nil means the NSTextView
                    // never receives the arrow key.
                    return nil
                }

                // -----------------------------------------
                // DOWN
                // -----------------------------------------

                if event.keyCode == 125 {

                    guard window.hasResults else {
                        return event
                    }

                    window.hideCaret()

                    NotificationCenter.default.post(
                        name: .searchMoveSelectionDown,
                        object: nil
                    )

                    return nil
                }

                return event
            }
    }

    // MARK: - Initial Position

    private func positionWindowInitially() {

        guard let screen = NSScreen.main else {
            return
        }

        let screenFrame = screen.visibleFrame

        let x =
            screenFrame.midX
            - windowWidth / 2

        let y =
            screenFrame.maxY
            - compactHeight
            - 120

        window.setFrame(
            NSRect(
                x: x,
                y: y,
                width: windowWidth,
                height: compactHeight
            ),
            display: false
        )
    }

    // MARK: - Show / Hide

    private func toggleWindow() {

        if window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    private func showWindow() {

        NSApp.activate(ignoringOtherApps: true)

        window.makeKeyAndOrderFront(nil)

        window.restoreSearchCaret()

        window.alphaValue = 0

        NSAnimationContext.runAnimationGroup { context in

            context.duration = 0.18
            context.timingFunction =
                CAMediaTimingFunction(name: .easeOut)

            window.animator().alphaValue = 1
        }

        // SwiftUI has to finish creating the
        // NSTextField before AppKit can focus it.
        DispatchQueue.main.async { [weak self] in

            guard let self else {
                return
            }

            self.focusSearchField()
        }
    }

    private func hideWindow() {

        NSAnimationContext.runAnimationGroup(
            { context in

                context.duration = 0.12

                context.timingFunction =
                    CAMediaTimingFunction(
                        name: .easeIn
                    )

                window.animator().alphaValue = 0
            },
            completionHandler: {

                self.window.restoreSearchCaret()

                self.window.orderOut(nil)
            }
        )
    }

    // MARK: - Application Focus

    @objc private func handleApplicationDidResignActive(
        _ notification: Notification
    ) {

        guard window.isVisible else {
            return
        }

        hideWindow()
    }

    // MARK: - Window Size

    private func updateWindowSize(
        hasResults: Bool
    ) {

        let targetHeight =
            hasResults
            ? expandedHeight
            : compactHeight

        resizeWindow(
            to: targetHeight,
            animated: true
        )
    }

    private func resizeWindow(
        to height: CGFloat,
        animated: Bool
    ) {

        guard window != nil else {
            return
        }

        let currentFrame = window.frame

        let top = currentFrame.maxY

        let newY = top - height

        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: newY,
            width: currentFrame.width,
            height: height
        )

        if animated {

            NSAnimationContext.runAnimationGroup { context in

                context.duration = 0.18

                context.timingFunction =
                    CAMediaTimingFunction(
                        name: .easeInEaseOut
                    )

                window.animator().setFrame(
                    newFrame,
                    display: true
                )
            }

        } else {

            window.setFrame(
                newFrame,
                display: true
            )
        }
    }
    
    private func focusSearchField() {

        guard let contentView = window.contentView else {
            return
        }

        func findTextField(
            in view: NSView
        ) -> NSTextField? {

            if let textField = view as? NSTextField {
                return textField
            }

            for subview in view.subviews {

                if let textField = findTextField(
                    in: subview
                ) {
                    return textField
                }
            }

            return nil
        }

        if let textField = findTextField(
            in: contentView
        ) {

            window.makeFirstResponder(textField)
        }
    }

    // MARK: - Cleanup

    func applicationWillTerminate(
        _ notification: Notification
    ) {

        shortcut.unregister()

        if let keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
        }

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )
    }
}
