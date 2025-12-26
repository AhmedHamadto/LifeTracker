import SwiftUI

extension View {
    /// Applies a conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies a conditional modifier with an else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }

    /// Wraps the view in a navigation link
    func asNavigationLink<Destination: View>(destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            self
        }
    }

    /// Adds a card-like background
    func cardStyle(padding: CGFloat = Theme.Spacing.lg, cornerRadius: CGFloat = Theme.Radius.lg) -> some View {
        self
            .padding(padding)
            .background(Theme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Adds a shadowed card background
    func shadowedCardStyle(padding: CGFloat = Theme.Spacing.lg, cornerRadius: CGFloat = Theme.Radius.lg) -> some View {
        self
            .padding(padding)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    /// Hides the view conditionally
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }

    /// Applies a loading overlay
    func loading(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
        }
    }

    /// Adds a badge overlay
    func badge(_ count: Int, color: Color = .red) -> some View {
        self.overlay(alignment: .topTrailing) {
            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color)
                    .clipShape(Capsule())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - Keyboard Dismissal

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Safe Area

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
