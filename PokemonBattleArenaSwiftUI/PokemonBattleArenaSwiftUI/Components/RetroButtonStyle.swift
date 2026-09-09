import SwiftUI

/// Mirrors `.retro-btn` / `.retro-btn-dark` in index.css and `RetroButton` in ui.tsx: a chunky
/// bordered button with a drop-shadow that "presses in" (shadow shrinks, content shifts) on tap.
struct RetroButtonStyle: ButtonStyle {
    var skin: SkinColors
    var dark: Bool = false
    var fontSize: CGFloat = 10
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let background = isDisabled ? skin.medium : (dark ? skin.dark : skin.medium)
        let foreground = dark ? skin.lightest : skin.darkest
        let pressed = configuration.isPressed
        // Matches .retro-btn's `box-shadow: 4px 4px 0` resting / `2px 2px 0` pressed in index.css.
        let shadowOffset: CGFloat = pressed ? 2 : 4

        return configuration.label
            .font(.pixel(fontSize))
            .foregroundStyle(foreground)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(background)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
            .background(alignment: .topLeading) {
                if !isDisabled {
                    Rectangle()
                        .fill(skin.darkest)
                        .offset(x: shadowOffset, y: shadowOffset)
                }
            }
            .opacity(isDisabled ? 0.5 : 1)
            .animation(.easeOut(duration: 0.05), value: pressed)
    }
}

/// Mirrors `.dialog-box` in index.css / `DialogBox` in ui.tsx: the classic Game Boy speech-box
/// with pixel corner accents.
struct DialogBoxView: View {
    var text: String
    var textColor: Color
    var skin: SkinColors

    var body: some View {
        Text(text.isEmpty ? " " : text)
            .font(.pixel(10))
            .foregroundStyle(textColor)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(skin.lightest)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }
}
