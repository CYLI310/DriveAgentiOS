import SwiftUI

enum ParticleEffectStyle: String, CaseIterable, Identifiable {
    case off = "Off"
    case orbit = "Orbit"
    case linearGradient = "Gradient"
    
    var id: String { self.rawValue }
}

struct ParticleEffectView: View {
    let accelerationState: LocationManager.AccelerationState
    let accelerationMagnitude: Double
    let style: ParticleEffectStyle
    let isSpeeding: Bool // New parameter for speeding state
    @State private var particles: [Particle] = []
    @State private var breathingOpacity: Double = 1.0
    @State private var speedingBreathingOpacity: Double = 1.0 // Fast breathing for speeding
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: Double = 1.0
    @State private var currentRotationSpeed: Double = 0.02
    @State private var currentAccelerationState: LocationManager.AccelerationState = .stopped
    
    var body: some View {
        if style == .off {
            EmptyView()
        } else if style == .linearGradient {
            // Gradient Effect
            ZStack {
                AngularGradient(
                    gradient: Gradient(colors: gradientColors),
                    center: .center,
                    angle: .degrees(rotationAngle * 100)
                )

                .blur(radius: 60)
                .opacity(0.15)
                .ignoresSafeArea()
            }
            .onAppear {
                startAnimations()
            }
        } else {
            TimelineView(.animation(minimumInterval: 0.033)) { timeline in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    

                    // Particle Effects
                    for (index, particle) in particles.enumerated() {
                        let position = calculatePosition(for: particle, at: index, center: center)
                        let finalOpacity = isSpeeding ? speedingBreathingOpacity * particle.opacity * 0.9 : breathingOpacity * particle.opacity * 0.9
                        
                        // Draw glow
                        context.opacity = finalOpacity * 0.3
                        context.fill(
                            Circle().path(in: CGRect(x: position.x - particle.size * 2, y: position.y - particle.size * 2, width: particle.size * 4, height: particle.size * 4)),
                            with: .color(glowColor)
                        )
                        
                        // Draw particle
                        context.opacity = finalOpacity
                        context.fill(
                            Circle().path(in: CGRect(x: position.x - particle.size / 2, y: position.y - particle.size / 2, width: particle.size, height: particle.size)),
                            with: .color(particleColor)
                        )
                    }

                }
                .blur(radius: 1)
                .onAppear {
                    currentAccelerationState = accelerationState
                    currentRotationSpeed = calculateRotationSpeed()
                    if accelerationState != .stopped {
                        generateParticles()
                        startAnimations()
                    }
                }
                .onChange(of: accelerationState) { newState in
                    currentAccelerationState = newState
                    if newState == .stopped && style == .orbit {
                        particles.removeAll()
                    } else if particles.isEmpty && style == .orbit {
                        generateParticles()
                        startAnimations()
                    }
                }

                .onChange(of: isSpeeding) { newValue in
                    if newValue {
                        // Start fast breathing animation when speeding
                        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                            speedingBreathingOpacity = 0.3
                        }
                    } else {
                        // Reset speeding breathing opacity
                        withAnimation(.easeInOut(duration: 0.2)) {
                            speedingBreathingOpacity = 1.0
                        }
                    }
                }
            }
        }
    }
    

    
    private func calculatePosition(for particle: Particle, at index: Int, center: CGPoint) -> CGPoint {
        switch style {
        case .off, .linearGradient:
            return center
            
        case .orbit:
            let angle = particle.baseAngle + rotationAngle
            let x = center.x + CGFloat(cos(angle) * particle.radius)
            let y = center.y + CGFloat(sin(angle) * particle.radius)
            return CGPoint(x: x, y: y)
        }
    }
    
    private var particleColor: Color {
        if isSpeeding {
            return .red
        }
        
        switch accelerationState {
        case .accelerating:
            return .blue
        case .decelerating:
            return .green
        case .steady:
            // Interpolate between blue and green for smooth transition
            return Color(
                red: 0.0,
                green: 0.5,
                blue: 0.75
            )
        case .stopped:
            return .clear
        }
    }
    
    private var glowColor: Color {
        if isSpeeding {
            return .red
        }
        
        switch accelerationState {
        case .accelerating:
            return .blue
        case .decelerating:
            return .green
        case .steady:
            return Color(
                red: 0.0,
                green: 0.5,
                blue: 0.75
            )
        case .stopped:
            return .clear
        }
    }
    
    private var gradientColors: [Color] {
        if isSpeeding {
            return [.red, .orange, .red]
        }
        
        switch accelerationState {
        case .accelerating:
            return [.blue, .cyan, .blue]
        case .decelerating:
            return [.green, .mint, .green]
        case .steady:
            return [.teal, .blue, .teal]
        case .stopped:
            return [.gray.opacity(0.5), .clear]
        }
    }
    
    private func calculateRotationSpeed() -> Double {
        return 0.005 // Static, slower speed
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                baseAngle: Double.random(in: 0...(2 * .pi)),
                radius: Double.random(in: 100...140),
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.4...0.9)
            )
        }
    }
    
    private func startAnimations() {
        // Breathing animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            breathingOpacity = 0.5
        }
        
        // Style-specific animations
        switch style {
        case .off:
            break
            
        case .orbit, .linearGradient:
            // Rotation animation
            Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { timer in
                if style != .linearGradient && currentAccelerationState == .stopped {
                    timer.invalidate()
                    return
                }
                rotationAngle += currentRotationSpeed
            }
        }
    }
}


struct Particle: Identifiable {
    let id = UUID()
    let baseAngle: Double
    let radius: Double
    let size: CGFloat
    let opacity: Double
}
