import Foundation
import Combine

@MainActor
final class DomesticBirdsViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let cqrsHandler: DomesticBirdsCQRSHandler
    private var timeoutTask: Task<Void, Never>?
    
    init(cqrsHandler: DomesticBirdsCQRSHandler) {
        self.cqrsHandler = cqrsHandler
    }
    
    // MARK: - Public API
    
    func initialize() {
        Task {
            do {
                // Command: Initialize
                try await cqrsHandler.execute(.initialize)
                scheduleTimeout()
            } catch {
                print("🐔 [DomesticBirds] Initialize error: \(error)")
            }
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            do {
                try await cqrsHandler.execute(.recordTracking(data))
                
                await performValidation()
            } catch {
                print("🐔 [DomesticBirds] Tracking error: \(error)")
                navigateToMain = true
            }
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            do {
                // Command: Record navigation
                try await cqrsHandler.execute(.recordNavigation(data))
            } catch {
                print("🐔 [DomesticBirds] Navigation error: \(error)")
            }
        }
    }
    
    func requestPermission() {
        Task {
            do {
                // Command: Grant permission
                try await cqrsHandler.execute(.grantPermission)
                showPermissionPrompt = false
                navigateToWeb = true
            } catch {
                print("🐔 [DomesticBirds] Permission error: \(error)")
                showPermissionPrompt = false
                navigateToWeb = true
            }
        }
    }
    
    func deferPermission() {
        Task {
            do {
                // Command: Decline permission
                try await cqrsHandler.execute(.declinePermission)
                showPermissionPrompt = false
                navigateToWeb = true
            } catch {
                print("🐔 [DomesticBirds] Defer error: \(error)")
                showPermissionPrompt = false
                navigateToWeb = true
            }
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        Task {
            showOfflineView = !isConnected
        }
    }
    
    func timeout() {
        Task {
            timeoutTask?.cancel()
            navigateToMain = true
        }
    }
    
    // MARK: - Private Logic
    
    private var validated = false
    
    private func performValidation() async {
        if !validated {
            do {
                try await cqrsHandler.execute(.validateAndExecute)
                
                validated = true
                
                let canRequest = cqrsHandler.query(.canRequestPermission) as! Bool
                
                if canRequest {
                    timeoutTask?.cancel()
                    showPermissionPrompt = true
                } else {
                    timeoutTask?.cancel()
                    navigateToWeb = true
                }
            } catch {
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await timeout()
        }
    }
}
