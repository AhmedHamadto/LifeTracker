import SwiftUI

struct QuickActionButton: View {
    let title: String
    let icon: String
    var color: Color = Theme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionsRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.lg) {
                QuickActionButton(title: "Scan Doc", icon: "doc.viewfinder", color: .blue) {}
                QuickActionButton(title: "Add Med", icon: "pills.fill", color: .green) {}
                QuickActionButton(title: "Add Item", icon: "barcode.viewfinder", color: .purple) {}
                QuickActionButton(title: "Log Workout", icon: "dumbbell.fill", color: .red) {}
                QuickActionButton(title: "Measure", icon: "ruler", color: .orange) {}
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack {
        QuickActionsRow()
    }
}
