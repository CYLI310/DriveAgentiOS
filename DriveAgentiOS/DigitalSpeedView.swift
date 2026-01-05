import SwiftUI

struct DigitalSpeedView: View {
    let speed: String
    let isSpeeding: Bool
    
    var body: some View {
        Text(speed)
            .font(.system(size: 80, weight: .bold, design: .rounded))
            .foregroundColor(isSpeeding ? .red : .primary)
            .shadow(color: isSpeeding ? .red.opacity(0.3) : .clear, radius: 10)
    }
}
