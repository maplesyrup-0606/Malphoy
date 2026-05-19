import AppKit
import Carbon

private var hotkeyManagerInstance: HotkeyManager?

func hotKeyHandler(nextHandler: EventHandlerCallRef?, event: EventRef?, userDate: UnsafeMutableRawPointer?) ->
    OSStatus {
        hotkeyManagerInstance?.onTrigger()
        return noErr
    }

final class HotkeyManager {
        private var hotKeyRef: EventHotKeyRef?
        let onTrigger: () -> Void

        init(onTrigger: @escaping () -> Void) {
            self.onTrigger = onTrigger
        
            var hotKeyID = EventHotKeyID()
            hotKeyID.signature = OSType(0x4D4C5048)
            hotKeyID.id = 1

            let keyCode = UInt32(kVK_Space)
            let modifiers = UInt32(cmdKey)

            RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

            hotkeyManagerInstance = self

            var eventType = EventTypeSpec()
            eventType.eventClass = OSType(kEventClassKeyboard)
            eventType.eventKind = OSType(kEventHotKeyPressed)

            InstallEventHandler(
                GetApplicationEventTarget(),
                hotKeyHandler,
                1,
                &eventType,
                nil,
                nil
            )
        }
    }
