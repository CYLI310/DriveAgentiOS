import SwiftUI

enum ParticleEffectStyle: String, CaseIterable, Identifiable {
    case off = "Off"
    case orbit = "Orbit"
    case pulse = "Pulse"
    case spiral = "Spiral"
    case linearGradient = "Gradient"
    case grid = "Grid"
    case waves = "Waves"
    
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
                .blur(radius: 20)
                .opacity(0.3)
                .mask(Circle())
            }
            .onAppear {
                startAnimations()
            }
        } else {
            TimelineView(.animation(minimumInterval: 0.033)) { timeline in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    if style == .grid {
                        drawGrid(context: context, size: size, center: center, time: time)
                    } else if style == .waves {
                        drawWaves(context: context, size: size, center: center, time: time)
                    } else {
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
                }
                .blur(radius: style == .grid || style == .waves ? 0 : 1)
                .onAppear {
                    currentAccelerationState = accelerationState
                    currentRotationSpeed = calculateRotationSpeed()
                    if accelerationState != .stopped || style == .grid || style == .waves {
                        generateParticles()
                        startAnimations()
                    }
                }
                .onChange(of: accelerationState) { newState in
                    currentAccelerationState = newState
                    if newState == .stopped && (style == .orbit || style == .pulse || style == .spiral) {
                        particles.removeAll()
                    } else if particles.isEmpty && (style == .orbit || style == .pulse || style == .spiral) {
                        generateParticles()
                        startAnimations()
                    }
                }
                .onChange(of: accelerationMagnitude) { _ in
                    currentRotationSpeed = calculateRotationSpeed()
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
    
    private func drawGrid(context: GraphicsContext, size: CGSize, center: CGPoint, time: TimeInterval) {
        let speed = isSpeeding ? 2.0 : 0.5 + accelerationMagnitude * 2
        let phase = (time * speed).truncatingRemainder(dividingBy: 1.0)
        let spacing: CGFloat = 40
        
        context.stroke(
            Path { path in
                // Vertical lines (perspective)
                for i in -5...5 {
                    let x = center.x + CGFloat(i) * spacing * 2
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: center.x + (x - center.x) * 0.2, y: size.height))
                }
                
                // Horizontal lines (moving)
                for i in 0..<10 {
                    let yProgress = (Double(i) / 10.0 + phase).truncatingRemainder(dividingBy: 1.0)
                    let y = size.height * CGFloat(1.0 - pow(yProgress, 2)) // Perspective spacing
                    
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            },
            with: .color(particleColor.opacity(0.5)),
            lineWidth: 2
        )
    }
    
    private func drawWaves(context: GraphicsContext, size: CGSize, center: CGPoint, time: TimeInterval) {
        let speed = isSpeeding ? 3.0 : 1.0 + accelerationMagnitude * 2
        
        for i in 0..<5 {
            let wavePhase = time * speed + Double(i) * 0.5
            let yOffset = CGFloat(i) * 20 - 40
            
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: center.y))
                    
                    for x in stride(from: 0, to: size.width, by: 5) {
                        let relativeX = x / size.width
                        let sine = sin(Double(relativeX) * .pi * 4 + wavePhase)
                        let y = center.y + yOffset + CGFloat(sine * 30)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                },
                with: .color(particleColor.opacity(0.6 - Double(i) * 0.1)),
                lineWidth: 3
            )
        }
    }
    
    private func calculatePosition(for particle: Particle, at index: Int, center: CGPoint) -> CGPoint {
        switch style {
        case .off, .linearGradient, .grid, .waves:
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
        let baseSpeed = 0.02
        let accelerationBoost = min(accelerationMagnitude * 3.0, 0.12)
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
            
        case .orbit, .spiral, .linearGradient:
            // Rotation animation
            Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { timer in
                if style != .linearGradient && currentAccelerationState == .stopped {
                    timer.invalidate()
                    return
                }
                rotationAngle += currentRotationSpeed
            }
            
        case .pulse:
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
            
        case .grid, .waves:
            // Handled by TimelineView
            break
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
