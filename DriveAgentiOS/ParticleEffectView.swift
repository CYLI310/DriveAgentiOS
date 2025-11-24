import SwiftUI

struct ParticleEffectView: View {
    let accelerationState: LocationManager.AccelerationState
    let accelerationMagnitude: Double
    @State private var particles: [Particle] = []
    @State private var breathingOpacity: Double = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.033)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                for particle in particles {
                    let angle = particle.baseAngle + rotationAngle
                    let x = center.x + CGFloat(cos(angle) * particle.radius)
                    let y = center.y + CGFloat(sin(angle) * particle.radius)
                    
                    let opacity = breathingOpacity * particle.opacity * 0.9 // Slightly faint
                    
                    // Draw glow
                    context.opacity = opacity * 0.3
                    context.fill(
                        Circle().path(in: CGRect(x: x - particle.size * 2, y: y - particle.size * 2, width: particle.size * 4, height: particle.size * 4)),
                        with: .color(glowColor)
                    )
                    
                    // Draw particle
                    context.opacity = opacity
                    context.fill(
                        Circle().path(in: CGRect(x: x - particle.size / 2, y: y - particle.size / 2, width: particle.size, height: particle.size)),
                        with: .color(particleColor)
                    )
                }
            }
            .blur(radius: 1)
            .onAppear {
                if accelerationState != .stopped {
                    generateParticles()
                    startBreathing()
                    startRotation()
                }
            }
            .onChange(of: accelerationState) { newState in
                if newState == .stopped {
                    particles.removeAll()
                } else if particles.isEmpty {
                    generateParticles()
                    startBreathing()
                    startRotation()
                }
            }
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
        // Base speed + acceleration-dependent speed
        // Clamp between 0.01 (slow) and 0.1 (fast)
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
    
    private func startBreathing() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            breathingOpacity = 0.5
        }
    }
    
    private func startRotation() {
        Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { timer in
            guard accelerationState != .stopped else {
                timer.invalidate()
                return
            }
            rotationAngle += rotationSpeed
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
