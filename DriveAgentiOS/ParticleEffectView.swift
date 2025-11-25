import SwiftUI

enum ParticleEffectStyle: String, CaseIterable, Identifiable {
    case off = "Off"
    case orbit = "Orbit"
    case pulse = "Pulse"
    case spiral = "Spiral"
    
    var id: String { self.rawValue }
}

struct ParticleEffectView: View {
    let accelerationState: LocationManager.AccelerationState
    let accelerationMagnitude: Double
    let style: ParticleEffectStyle
    @State private var particles: [Particle] = []
    @State private var breathingOpacity: Double = 1.0
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        if style == .off {
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: 0.033)) { timeline in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    for (index, particle) in particles.enumerated() {
                        let position = calculatePosition(for: particle, at: index, center: center)
                        let opacity = breathingOpacity * particle.opacity * 0.9
                        
                        // Draw glow
                        context.opacity = opacity * 0.3
                        context.fill(
                            Circle().path(in: CGRect(x: position.x - particle.size * 2, y: position.y - particle.size * 2, width: particle.size * 4, height: particle.size * 4)),
                            with: .color(glowColor)
                        )
                        
                        // Draw particle
                        context.opacity = opacity
                        context.fill(
                            Circle().path(in: CGRect(x: position.x - particle.size / 2, y: position.y - particle.size / 2, width: particle.size, height: particle.size)),
                            with: .color(particleColor)
                        )
                    }
                }
                .blur(radius: 1)
                .onAppear {
                    if accelerationState != .stopped {
                        generateParticles()
                        startAnimations()
                    }
                }
                .onChange(of: accelerationState) { newState in
                    if newState == .stopped {
                        particles.removeAll()
                    } else if particles.isEmpty {
                        generateParticles()
                        startAnimations()
                    }
                }
            }
        }
    }
    
    private func calculatePosition(for particle: Particle, at index: Int, center: CGPoint) -> CGPoint {
        switch style {
        case .off:
            return center
            
        case .orbit:
            let angle = particle.baseAngle + rotationAngle
            let x = center.x + CGFloat(cos(angle) * particle.radius)
            let y = center.y + CGFloat(sin(angle) * particle.radius)
            return CGPoint(x: x, y: y)
            
        case .pulse:
            let angle = particle.baseAngle
            let pulsedRadius = particle.radius * pulseScale
            let x = center.x + CGFloat(cos(angle) * pulsedRadius)
            let y = center.y + CGFloat(sin(angle) * pulsedRadius)
            return CGPoint(x: x, y: y)
            
        case .spiral:
            let spiralAngle = particle.baseAngle + rotationAngle * 2
            let spiralRadius = particle.radius + sin(rotationAngle * 3 + Double(index) * 0.5) * 20
            let x = center.x + CGFloat(cos(spiralAngle) * spiralRadius)
            let y = center.y + CGFloat(sin(spiralAngle) * spiralRadius)
            return CGPoint(x: x, y: y)
        }
    }
    
    private var particleColor: Color {
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
    
    private var rotationSpeed: Double {
        let baseSpeed = 0.02
        let accelerationBoost = min(accelerationMagnitude * 2, 0.08)
        return baseSpeed + accelerationBoost
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
            
        case .orbit, .spiral:
            // Rotation animation
            Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { timer in
                guard accelerationState != .stopped else {
                    timer.invalidate()
                    return
                }
                rotationAngle += rotationSpeed
            }
            
        case .pulse:
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
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
