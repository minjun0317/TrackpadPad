import AppKit
import SwiftUI

final class OverlayPanel: NSPanel {
    // Roughly the aspect ratio of a MacBook trackpad.
    private static let size = NSSize(width: 420, height: 280)

    private let pad: PadController

    init(pad: PadController) {
        self.pad = pad
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let host = NSHostingView(rootView: OverlayView(pad: pad))
        host.sizingOptions = []
        contentView = host
    }

    func show() {
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            setFrameOrigin(NSPoint(x: visible.midX - Self.size.width / 2, y: visible.minY + 20))
        }
        orderFrontRegardless()
    }

    func hide() {
        // Let the SwiftUI dismiss animation finish before removing the window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self, !self.pad.isActive else { return }
            self.orderOut(nil)
        }
    }
}

struct OverlayView: View {
    @ObservedObject var pad: PadController

    private let calm = Animation.easeOut(duration: 0.18)

    var body: some View {
        ZStack {
            if pad.isActive {
                GlassEffectContainer(spacing: 8) {
                    VStack(spacing: 6) {
                        ForEach(PadLayout.rows, id: \.self) { row in
                            HStack(spacing: 6) {
                                ForEach(row, id: \.self) { key in
                                    KeyCap(key: key, pressed: pad.pressedKeys.contains(key))
                                }
                            }
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if pad.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .glassEffect(.regular, in: .capsule)
                            .offset(y: -24)
                            .transition(.opacity)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .padding(EdgeInsets(top: 30, leading: 12, bottom: 12, trailing: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(calm, value: pad.isActive)
        .animation(calm, value: pad.isLocked)
        .environment(\.colorScheme, .dark)
    }
}

private struct KeyCap: View {
    let key: PadKey
    let pressed: Bool

    var body: some View {
        Text("\(key)")
            .font(.system(size: 22, weight: .light, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(pressed ? 1 : 0.85))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(
                pressed ? .regular.tint(.white.opacity(0.16)) : .regular,
                in: .rect(cornerRadius: 14)
            )
            .animation(.easeOut(duration: pressed ? 0.06 : 0.2), value: pressed)
    }
}
