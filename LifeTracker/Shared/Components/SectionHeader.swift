import SwiftUI

struct SectionHeader: View {
    let title: String
    var showSeeAll: Bool = false
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showSeeAll, let action {
                Button(action: action) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeader(title: "Recent Documents")

        SectionHeader(title: "Today's Medications", showSeeAll: true) {
            print("See all tapped")
        }
    }
}
