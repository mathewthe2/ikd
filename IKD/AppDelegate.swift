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

    // We only position the window automatically once.
    private var hasInitialPosition = false

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        createWindow()

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

        // Allows dragging the window by its background.
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

        // Only position the window automatically
        // on the very first launch.
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

        hasInitialPosition = true
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

        // IMPORTANT:
        //
        // Do NOT call positionWindow() here.
        //
        // The window already knows where the user dragged it.
        // We only make sure it starts in its compact state.

        resizeWindow(
            to: compactHeight,
            animated: false
        )

        NSApp.activate(
            ignoringOtherApps: true
        )

        window.alphaValue = 0

        window.orderFrontRegardless()

        window.makeKey()

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

                // Keep the window exactly where the user
                // left it.
                //
                // We don't call positionWindow().
                // We don't reset the X coordinate.
                // We don't reset the Y coordinate.

                self.window.orderOut(nil)
            }
        )
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

        // Keep the TOP edge exactly where it is.
        //
        // NSWindow coordinates use the bottom-left as the origin,
        // so when the height changes we calculate a new Y such that:
        //
        // newY + newHeight = oldY + oldHeight
        //
        // This means the top stays fixed and only the bottom moves.

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

    func applicationWillTerminate(
        _ notification: Notification
    ) {

        shortcut.unregister()
    }
}
