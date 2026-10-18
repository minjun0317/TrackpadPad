import AppKit
import CoreGraphics

final class PadController: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var isLocked = false
    /// Keys a finger is currently resting on.
    @Published private(set) var pressedKeys: Set<PadKey> = []

    var onActiveChange: ((Bool) -> Void)?

    private struct TrackedTouch {
        let start: PadKey
        var current: PadKey
        let startedAt: TimeInterval
    }

    private static let maxTapDuration: TimeInterval = 0.6

    private var tracked: [Int32: TrackedTouch] = [:]
    /// Fingers already resting on the trackpad when the pad opened.
    private var ignored: Set<Int32> = []
    private var needsBaseline = false

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        tracked = [:]
        ignored = []
        pressedKeys = []
        needsBaseline = active
        Multitouch.isListening = active
        CGAssociateMouseAndMouseCursorPosition(active ? 0 : 1)
        onActiveChange?(active)
    }

    func setLocked(_ locked: Bool) {
        isLocked = locked
    }

    func handle(_ touches: [Touch]) {
        guard isActive else { return }
        let down = touches.filter(\.isDown)

        if needsBaseline {
            needsBaseline = false
            ignored = Set(down.map(\.id))
        }

        let now = ProcessInfo.processInfo.systemUptime
        var seen = Set<Int32>()
        for touch in down where !ignored.contains(touch.id) {
            seen.insert(touch.id)
            let key = PadLayout.key(at: touch.point)
            if tracked[touch.id] == nil {
                tracked[touch.id] = TrackedTouch(start: key, current: key, startedAt: now)
                haptic()
            } else {
                tracked[touch.id]?.current = key
            }
        }

        for (id, touch) in tracked where !seen.contains(id) {
            if touch.current == touch.start, now - touch.startedAt < Self.maxTapDuration {
                KeySender.send(touch.start)
            }
        }
        tracked = tracked.filter { seen.contains($0.key) }
        ignored.formIntersection(down.map(\.id))

        let pressed = Set(tracked.values.filter { $0.current == $0.start }.map(\.start))
        if pressed != pressedKeys { pressedKeys = pressed }
    }

    private func haptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}
