import SwiftUI

struct AnalogSpeedView: View {
    let speedMps: Double
    let useMetric: Bool
    let isSpeeding: Bool
    let accelerationState: LocationManager.AccelerationState
    let dashColor: DashColor
    
    private var maxSpeed: Double {
        useMetric ? 240 : 160
    }
    
    private var currentSpeed: Double {
        let value = useMetric ? speedMps * 3.6 : speedMps * 2.23694
        return max(0, min(value, maxSpeed))
    }
    
    private var unitText: String {
        useMetric ? "KM/H" : "MPH"
    }
    
    private var needleAngle: Angle {
        // Gauge spans -135° to +135° (270 degrees sweep)
        let fraction = currentSpeed / maxSpeed
        return Angle(degrees: -135 + 270 * fraction)
    }
    
    private var themeColor: Color {
        if isSpeeding { return .red }
        switch accelerationState {
        case .accelerating: return .blue
        case .decelerating: return .green
        case .steady: return .teal
        case .stopped: return .gray
        }
    }
    
    private var dialBackground: AnyShapeStyle {
        if dashColor == .black {
            return AnyShapeStyle(RadialGradient(
                gradient: Gradient(colors: [Color(white: 0.12), .black]),
                center: .center,
                startRadius: 0,
                endRadius: 160
            ))
        } else {
            return AnyShapeStyle(RadialGradient(
                gradient: Gradient(colors: [Color(white: 0.98), Color(white: 0.85)]),
                center: .center,
                startRadius: 0,
                endRadius: 160
            ))
        }
    }
    
    private var tickColor: Color {
        dashColor == .black ? .white : .black
    }
    
    private var labelColor: Color {
        dashColor == .black ? .white.opacity(0.7) : .black.opacity(0.6)
    }
    
    private var mainTextColor: Color {
        dashColor == .black ? .white : .black
    }

    var body: some View {
        ZStack {
            // Main Glass Plate
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(dashColor == .black ? 0.4 : 0.2), radius: 25, x: 0, y: 15)
            
            // Inner Dial
            Circle()
                .fill(dialBackground)
                .padding(15)
            
            // Ticks
            ForEach(0...Int(maxSpeed / 10), id: \.self) { i in
                let value = Double(i * 10)
                let fraction = value / maxSpeed
                let angle = Angle(degrees: -135 + 270 * fraction)
                let isMajor = i % 2 == 0
                
                Capsule()
                    .fill(isMajor ? tickColor.opacity(0.8) : tickColor.opacity(0.3))
                    .frame(width: isMajor ? 3 : 1.5, height: isMajor ? 18 : 10)
                    .offset(y: -105) // Radius of ticks
                    .rotationEffect(angle)
            }
            
            // Labels (Outside the ring)
            ForEach(0...Int(maxSpeed / 40), id: \.self) { i in
                let value = Double(i * 40)
                let fraction = value / maxSpeed
                let angle = Angle(degrees: -135 + 270 * fraction)
                
                // Position labels with trigonometry to keep them upright
                let radius: CGFloat = 132
                let x = radius * cos(CGFloat(angle.radians - .pi / 2))
                let y = radius * sin(CGFloat(angle.radians - .pi / 2))
                
                Text("\(Int(value))")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(labelColor)
                    .position(x: 140 + x, y: 140 + y) // Center is (140, 140) for a 280 frame
            }
            
            // Speeding Alert Arc (Subtle)
            if isSpeeding {
                Circle()
                    .trim(from: 0.375, to: 1.0) 
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.clear, .red.opacity(0.4), .red]),
                            center: .center,
                            angle: .degrees(90)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 210, height: 210)
                    .rotationEffect(.degrees(90))
                    .blur(radius: 2)
            }
            
            // Central Info
            VStack(spacing: 0) {
                Text(String(format: "%.0f", currentSpeed))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(mainTextColor)
                    .shadow(color: themeColor.opacity(dashColor == .black ? 0.3 : 0.1), radius: 10)
                Text(unitText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeColor)
                    .tracking(3)
            }
            .offset(y: 50)
            
            // Needle
            ZStack(alignment: .bottom) {
                // Needle Glow
                Capsule()
                    .fill(themeColor.opacity(0.4))
                    .frame(width: 10, height: 110)
                    .blur(radius: 8)
                    .offset(y: -55)
                
                // Needle Main
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [dashColor == .black ? .white : .black.opacity(0.8), themeColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 105)
                    .offset(y: -52.5)
            }
            .rotationEffect(needleAngle)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.86), value: currentSpeed)
            
            // Hub
            Circle()
                .fill(dashColor == .black ? Color.black : Color(white: 0.8))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [dashColor == .black ? .white.opacity(0.5) : .black.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(radius: 5)
        }
        .frame(width: 280, height: 280)
    }
}
