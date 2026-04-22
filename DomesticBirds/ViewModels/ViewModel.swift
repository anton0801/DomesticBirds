import Foundation
import Combine

@MainActor
final class BirdViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let pipeline: BirdPipeline
    private var cancellables = Set<AnyCancellable>()
    private var timeoutJob: Task<Void, Never>?
    
    init(pipeline: BirdPipeline) {
        self.pipeline = pipeline
    }
    
    func initialize() {
        Task {
            await pipeline.bootstrap()
            scheduleTimeout()
        }
    }
    
    func receiveMetrics(_ data: [String: Any]) {
        Task {
            await pipeline.ingestMetrics(data)
            await run()
        }
    }
    
    func receiveRoutes(_ data: [String: Any]) {
        Task {
            await pipeline.ingestRoutes(data)
        }
    }
    
    func authorize() {
        Task {
            _ = await pipeline.authorize()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func postponeAuth() {
        Task {
            pipeline.postpone()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func networkChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    func timeout() {
        if !pipeline.integritied {
            timeoutJob?.cancel()
            navigateToMain = true
        }
    }
    
    private func run() async {
        let result = await pipeline.execute()
        
        timeoutJob?.cancel()
        
        switch result {
        case .navigateMain:
            if !navigateToWeb {
                navigateToMain = true
            }
        case .showPermission:
            showPermissionPrompt = true
        case .navigateWeb:
            navigateToWeb = true
        }
    }
    
    private func scheduleTimeout() {
        timeoutJob = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await timeout()
        }
    }
}
