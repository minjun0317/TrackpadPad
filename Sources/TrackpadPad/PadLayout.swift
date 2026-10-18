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

    /// Share of the trackpad height per row, top to bottom. The full-width 0 row is shorter.
    static let rowHeights: [CGFloat] = [0.28, 0.28, 0.28, 0.16]

    static func key(at p: CGPoint) -> PadKey {
        let keys = rows[row(at: 1 - p.y)]
        return keys[clamp(Int(p.x * CGFloat(keys.count)), keys.count - 1)]
    }

    private static func row(at fromTop: CGFloat) -> Int {
        var edge: CGFloat = 0
        for (index, height) in rowHeights.enumerated() {
            edge += height
            if fromTop < edge { return index }
        }
        return rows.count - 1
    }

    private static func clamp(_ v: Int, _ hi: Int) -> Int { min(max(v, 0), hi) }
}
