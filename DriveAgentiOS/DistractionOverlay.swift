import SwiftUI

struct DistractionOverlay: View {
    @ObservedObject var languageManager: LanguageManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if #available(iOS 18.0, *) {
                    Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .symbolEffect(.bounce, options: .repeating)
                } else {
                    // Fallback on earlier versions
                }
                
                Text(languageManager.localize("Eyes on the road!"))
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                
                Text(languageManager.localize("Focus on driving"))
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.red.opacity(0.3))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
