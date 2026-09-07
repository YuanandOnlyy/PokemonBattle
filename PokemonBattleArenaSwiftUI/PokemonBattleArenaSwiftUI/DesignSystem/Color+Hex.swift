import SwiftUI

extension Color {
    /// Creates a Color from a "#RRGGBB" or "#RRGGBBAA" hex string, matching the hex
    /// values used throughout the original app's index.css / useSkin.ts.
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let length = hexString.count
        let red, green, blue, alpha: Double

        if length == 8 {
            red = Double((rgbValue & 0xFF000000) >> 24) / 255
            green = Double((rgbValue & 0x00FF0000) >> 16) / 255
            blue = Double((rgbValue & 0x0000FF00) >> 8) / 255
            alpha = Double(rgbValue & 0x000000FF) / 255
        } else {
            red = Double((rgbValue & 0xFF0000) >> 16) / 255
            green = Double((rgbValue & 0x00FF00) >> 8) / 255
            blue = Double(rgbValue & 0x0000FF) / 255
            alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
