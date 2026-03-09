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
        // 1. Welcome / Speed Tracking
        .page(OnboardingPage(
            icon: "speedometer",
            title: "Track Your Speed",
            description: "Track Speed Desc",
            color: .blue,
            highlights: []
        )),
        // 2. Speed Display Modes
        .page(OnboardingPage(
            icon: "gauge.with.needle",
            title: "Speed Display Modes",
            description: "Speed Display Modes Desc",
            color: .indigo,
            highlights: [
                FeatureHighlight(icon: "digitalcrown.horizontal.press.fill", label: "Digital Mode"),
                FeatureHighlight(icon: "dial.medium.fill", label: "Analog Mode"),
            ]
        )),
        // 3. Horizontal Dashboard live preview
        .horizontalDash,
        // 4. Route / Map
        .page(OnboardingPage(
            icon: "map.fill",
            title: "View Your Route",
            description: "View Route Desc",
            color: .green,
            highlights: []
        )),
        // 5. Speed Camera Alerts
        .page(OnboardingPage(
            icon: "camera.metering.multispot",
            title: "Speed Cameras",
            description: "Speed Cameras Desc",
            color: .red,
            highlights: [
                FeatureHighlight(icon: "speaker.wave.2.fill", label: "Audio Alert"),
                FeatureHighlight(icon: "location.fill", label: "Proximity Alert"),
            ]
        )),
        // 6. Distraction Alert
        .page(OnboardingPage(
            icon: "eye.trianglebadge.exclamationmark.fill",
            title: "Distraction Alert",
            description: "Distraction Alert Desc",
            color: .yellow,
            highlights: [
                FeatureHighlight(icon: "arkit", label: "Face Tracking"),
                FeatureHighlight(icon: "car.fill", label: "Speed Aware"),
            ]
        )),
        // 7. Live Activity
        .page(OnboardingPage(
            icon: "livephoto",
            title: "Live Activity",
            description: "Live Activity Desc",
            color: .cyan,
            highlights: [
                FeatureHighlight(icon: "lock.display", label: "Lock Screen"),
                FeatureHighlight(icon: "apps.iphone", label: "Dynamic Island"),
            ]
        )),
        // 8. Trip Information
        .page(OnboardingPage(
            icon: "figure.walk.motion",
            title: "Trip Information",
            description: "Trip Info Desc",
            color: .teal,
            highlights: [
                FeatureHighlight(icon: "arrow.triangle.turn.up.right.diamond.fill", label: "Distance"),
                FeatureHighlight(icon: "gauge.with.dots.needle.67percent", label: "Max Speed"),
            ]
        )),
        // 9. Customize Settings
        .page(OnboardingPage(
            icon: "gearshape.2.fill",
            title: "Customize Settings",
            description: "Customize Settings Desc",
            color: .purple,
            highlights: [
                FeatureHighlight(icon: "moon.fill", label: "Theme"),
                FeatureHighlight(icon: "ruler.fill", label: "Units"),
                FeatureHighlight(icon: "waveform.path", label: "Haptics"),
                FeatureHighlight(icon: "globe", label: "Language"),
            ]
        )),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Subtle ambient background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.06), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.25))
                            .frame(width: currentPage == index ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 8)

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
                        Button {
                            themeManager.triggerHaptic()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentPage -= 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(languageManager.localize("Back"))
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .transition(.opacity)
                    }

                    Spacer()

                    if currentPage < items.count - 1 {
                        Button {
                            themeManager.triggerHaptic()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(languageManager.localize("Next"))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .transition(.opacity)
                    } else {
                        Button {
                            themeManager.triggerHaptic(.medium)
                            isPresented = false
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(languageManager.localize("Get Started"))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
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
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 90, height: 90)
                        .blur(radius: 20)
                    Image(systemName: "rectangle.landscape.rotate")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 44)

                Text(languageManager.localize("Horizontal Dashboard"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(languageManager.localize("Horizontal Dash Desc"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
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
            .frame(height: 200)
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
        VStack(spacing: 0) {
            // Icon with ambient glow
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 110, height: 110)
                    .blur(radius: 24)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 44)
            .padding(.bottom, 28)

            // Title + Description
            VStack(spacing: 14) {
                Text(languageManager.localize(page.title))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(languageManager.localize(page.description))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            // Feature highlights grid (if any)
            if !page.highlights.isEmpty {
                let columns = page.highlights.count <= 2
                    ? [GridItem(.flexible()), GridItem(.flexible())]
                    : [GridItem(.flexible()), GridItem(.flexible())]

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(page.highlights) { highlight in
                        HighlightChip(icon: highlight.icon, label: languageManager.localize(highlight.label))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
            }

            Spacer()
        }
    }
}

// MARK: - Highlight Chip

struct HighlightChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Data Models

struct FeatureHighlight: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let highlights: [FeatureHighlight]
}
