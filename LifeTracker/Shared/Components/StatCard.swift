import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = Theme.primary
    var trend: Trend?

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(iconColor)

                    Spacer()

                    if let trend {
                        TrendBadge(trend: trend)
                    }
                }

                Spacer()

                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 100)
        }
    }
}

struct TrendBadge: View {
    let trend: Trend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption2)
            Text(trend.displayValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(trend.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct Trend {
    let value: Double
    let isPositiveGood: Bool

    var icon: String {
        value >= 0 ? "arrow.up" : "arrow.down"
    }

    var displayValue: String {
        let absValue = abs(value)
        return String(format: "%.1f%%", absValue)
    }

    var color: Color {
        let isPositive = value >= 0
        if isPositiveGood {
            return isPositive ? .green : .red
        } else {
            return isPositive ? .red : .green
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        StatCard(
            title: "Documents",
            value: "24",
            icon: "doc.fill",
            iconColor: .blue
        )

        StatCard(
            title: "Medications",
            value: "3",
            icon: "pills.fill",
            iconColor: .green,
            trend: Trend(value: 100, isPositiveGood: true)
        )

        StatCard(
            title: "Items",
            value: "142",
            icon: "archivebox.fill",
            iconColor: .purple
        )

        StatCard(
            title: "Workouts",
            value: "12",
            icon: "dumbbell.fill",
            iconColor: .red,
            trend: Trend(value: 25, isPositiveGood: true)
        )
    }
    .padding()
}
