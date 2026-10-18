import CoreGraphics

enum KeySender {
    /// Tags our synthetic events so the event tap can recognize them.
    static let marker: Int64 = 0x5450_5044

    private static let source = CGEventSource(stateID: .privateState)

    static func send(_ digit: PadKey) {
        post(keypadDigits[digit])
    }

    // kVK_ANSI_Keypad0 ... kVK_ANSI_Keypad9
    private static let keypadDigits: [CGKeyCode] = [0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5B, 0x5C]

    private static func post(_ code: CGKeyCode) {
        for keyDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: keyDown) else { continue }
            // Control is physically held while typing; strip it so apps see a plain keystroke.
            event.flags = .maskNumericPad
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            event.post(tap: .cghidEventTap)
        }
    }
}
