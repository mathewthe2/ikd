import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: SearchWindow!

    private let shortcut = GlobalShortcut()

    private let compactHeight: CGFloat = 64
    private let expandedHeight: CGFloat = 420
    private let windowWidth: CGFloat = 680

    private var keyboardMonitor: Any?
    
    private var resizeWorkItem: DispatchWorkItem?

    // MARK: - Remembered Window Position

    // Horizontal position is based on the window center.
    private var relativeWindowX: CGFloat = 0.5

    // Vertical position is based on the distance
    // between the top of the screen and the top of the window.
    //
    // This is important because the window expands downward.
    private var relativeWindowTop: CGFloat = 0.15

    // MARK: - Application

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        createWindow()

        // Hide the window when the application loses focus.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                handleApplicationDidResignActive
            ),
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )

        // Remember the window's position when it is moved.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                handleWindowDidMove
            ),
            name: NSWindow.didMoveNotification,
            object: window
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

        let hostingView = NSHostingView(
            rootView: contentView
        )

        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor =
            NSColor.clear.cgColor

        window.contentView = hostingView

        window.isMovableByWindowBackground = true

        window.level = .floating

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        window.isReleasedWhenClosed = false

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

    // MARK: - Screen Detection

    private func screenContainingMouse() -> NSScreen? {

        let mouseLocation = NSEvent.mouseLocation

        return NSScreen.screens.first {
            $0.frame.contains(mouseLocation)
        }
    }

    // MARK: - Initial Position

    private func positionWindowInitially() {

        guard let screen = screenContainingMouse() else {
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

        // Store the initial position.
        rememberWindowPosition()
    }

    // MARK: - Remember Position

    @objc private func handleWindowDidMove(
        _ notification: Notification
    ) {

        rememberWindowPosition()
    }

    private func rememberWindowPosition() {

        guard let screen = window.screen else {
            return
        }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        // Remember horizontal position using the center.
        relativeWindowX =
            (windowFrame.midX - screenFrame.minX)
            / screenFrame.width

        // Remember vertical position using the TOP edge.
        //
        // This prevents the 64 -> 420 height change from
        // changing the saved vertical position.
        relativeWindowTop =
            (screenFrame.maxY - windowFrame.maxY)
            / screenFrame.height
    }

    // MARK: - Move To Screen

    private func moveWindowToScreen(
        _ screen: NSScreen
    ) {

        let screenFrame = screen.visibleFrame

        let centerX =
            screenFrame.minX
            + relativeWindowX * screenFrame.width

        let topY =
            screenFrame.maxY
            - relativeWindowTop * screenFrame.height

        let newFrame = NSRect(
            x: centerX - window.frame.width / 2,
            y: topY - window.frame.height,
            width: window.frame.width,
            height: window.frame.height
        )

        window.setFrame(
            newFrame,
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

        // Find the monitor where the mouse currently is
        // and move the window there while preserving
        // its relative position.
        if let screen = screenContainingMouse() {
            moveWindowToScreen(screen)
        }

        NSApp.activate(
            ignoringOtherApps: true
        )

        window.makeKeyAndOrderFront(nil)

        window.restoreSearchCaret()

        window.alphaValue = 0

        NSAnimationContext.runAnimationGroup { context in

            context.duration = 0.18

            context.timingFunction =
                CAMediaTimingFunction(
                    name: .easeOut
                )

            window.animator().alphaValue = 1
        }

        // SwiftUI needs one run-loop cycle to finish
        // creating the underlying NSTextField.
        DispatchQueue.main.async { [weak self] in

            self?.focusSearchField()
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
            completionHandler: { [weak self] in

                guard let self else {
                    return
                }

                self.window.restoreSearchCaret()

                self.window.orderOut(nil)
            }
        )
    }

    // MARK: - Search Field Focus

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

            window.makeFirstResponder(
                textField
            )
        }
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
        resizeWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            let targetHeight =
                hasResults
                ? self.expandedHeight
                : self.compactHeight

            self.resizeWindow(
                to: targetHeight,
                animated: true
            )
        }

        resizeWorkItem = workItem

        DispatchQueue.main.async(execute: workItem)
    }

    private func resizeWindow(
        to height: CGFloat,
        animated: Bool
    ) {

        guard window != nil else {
            return
        }

        let currentFrame = window.frame

        // Keep the TOP edge fixed.
        //
        // This means the window grows downward when
        // search results appear.
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

    // MARK: - Cleanup

    func applicationWillTerminate(
        _ notification: Notification
    ) {

        shortcut.unregister()

        if let keyboardMonitor {
            NSEvent.removeMonitor(
                keyboardMonitor
            )
        }

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )

        NotificationCenter.default.removeObserver(
            self,
            name: NSWindow.didMoveNotification,
            object: window
        )
    }
}
