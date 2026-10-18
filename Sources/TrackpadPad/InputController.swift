import CoreGraphics
import Foundation

/// Watches the Control key (hold = show pad, double tap = lock) and swallows
/// pointer events while the pad is open.
final class InputController {
    private let pad: PadController
    private var tap: CFMachPort?

    private var controlDownAt: TimeInterval?
    private var lastControlTapAt: TimeInterval = 0
    private var pendingActivation: DispatchWorkItem?

    private static let activationDelay: TimeInterval = 0.12
    private static let quickTap: TimeInterval = 0.25
    private static let doubleTapWindow: TimeInterval = 0.4

    private static let leftControl: Int64 = 59
    private static let rightControl: Int64 = 62
    private static let escape: Int64 = 53
    private static let otherModifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskShift]

    private static let pointerTypes: [UInt32] = [
        CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
        .otherMouseDown, .otherMouseUp, .otherMouseDragged, .scrollWheel,
    ].map(\.rawValue) + [29, 30, 31, 32] // gesture, magnify, swipe, smart magnify

    init(pad: PadController) {
        self.pad = pad
    }

    var isRunning: Bool { tap != nil }

    func start() -> Bool {
        guard tap == nil else { return true }
        let types = Self.pointerTypes + [CGEventType.flagsChanged, .keyDown, .keyUp].map(\.rawValue)
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: tapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass

        case .flagsChanged:
            handleFlags(event)
            return pass

        case .keyDown, .keyUp:
            if event.getIntegerValueField(.eventSourceUserData) == KeySender.marker {
                event.flags = event.flags.intersection(.maskNumericPad)
                return pass
            }
            guard type == .keyDown else { return pass }
            if pad.isLocked, event.getIntegerValueField(.keyboardEventKeycode) == Self.escape {
                unlock()
                return nil
            }
            // Control + another key is a shortcut, not a pad gesture.
            if controlDownAt != nil { cancelHold() }
            return pass

        default:
            return pad.isActive ? nil : pass
        }
    }

    private func handleFlags(_ event: CGEvent) {
        let code = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let hasOthers = !flags.intersection(Self.otherModifiers).isEmpty

        guard code == Self.leftControl || code == Self.rightControl else {
            if hasOthers, controlDownAt != nil { cancelHold() }
            return
        }

        if flags.contains(.maskControl) {
            guard !hasOthers else { cancelHold(); return }
            controlDownAt = ProcessInfo.processInfo.systemUptime
            guard !pad.isLocked else { return }
            let work = DispatchWorkItem { [weak self] in self?.pad.setActive(true) }
            pendingActivation = work
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.activationDelay, execute: work)
        } else {
            controlReleased()
        }
    }

    private func controlReleased() {
        pendingActivation?.cancel()
        guard let downAt = controlDownAt else { return }
        controlDownAt = nil

        let now = ProcessInfo.processInfo.systemUptime
        if now - downAt < Self.quickTap {
            if now - lastControlTapAt < Self.doubleTapWindow {
                lastControlTapAt = 0
                pad.isLocked ? unlock() : lock()
                return
            }
            lastControlTapAt = now
        }
        if !pad.isLocked { pad.setActive(false) }
    }

    private func cancelHold() {
        pendingActivation?.cancel()
        controlDownAt = nil
        lastControlTapAt = 0
        if !pad.isLocked { pad.setActive(false) }
    }

    private func lock() {
        pad.setLocked(true)
        pad.setActive(true)
    }

    private func unlock() {
        pad.setLocked(false)
        pad.setActive(false)
    }
}

private let tapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let controller = Unmanaged<InputController>.fromOpaque(userInfo).takeUnretainedValue()
    return controller.handle(type: type, event: event)
}
