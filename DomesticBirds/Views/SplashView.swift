import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @StateObject private var viewModel: BirdViewModel
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var subtitleOpacity: Double = 0
    @State private var particlesOpacity: Double = 0
    @State private var loadingIndicatorIndex: Int = 0
    @State private var bgRotation: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    
    init() {
        let storage = BatchedStorage()
        let integrity = SupabaseIntegrityCheck()
        let remoteConfig = HTTPRemoteConfig()
        let authManager = SystemAuthManager()
        
        let pipeline = BirdPipeline()
        pipeline.persistence = storage
        pipeline.integrity = integrity
        pipeline.remoteConfig = remoteConfig
        pipeline.authManager = authManager
        
        _viewModel = StateObject(wrappedValue: BirdViewModel(pipeline: pipeline))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#1A3A20"), Color(hex: "#2D5A35"), Color(hex: "#3A7D44")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image(geometry.size.width > geometry.size.height ? "wait_app_bg2" : "wait_app_bg")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 10)
                        .opacity(0.5)
                }
                .ignoresSafeArea()
                
                // Decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 350, height: 350)
                        .offset(x: -80, y: -120)
                        .rotationEffect(.degrees(bgRotation))
                    
                    Circle()
                        .fill(Color(hex: "#E8A020").opacity(0.08))
                        .frame(width: 250, height: 250)
                        .offset(x: geo.size.width - 60, y: geo.size.height - 100)
                    
                    // Wheat/grain dots pattern
                    ForEach(0..<12) { i in
                        let angle = Double(i) * 30.0
                        let radius: CGFloat = 130
                        let x = geo.size.width / 2 + radius * CGFloat(cos(angle * .pi / 180))
                        let y = geo.size.height / 2 + radius * CGFloat(sin(angle * .pi / 180))
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                            .opacity(particlesOpacity)
                    }
                }
                
                NavigationLink(
                    destination: DomesticBirdsWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: MainView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo
                    ZStack {
                        // Outer ring
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 130, height: 130)
                        
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "#E8A020"), Color(hex: "#F5C842")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color(hex: "#E8A020").opacity(0.5), radius: 20, x: 0, y: 8)
                        
                        // Bird icon
                        VStack(spacing: -4) {
                            Image(systemName: "bird.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .rotationEffect(.degrees(-30))
                                .offset(x: 14, y: -4)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Shimmer overlay
                    .overlay(
                        RoundedRectangle(cornerRadius: 65)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.3), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 80)
                            .offset(x: shimmerOffset)
                            .clipped()
                    )
                    .clipShape(Circle())
                    
                    Spacer().frame(height: 32)
                    
                    // App Name
                    Text("Domestic Birds")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                    
                    Spacer().frame(height: 10)
                    
                    // Tagline
                    Text("Loading App Content...")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                        .opacity(subtitleOpacity)
                    
                    Spacer()
                    
                    // Bottom indicator
                    HStack(spacing: 6) {
                        ForEach(0..<2) { i in
                            Capsule()
                                .fill(Color.white.opacity(loadingIndicatorIndex == i ? 0.9 : 0.3))
                                .frame(width: loadingIndicatorIndex == i ? 24 : 8, height: 4)
                        }
                    }
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 50)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                DomesticBirdsNotificationView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                ProblemView()
            }
            .onAppear {
                NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
                    .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
                    .sink { data in
                        viewModel.receiveMetrics(data)
                    }
                    .store(in: &cancellables)
                
                NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
                    .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                    .sink { data in
                        viewModel.receiveRoutes(data)
                    }
                    .store(in: &cancellables)
                runAnimation()
                networkMonitor.pathUpdateHandler = { path in
                    Task { @MainActor in
                        viewModel.networkChanged(path.status == .satisfied)
                    }
                }
                networkMonitor.start(queue: .global(qos: .background))
                viewModel.initialize()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func runAnimation() {
        // Stage 1 — logo
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Stage 2 — particles
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            particlesOpacity = 1
        }
        
        // Stage 3 — title
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            titleOpacity = 1.0
        }
        
        // Stage 4 — subtitle
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            subtitleOpacity = 1.0
        }
        
        // Stage 5 — shimmer
        withAnimation(.easeInOut(duration: 0.8).delay(1.2)) {
            shimmerOffset = 200
        }
        
        // Stage 6 — background rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            bgRotation = 360
        }
        withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
            loadingIndicatorIndex = 1
        }
    }
}

struct ProblemView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "problem_bg2" : "problem_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 8)
                    .opacity(0.8)
                
                Image("problem_alert")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
