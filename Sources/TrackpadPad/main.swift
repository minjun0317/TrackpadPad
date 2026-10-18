import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let pad = PadController()
    private lazy var panel = OverlayPanel(pad: pad)
    private lazy var input = InputController(pad: pad)
    private var statusItem: NSStatusItem?
    private var permissionTimer: Timer?
    private let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        pad.onActiveChange = { [weak self] active in
            active ? self?.panel.show() : self?.panel.hide()
        }
        Multitouch.onFrame = { [weak self] touches in self?.pad.handle(touches) }
        let devices = Multitouch.start()
        if devices <= 0 { NSLog("TrackpadPad: no multitouch device (\(devices))") }

        setUpStatusItem()
        startInputWhenTrusted()
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.and.hand.point.up.left.filled", accessibilityDescription: "Trackpad Pad")

        let menu = NSMenu()
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(NSMenuItem(title: "⌃ 누르고 있기: 패드 / ⌃⌃: 고정", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let settings = NSMenuItem(title: "손쉬운 사용 설정 열기…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(NSMenuItem(title: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
        updateStatusLine()
    }

    private func startInputWhenTrusted() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options), input.start() {
            updateStatusLine()
            return
        }
        updateStatusLine()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self, AXIsProcessTrusted(), self.input.start() else { return }
            timer.invalidate()
            self.updateStatusLine()
        }
    }

    private func updateStatusLine() {
        statusLine.title = input.isRunning ? "실행 중" : "손쉬운 사용 권한 필요"
    }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
