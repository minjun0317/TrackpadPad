import CoreGraphics

typealias PadKey = Int

/// The whole trackpad is a phone-style digit pad: three rows of 1–9 and a full-width 0.
/// Coordinates are normalized 0...1, origin bottom-left.
enum PadLayout {
    static let rows: [[PadKey]] = [
        [7, 8, 9],
        [4, 5, 6],
        [1, 2, 3],
        [0],
    ]

    static func key(at p: CGPoint) -> PadKey {
        let row = clamp(Int((1 - p.y) * 4), rows.count - 1)
        let keys = rows[row]
        return keys[clamp(Int(p.x * CGFloat(keys.count)), keys.count - 1)]
    }

    private static func clamp(_ v: Int, _ hi: Int) -> Int { min(max(v, 0), hi) }
}
