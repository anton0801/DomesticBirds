import SwiftUI

struct BirdConstants {
    static let appID = "6762511633"
    static let devKey = "U98po8PwQQoknNXDmfCjhM"
}

@main
struct DomesticBirdsApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
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

final class PushManager: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: "temp_url")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String {
            return direct
        }
        
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String {
            return url
        }
        
        return nil
    }
}
