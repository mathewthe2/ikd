import Cocoa
import Carbon.HIToolbox

final class GlobalShortcut {

    private var hotKeyRef: EventHotKeyRef?

    var onShortcut: (() -> Void)?

    func register() {

        let keyCode: UInt32 = 49 // Space
        let modifiers: UInt32 = UInt32(optionKey)

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x494B444B),
            id: 1
        )

        var ref: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr else {
            print("Failed to register shortcut: \(status)")
            return
        }

        hotKeyRef = ref

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (
                _,
                _,
                userData
            ) -> OSStatus in

                guard let userData else {
                    return noErr
                }

                let shortcut = Unmanaged<GlobalShortcut>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                shortcut.onShortcut?()

                return noErr

            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        print("Global shortcut registered: Option + Space")
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}
