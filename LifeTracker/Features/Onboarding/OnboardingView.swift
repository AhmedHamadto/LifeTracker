import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Organize Your Life",
            subtitle: "Track everything that matters in one app",
            icon: "rectangle.stack.fill",
            color: .blue,
            features: [
                "Medical documents & receipts",
                "Medication schedules & reminders",
                "Personal inventory & belongings",
                "Health & fitness tracking"
            ]
        ),
        OnboardingPage(
            title: "Smart Documents",
            subtitle: "Scan, organize, and search your documents",
            icon: "doc.viewfinder",
            color: .blue,
            features: [
                "Scan documents with your camera",
                "Automatic text extraction (OCR)",
                "Smart categorization",
                "Expiry date tracking"
            ]
        ),
        OnboardingPage(
            title: "Never Miss a Dose",
            subtitle: "Stay on top of your medications",
            icon: "pills.fill",
            color: .green,
            features: [
                "Medication schedules",
                "Push notification reminders",
                "Refill tracking",
                "Apple Health integration"
            ]
        ),
        OnboardingPage(
            title: "Track Your Stuff",
            subtitle: "Keep inventory of your belongings",
            icon: "barcode.viewfinder",
            color: .purple,
            features: [
                "Barcode scanning",
                "Product auto-lookup",
                "Value tracking for insurance",
                "Location management"
            ]
        ),
        OnboardingPage(
            title: "Stay Healthy",
            subtitle: "Log workouts and track progress",
            icon: "heart.fill",
            color: .red,
            features: [
                "Workout logging",
                "Body measurements",
                "Progress photos",
                "Apple Health sync"
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page Indicator
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? pages[index].color : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, Theme.Spacing.xl)

            // Buttons
            VStack(spacing: Theme.Spacing.md) {
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(pages[currentPage].color)

                    Button("Skip") {
                        hasCompletedOnboarding = true
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Get Started")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(pages[currentPage].color)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let features: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
                .padding(.bottom, Theme.Spacing.lg)

            // Title
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(page.subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Features
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(page.features, id: \.self) { feature in
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(page.color)

                        Text(feature)
                            .font(.body)
                    }
                }
            }
            .padding(.top, Theme.Spacing.xl)
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingView()
}
