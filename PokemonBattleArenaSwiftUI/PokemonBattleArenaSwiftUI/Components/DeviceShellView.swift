import SwiftUI

/// Mirrors `PhoneFrame` in ui.tsx: the decorative Game Boy hardware shell (top chrome, screen
/// bezel with scanlines/vignette, D-pad, speaker grille, SELECT/START, A/B buttons) that wraps
/// every screen. Colors are hard-coded to the dev-body/dev-* CSS variables in index.css — these
/// don't reskin with the console skin (only the on-screen content does, exactly as in the original).
struct DeviceShellView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    private let devBody = Color(hex: "#1c1c28")
    private let devScreenBezel = Color(hex: "#0a0a14")
    private let devButtonAB = Color(hex: "#8a1050")
    private let devButtonSys = Color(hex: "#3a3a50")
    private let devDpad = Color(hex: "#141422")
    private let devLED = Color(hex: "#00e000")

    var body: some View {
        VStack(spacing: 0) {
            topChrome
            screenZone
            bottomChrome
        }
        .background(devBody)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12, bottomLeadingRadius: 40,
                bottomTrailingRadius: 40, topTrailingRadius: 12
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#2a2a3a"), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.8), radius: 30, y: 20)
        .padding()
    }

    private var topChrome: some View {
        HStack {
            Text("Game Boy")
                .font(.pixel(8))
                .foregroundStyle(Color(hex: "#5060a0"))
                .tracking(2)
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(devLED)
                    .frame(width: 7, height: 7)
                    .shadow(color: devLED, radius: 4)
                Text("POWER")
                    .font(.pixel(5))
                    .foregroundStyle(Color(hex: "#404060"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [Color(hex: "#26263a"), Color(hex: "#1c1c28")], startPoint: .top, endPoint: .bottom)
        )
        .overlay(Rectangle().fill(devScreenBezel).frame(height: 3), alignment: .bottom)
    }

    private var screenZone: some View {
        ZStack {
            content()
        }
        .background(SkinColors.dmg.medium)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#060610"), lineWidth: 3))
        .overlay(
            // CRT vignette
            RadialGradient(colors: [.clear, .black.opacity(0.4)], center: .center, startRadius: 120, endRadius: 260)
                .allowsHitTesting(false)
        )
        .padding(14)
        .padding(.vertical, -4)
        .background(devScreenBezel)
    }

    private var bottomChrome: some View {
        HStack(alignment: .center, spacing: 8) {
            dPad
            centerControls
            abButtons
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(
            LinearGradient(colors: [Color(hex: "#1c1c28"), Color(hex: "#161620")], startPoint: .top, endPoint: .bottom)
        )
        .overlay(Rectangle().fill(devScreenBezel).frame(height: 3), alignment: .top)
    }

    private var dPad: some View {
        VStack(spacing: 0) {
            dPadSegment("\u{25B2}", width: 22, height: 16)
            HStack(spacing: 0) {
                dPadSegment("\u{25C0}", width: 16, height: 22)
                Rectangle().fill(devDpad).frame(width: 22, height: 22)
                    .overlay(Rectangle().stroke(Color(hex: "#0a0a18"), lineWidth: 2))
                dPadSegment("\u{25B6}", width: 16, height: 22)
            }
            dPadSegment("\u{25BC}", width: 22, height: 16)
        }
    }

    private func dPadSegment(_ symbol: String, width: CGFloat, height: CGFloat) -> some View {
        Text(symbol)
            .font(.system(size: 8))
            .foregroundStyle(Color(hex: "#303048"))
            .frame(width: width, height: height)
            .background(devDpad)
            .overlay(Rectangle().stroke(Color(hex: "#0a0a18"), lineWidth: 2))
    }

    private var centerControls: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(4), spacing: 3), count: 5), spacing: 3) {
                ForEach(0..<15, id: \.self) { _ in
                    Circle().fill(Color(hex: "#0a0a18")).frame(width: 4, height: 4)
                }
            }
            HStack(spacing: 10) {
                sysButton("SELECT")
                sysButton("START")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func sysButton(_ label: String) -> some View {
        VStack(spacing: 3) {
            Capsule()
                .fill(devButtonSys)
                .frame(width: 28, height: 10)
                .rotationEffect(.degrees(-15))
                .overlay(Capsule().stroke(devScreenBezel, lineWidth: 2).rotationEffect(.degrees(-15)))
            Text(label)
                .font(.pixel(5))
                .foregroundStyle(Color(hex: "#404060"))
        }
    }

    private var abButtons: some View {
        HStack(spacing: 6) {
            abButton("B", offsetY: 8)
            abButton("A", offsetY: -8)
        }
    }

    private func abButton(_ label: String, offsetY: CGFloat) -> some View {
        Text(label)
            .font(.pixel(9))
            .foregroundStyle(Color(hex: "#f0a0c0"))
            .frame(width: 32, height: 32)
            .background(Circle().fill(label == "A" ? devButtonAB : Color(hex: "#701040")))
            .overlay(Circle().stroke(devScreenBezel, lineWidth: 2))
            .offset(y: offsetY)
    }
}
