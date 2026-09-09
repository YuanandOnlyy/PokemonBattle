import SwiftUI

/// Fades a view in with a slight upward slide shortly after it appears, timed to a slot index so
/// a stack of sibling views cascades in one after another instead of popping in all at once.
/// Mirrors the staggered boot-sequence reveal used by `SplashScreenView`. `order` only needs to
/// increase between siblings on the same screen; it resets automatically whenever the view is
/// re-inserted (e.g. navigating back to a screen replays the cascade).
struct StaggerAppear: ViewModifier {
    var order: Int
    var step: Double = 0.06
    var distance: CGFloat = 14

    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : distance)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78).delay(Double(order) * step)) {
                    shown = true
                }
            }
    }
}

extension View {
    /// Cascading entrance: apply with an increasing `order` across sibling views so they reveal
    /// in sequence top-to-bottom (or in whatever order you assign).
    func staggerAppear(_ order: Int, step: Double = 0.06, distance: CGFloat = 14) -> some View {
        modifier(StaggerAppear(order: order, step: step, distance: distance))
    }
}
