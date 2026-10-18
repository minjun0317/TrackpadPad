import CoreGraphics
import CPrivate
import Foundation

struct Touch {
    let id: Int32
    let point: CGPoint
    let isDown: Bool
}

enum Multitouch {
    /// Read from the multitouch thread; frames are dropped while false.
    static var isListening = false
    static var onFrame: (([Touch]) -> Void)?

    @discardableResult
    static func start() -> Int {
        Int(TPMultitouchStart(contactCallback))
    }
}

private let contactCallback: MTContactCallback = { _, touches, count, _, _ in
    guard Multitouch.isListening else { return 0 }
    var frame: [Touch] = []
    if let touches {
        for i in 0..<Int(count) {
            let t = touches[i]
            frame.append(Touch(
                id: t.identifier,
                point: CGPoint(x: CGFloat(t.normalized.position.x), y: CGFloat(t.normalized.position.y)),
                isDown: t.state == 4 || t.state == 5
            ))
        }
    }
    DispatchQueue.main.async { Multitouch.onFrame?(frame) }
    return 0
}
