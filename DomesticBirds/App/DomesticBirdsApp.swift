import SwiftUI

@main
struct DomesticBirdsApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

final class AttributionBridge: NSObject {
    var onTracking: (([AnyHashable: Any]) -> Void)?
    var onNavigation: (([AnyHashable: Any]) -> Void)?
    private var trackingBuf: [AnyHashable: Any] = [:], navigationBuf: [AnyHashable: Any] = [:], timer: Timer?
    
    func receiveTracking(_ data: [AnyHashable: Any]) { trackingBuf = data; scheduleTimer(); if !navigationBuf.isEmpty { merge() } }
    func receiveNavigation(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "db_launch_flag") else { return }
        navigationBuf = data; onNavigation?(data); timer?.invalidate(); if !trackingBuf.isEmpty { merge() }
    }
    private func scheduleTimer() { timer?.invalidate(); timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() } }
    private func merge() { var result = trackingBuf; navigationBuf.forEach { k, v in let key = "deep_\(k)"; if result[key] == nil { result[key] = v } }; onTracking?(result) }
}


struct MainView: View {
    @StateObject private var appState = AppState()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity))
                    .zIndex(1)
            } else if !appState.isAuthenticated {
                AuthNavigationView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity))
                    .zIndex(1)
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: appState.isAuthenticated)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasCompletedOnboarding)
        .environmentObject(appState)
        .preferredColorScheme(appState.colorScheme)
    }
}

struct AuthNavigationView: View {
    var body: some View {
        NavigationView {
            WelcomeView()
        }
        .navigationViewStyle(.stack)
    }
}


final class PushBridge: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(from: payload) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { NotificationCenter.default.post(name: .init("LoadTempURL"), object: nil, userInfo: ["temp_url": url]) }
    }
    private func extract(from p: [AnyHashable: Any]) -> String? {
        if let u = p["url"] as? String { return u }
        if let d = p["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let a = p["aps"] as? [String: Any], let d = a["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let c = p["custom"] as? [String: Any], let u = c["target_url"] as? String { return u }
        return nil
    }
}
