import Cocoa
import SwiftUI

class SearchWindow: NSWindow {

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: SearchWindow!

    private let shortcut = GlobalShortcut()

    private let compactHeight: CGFloat = 64
    private let expandedHeight: CGFloat = 420
    private let windowWidth: CGFloat = 680

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        createWindow()

        // Hide whenever our app loses focus to another app.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )

        shortcut.onShortcut = { [weak self] in
            self?.toggleWindow()
        }

        shortcut.register()
    }

    // MARK: - Window Creation

    private func createWindow() {

        let contentView = ContentView(
            onResultsChanged: { [weak self] hasResults in
                self?.updateWindowSize(
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

        // Allow dragging the window by its background.
        window.isMovableByWindowBackground = true

        window.level = .floating

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        window.hasShadow = true
        window.isReleasedWhenClosed = false

        window.contentView = NSHostingView(
            rootView: contentView
        )

        positionWindowInitially()

        window.orderOut(nil)
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

        // Don't reposition the window.
        // The user's last dragged position is preserved.

        NSApp.activate()

        // makeKeyAndOrderFront both shows the window
        // and makes it the key window.
        window.makeKeyAndOrderFront(nil)

        window.alphaValue = 0

        NSAnimationContext.runAnimationGroup { context in

            context.duration = 0.18

            context.timingFunction =
                CAMediaTimingFunction(
                    name: .easeOut
                )

            window.animator().alphaValue = 1
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

                // Do not reset the frame.
                // This preserves the user's dragged position.

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

    // MARK: - Results / Resize

    private func updateWindowSize(
        hasResults: Bool
    ) {

        let targetHeight = hasResults
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

        // Keep the top edge exactly where it is.
        //
        // Current top:
        //     currentFrame.maxY
        //
        // New bottom:
        //     top - newHeight
        //
        // X never changes.

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

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )
    }
}
