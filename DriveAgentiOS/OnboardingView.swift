import SwiftUI

// MARK: - Onboarding Item Type

enum OnboardingItem {
    case page(OnboardingPage)
    case horizontalDash
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var themeManager: ThemeManager
    @State private var currentPage = 0

    // Constant bindings used by the HorizontalDashboardView preview
    @State private var dummyMapVisible: Bool = false
    @State private var dummyShowSettings: Bool = false

    let items: [OnboardingItem] = [
        .page(OnboardingPage(
            icon: "speedometer",
            title: "Track Your Speed",
            description: "Track Speed Desc",
            color: .blue
        )),
        .page(OnboardingPage(
            icon: "map.fill",
            title: "View Your Route",
            description: "View Route Desc",
            color: .green
        )),
        .horizontalDash,
        .page(OnboardingPage(
            icon: "camera.metering.multispot",
            title: "Speed Cameras",
            description: "Speed Cameras Desc",
            color: .red
        )),
        .page(OnboardingPage(
            icon: "gearshape.fill",
            title: "Customize Settings",
            description: "Customize Settings Desc",
            color: .purple
        )),
        .page(OnboardingPage(
            icon: "info.circle.fill",
            title: "Trip Information",
            description: "Trip Info Desc",
            color: .cyan
        ))
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 50)

                TabView(selection: $currentPage) {
                    ForEach(0..<items.count, id: \.self) { index in
                        itemView(for: items[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _ in
                    themeManager.triggerHaptic()
                }

                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(languageManager.localize("Back")) {
                            themeManager.triggerHaptic()
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()

                    if currentPage < items.count - 1 {
                        Button(languageManager.localize("Next")) {
                            themeManager.triggerHaptic()
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .transition(.opacity)
                    } else {
                        Button(languageManager.localize("Get Started")) {
                            themeManager.triggerHaptic(.medium)
                            isPresented = false
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: currentPage)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func itemView(for item: OnboardingItem) -> some View {
        switch item {
        case .page(let page):
            OnboardingPageView(page: page, languageManager: languageManager)
        case .horizontalDash:
            OnboardingHorizontalDashView(
                languageManager: languageManager,
                isMapVisible: $dummyMapVisible,
                showingSettings: $dummyShowSettings
            )
        }
    }
}

// MARK: - Horizontal Dash Preview Page

struct OnboardingHorizontalDashView: View {
    @ObservedObject var languageManager: LanguageManager
    @Binding var isMapVisible: Bool
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Title header
            VStack(spacing: 8) {
                Text(languageManager.localize("Horizontal Dashboard"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)

                Text(languageManager.localize("Horizontal Dash Desc"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Live preview of the horizontal dash with demo data
            HorizontalDashboardView(
                speed: "82 km/h",
                speedMps: 22.8,
                useMetric: true,
                isSpeeding: false,
                streetName: "Sunset Boulevard",
                closestTrap: nil,
                tripDistance: "12.4 km",
                maxSpeed: "97 km/h",
                accelerationState: .steady,
                accelerationMagnitude: 0.0,
                languageManager: languageManager,
                isMapVisible: $isMapVisible,
                showingSettings: $showingSettings,
                alertGlowOpacity: 0.0,
                alertBackgroundOpacity: 0.0
            )
            .frame(height: 220)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .allowsHitTesting(false)

            Spacer()
        }
    }
}

// MARK: - Standard Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @ObservedObject var languageManager: LanguageManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [page.color, page.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 50)

            VStack(spacing: 16) {
                Text(languageManager.localize(page.title))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(languageManager.localize(page.description))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}

// MARK: - Data Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
