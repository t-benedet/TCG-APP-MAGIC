import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            CardListView()
                .environmentObject(dataManager)

            if showLaunchScreen {
                LaunchScreen()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

// MARK: - Launch Screen

struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.05, green: 0.02, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated particles
            ParticleView()

            // Logo and title
            VStack(spacing: 24) {
                // Logo icon
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.3, blue: 0.8),
                                    Color(red: 0.3, green: 0.2, blue: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.5), radius: 20)

                    // Icon
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)

                // Title
                VStack(spacing: 8) {
                    Text("Magic Collection")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Track your cards")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Particle View

struct ParticleView: View {
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color(red: 0.6, green: 0.4, blue: 0.9))
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        for _ in 0..<20 {
            let particle = Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.4),
                speed: Double.random(in: 0.5...2)
            )
            particles.append(particle)
        }
    }

    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].y -= CGFloat(particles[i].speed)
                if particles[i].y < -10 {
                    particles[i].y = size.height + 10
                    particles[i].x = CGFloat.random(in: 0...size.width)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
