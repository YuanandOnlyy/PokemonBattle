import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Font {
    /// The Game Boy "Press Start 2P" pixel font. Registered via Info.plist + Resources/PressStart2P-Regular.ttf.
    /// Falls back to a monospaced system font if the custom face is unavailable.
    static func pixel(_ size: CGFloat) -> Font {
        #if canImport(UIKit)
        if UIFont(name: "PressStart2P-Regular", size: size) != nil {
            return .custom("PressStart2P-Regular", size: size)
        }
        #endif
        return .system(size: size, weight: .bold, design: .monospaced)
    }
}

extension View {
    /// Convenience for the extremely common `font(.pixel(_:)).foregroundStyle(_:)` pairing seen
    /// throughout the original app's inline styles.
    func pixelText(_ size: CGFloat, _ color: Color) -> some View {
        font(.pixel(size)).foregroundStyle(color)
    }
}
