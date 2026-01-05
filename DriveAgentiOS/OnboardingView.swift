import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var themeManager: ThemeManager
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            icon: "speedometer",
            title: "Track Your Speed",
            description: "Track Speed Desc",
            color: .blue
        ),
        OnboardingPage(
            icon: "map.fill",
            title: "View Your Route",
            description: "View Route Desc",
            color: .green
        ),
        OnboardingPage(
            icon: "camera.metering.multispot",
            title: "Speed Cameras",
            description: "Speed Cameras Desc",
            color: .red
        ),
        OnboardingPage(
            icon: "gearshape.fill",
            title: "Customize Settings",
            description: "Customize Settings Desc",
            color: .purple
        ),
        OnboardingPage(
            icon: "info.circle.fill",
            title: "Trip Information",
            description: "Trip Info Desc",
            color: .cyan
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 50)
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], languageManager: languageManager)
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
                    
                    if currentPage < pages.count - 1 {
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
}

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

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
