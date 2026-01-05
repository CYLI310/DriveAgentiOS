import SwiftUI

struct RetroDigitalSpeedView: View {
    let speedMps: Double
    let useMetric: Bool
    let isSpeeding: Bool
    
    private var currentSpeed: Double {
        useMetric ? speedMps * 3.6 : speedMps * 2.23694
    }
    
    private var unitText: String {
        useMetric ? "KM/H" : "MPH"
    }

    var body: some View {
        ZStack {
            // Main Plate - Industrial Look
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 12)
            
            // Grid Background
            Path { path in
                let step: CGFloat = 12
                for i in 0...22 {
                    let pos = CGFloat(i) * step
                    path.move(to: CGPoint(x: pos, y: 0))
                    path.addLine(to: CGPoint(x: pos, y: 140))
                    path.move(to: CGPoint(x: 0, y: pos))
                    path.addLine(to: CGPoint(x: 220, y: pos))
                }
            }
            .stroke(Color(red: 0.4, green: 1.0, blue: 0.6).opacity(0.08), lineWidth: 0.6)
            .frame(width: 220, height: 140)
            .clipped()
            
            // Scanlines Effect
            GeometryReader { geo in
                VStack(spacing: 1.5) {
                    ForEach(0..<Int(geo.size.height / 2.5), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.15))
                            .frame(height: 0.8)
                    }
                }
            }
            .frame(width: 220, height: 140)
            .allowsHitTesting(false)
            
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    // Segmented Digits Look
                    Text(String(format: "%02d", Int(currentSpeed)))
                        .font(.system(size: 84, weight: .black, design: .monospaced))
                        .foregroundColor(isSpeeding ? Color(red: 1.0, green: 0.2, blue: 0.2) : Color(red: 0.3, green: 1.0, blue: 0.5))
                        .shadow(color: (isSpeeding ? Color.red : Color.green).opacity(0.6), radius: 12)
                    
                    Text(unitText)
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .foregroundColor((isSpeeding ? Color.red : Color.green).opacity(0.5))
                        .tracking(1)
                }
                
                // Speed Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.05))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [isSpeeding ? .red : Color(red: 0.0, green: 0.8, blue: 0.4), .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(min(currentSpeed / (useMetric ? 120 : 80), 1.0)))
                            .shadow(color: (isSpeeding ? Color.red : Color.green).opacity(0.5), radius: 4)
                    }
                }
                .frame(height: 12)
                .padding(.horizontal, 24)
                
                Text(isSpeeding ? "OVER LIMIT" : "UNDER LIMIT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor((isSpeeding ? Color.red : Color.green).opacity(0.9))
                    .tracking(4)
                    .opacity(0.7)
            }
        }
        .frame(width: 270, height: 190)
    }
}
