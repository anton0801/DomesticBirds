import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Identify Bird Breeds",
            subtitle: "Take a photo of any bird and our AI instantly identifies the breed with detailed information.",
            icon: "camera.viewfinder",
            color: Color(hex: "#3A7D44"),
            accentColor: Color(hex: "#52A865"),
            illustration: "identify"
        ),
        OnboardingPage(
            id: 1,
            title: "Track Your Poultry",
            subtitle: "Monitor each bird's health, age, egg production, and feeding schedule in one place.",
            icon: "chart.line.uptrend.xyaxis",
            color: Color(hex: "#E8A020"),
            accentColor: Color(hex: "#F5C842"),
            illustration: "track"
        ),
        OnboardingPage(
            id: 2,
            title: "Manage Breeding & Eggs",
            subtitle: "Plan breeding pairs, track incubation, and record hatch outcomes for your flock.",
            icon: "heart.circle.fill",
            color: Color(hex: "#7B4F2E"),
            accentColor: Color(hex: "#A0633A"),
            illustration: "breeding"
        )
    ]

    var body: some View {
        ZStack {
            // Background
            pages[currentPage].color
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentPage)

            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 300, height: 300)
                        .offset(x: -50, y: -100)

                    Circle()
                        .fill(pages[currentPage].accentColor.opacity(0.15))
                        .frame(width: 250, height: 250)
                        .offset(x: geo.size.width - 30, y: geo.size.height - 80)
                        .animation(.easeInOut(duration: 0.4), value: currentPage)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button(action: finishOnboarding) {
                        Text("Skip")
                            .font(DBFont.body())
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 16)

                Spacer()

                // Illustration
                OnboardingIllustration(type: pages[currentPage].illustration, color: pages[currentPage].accentColor)
                    .frame(height: 220)
                    .id(currentPage) // Triggers re-render animation

                Spacer().frame(height: 48)

                // Text content
                VStack(spacing: 16) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .id("title_\(currentPage)")
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))

                    Text(pages[currentPage].subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .id("sub_\(currentPage)")
                }

                Spacer()

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count) { idx in
                        Capsule()
                            .fill(Color.white.opacity(idx == currentPage ? 1.0 : 0.3))
                            .frame(width: idx == currentPage ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Next / Get Started
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            finishOnboarding()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(DBFont.headline(17))
                        Image(systemName: currentPage == pages.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(pages[currentPage].color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 28)
                .animation(.easeInOut(duration: 0.2), value: currentPage)

                Spacer().frame(height: 50)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50, currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentPage += 1 }
                    } else if value.translation.width > 50, currentPage > 0 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentPage -= 1 }
                    }
                }
        )
    }

    private func finishOnboarding() {
        withAnimation { hasCompletedOnboarding = true }
    }
}

struct OnboardingPage {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let accentColor: Color
    let illustration: String
}

// MARK: - Onboarding Illustrations
struct OnboardingIllustration: View {
    let type: String
    let color: Color
    @State private var animated = false

    var body: some View {
        ZStack {
            switch type {
            case "identify":
                IdentifyIllustration(color: color, animated: animated)
            case "track":
                TrackIllustration(color: color, animated: animated)
            default:
                BreedingIllustration(color: color, animated: animated)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
                animated = true
            }
        }
    }
}

struct IdentifyIllustration: View {
    let color: Color
    let animated: Bool

    var body: some View {
        ZStack {
            // Camera viewfinder
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 180, height: 180)
                .scaleEffect(animated ? 1.0 : 0.6)
                .opacity(animated ? 1 : 0)

            // Corner marks
            ForEach(0..<4) { i in
                CornerMark(corner: i)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 180, height: 180)
                    .scaleEffect(animated ? 1.0 : 0.5)
                    .opacity(animated ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.1 + 0.3), value: animated)
            }

            // Bird emoji
            Text("🐔")
                .font(.system(size: 72))
                .scaleEffect(animated ? 1.0 : 0.3)
                .opacity(animated ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.5).delay(0.4), value: animated)

            // Scan line
            Rectangle()
                .fill(color.opacity(0.6))
                .frame(width: 160, height: 2)
                .offset(y: animated ? 80 : -80)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.8), value: animated)
                .clipShape(RoundedRectangle(cornerRadius: 1))
        }
    }
}

struct CornerMark: Shape {
    let corner: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size: CGFloat = 20
        let (x, y): (CGFloat, CGFloat) = {
            switch corner {
            case 0: return (rect.minX, rect.minY)
            case 1: return (rect.maxX, rect.minY)
            case 2: return (rect.minX, rect.maxY)
            default: return (rect.maxX, rect.maxY)
            }
        }()
        let dx: CGFloat = corner == 0 || corner == 2 ? 1 : -1
        let dy: CGFloat = corner == 0 || corner == 1 ? 1 : -1
        path.move(to: CGPoint(x: x + dx * size, y: y))
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x, y: y + dy * size))
        return path
    }
}

struct TrackIllustration: View {
    let color: Color
    let animated: Bool

    var body: some View {
        ZStack {
            // Mini cards
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MiniStatCard(emoji: "🥚", value: "24", label: "Eggs Today", color: color, animated: animated, delay: 0.1)
                    MiniStatCard(emoji: "🐔", value: "48", label: "Birds", color: Color(hex: "#3A7D44"), animated: animated, delay: 0.2)
                }
                HStack(spacing: 12) {
                    MiniStatCard(emoji: "💊", value: "2", label: "Health Alerts", color: Color(hex: "#E53E3E"), animated: animated, delay: 0.3)
                    MiniStatCard(emoji: "🌾", value: "12kg", label: "Feed Used", color: Color(hex: "#7B4F2E"), animated: animated, delay: 0.4)
                }
            }
        }
    }
}

struct MiniStatCard: View {
    let emoji: String
    let value: String
    let label: String
    let color: Color
    let animated: Bool
    let delay: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 24))
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 100, height: 80)
        .background(Color.white.opacity(0.15))
        .cornerRadius(14)
        .scaleEffect(animated ? 1.0 : 0.5)
        .opacity(animated ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(delay), value: animated)
    }
}

struct BreedingIllustration: View {
    let color: Color
    let animated: Bool

    var body: some View {
        ZStack {
            // Heart
            Image(systemName: "heart.fill")
                .font(.system(size: 90))
                .foregroundColor(Color.white.opacity(0.15))
                .scaleEffect(animated ? 1.0 : 0.3)

            VStack(spacing: 10) {
                HStack(spacing: 20) {
                    Text("🐓").font(.system(size: 50))
                        .offset(x: animated ? 0 : -40)
                        .opacity(animated ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: animated)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#F56565"))
                        .scaleEffect(animated ? 1.0 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.5), value: animated)
                    Text("🐔").font(.system(size: 50))
                        .offset(x: animated ? 0 : 40)
                        .opacity(animated ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: animated)
                }
                HStack(spacing: 14) {
                    ForEach(0..<3) { i in
                        Text("🥚")
                            .font(.system(size: 32))
                            .scaleEffect(animated ? 1.0 : 0.2)
                            .opacity(animated ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.6 + Double(i) * 0.15), value: animated)
                    }
                }
            }
        }
    }
}
