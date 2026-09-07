import SwiftUI

extension Font {
    /// The Game Boy "Press Start 2P" pixel font. Requires PressStart2P-Regular.ttf to be added to
    /// the app target and registered in Info.plist (see project README / setup notes) — until then
    /// this silently falls back to the system monospaced font so the app still renders correctly.
    static func pixel(_ size: CGFloat) -> Font {
        .custom("PressStart2P-Regular", size: size)
    }
}

extension View {
    /// Convenience for the extremely common `font(.pixel(_:)).foregroundStyle(_:)` pairing seen
    /// throughout the original app's inline styles.
    func pixelText(_ size: CGFloat, _ color: Color) -> some View {
        font(.pixel(size)).foregroundStyle(color)
    }
}
